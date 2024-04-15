// NOTE: How to set kernel loglevel to debug? echo "7" > /sys/kernel/printk

// TODO: Implement file operations
// TODO: Pass blink frequency as kernel parameter
// TODO: Figure timer stuff out
// TODO: Document important stuff
use alloc::vec::Vec;
use kernel::chrdev;
use kernel::file::{
    self,
    flags::{O_ACCMODE, O_RDONLY, O_RDWR, O_WRONLY},
};
use kernel::io_buffer::{IoBufferReader, IoBufferWriter};
use kernel::sync::{self, smutex::Mutex, Arc};
use kernel::{prelude::*, ForeignOwnable};

// Constants
const MAX_DEVICES: usize = 1;
const MINOR_IDS_BEGIN: u16 = 0;

// Kernel module registration.
module! {
    type: Module,
    name: "text_to_morse",
    author: "Simon Brummer <simon.brummer@posteo.de>",
    description: "Module converting text to morse code",
    license: "Dual MPL/GPL",
    params: {
        DEVICES: usize {
            default: 1,
            permissions: 0o444,
            description: "Number of devices to create.",
        },
    },
}

struct Module {
    _registry: Pin<Box<chrdev::Registration<MAX_DEVICES>>>,
}

impl kernel::Module for Module {
    fn init(name: &'static CStr, module: &'static ThisModule) -> Result<Self> {
        pr_debug!("Called init(...)\n");

        // Determine the number of devices to create
        let devices = DEVICES.read().clone();
        if MAX_DEVICES < devices {
            pr_crit!(
                "Error: Unable to create more devices than {}. \
                 Change parameter DEVICES accordingly.\n",
                MAX_DEVICES
            );
            return Err(EOVERFLOW);
        }

        // Register given number of Character devices
        let mut registry = chrdev::Registration::new_pinned(name, MINOR_IDS_BEGIN, module)?;
        for number in 0..devices {
            pr_info!("Registering device number {}\n", number);
            registry.as_mut().register::<Device>()?;
        }

        Ok(Module {
            _registry: registry,
        })
    }
}

impl Drop for Module {
    fn drop(&mut self) {
        pr_debug!("Called drop(...)\n");
    }
}

/// Character device implementation.
struct DeviceState {
    has_readers: bool,
    has_writers: bool,
}

impl DeviceState {
    fn new() -> Mutex<Self> {
        Mutex::new(Self {
            has_readers: false,
            has_writers: false,
        })
    }
}

struct Device {
    id: usize,
    state: Mutex<DeviceState>,
}

impl Device {
    fn new(id: usize) -> Self {
        Self {
            id,
            state: DeviceState::new(),
        }
    }

    fn try_new(id: usize) -> Result<Arc<Self>> {
        Arc::try_new(Device::new(id))
    }

    fn get_or_allocate_device(id: usize) -> Result<Arc<Device>> {
        // Try to find device in device pool. If this fails, try to create
        // new device and insert it.
        static DEVICES_POOL: Mutex<Vec<Arc<Device>>> = Mutex::new(Vec::new());

        let mut device_pool = DEVICES_POOL.lock();

        let device = device_pool.iter().find(|device| device.id == id);

        match device {
            None => {
                let device = Device::try_new(id)?;
                device_pool.try_push(device.clone())?;
                Ok(device)
            }
            Some(device) => Ok(device.clone()),
        }
    }
}

#[vtable]
impl file::Operations for Device {
    type Data = Arc<Device>;

    fn open(_: &(), file: &file::File) -> Result<Self::Data> {
        // Open: Implements "backend" syscall open. We enforce the following semantics:
        // - Exclusive read access: At most one reader is allowed at all times.
        // - Exclusive write access: At most one writer is allowed at all times.
        pr_debug!("Called open(...)\n");

        // TODO: Determine minor_id from file and use it as device id. No obvious way to do it.
        let minor_id = 0;
        let device = Device::get_or_allocate_device(minor_id)?;

        // Handle requested access mode
        match file.flags() & O_ACCMODE {
            // Handle read only access attempt
            O_RDONLY => {
                let mut state = device.state.lock();
                if state.has_readers {
                    pr_err!(
                        "Failed to get read access for Device {}. Already in use.\n",
                        device.id
                    );
                    return Err(EACCES);
                } else {
                    pr_debug!("Mark Device {} as read accessed.\n", device.id);
                    state.has_readers = true;
                }
            }
            // Handle write only access attempt
            O_WRONLY => {
                let mut state = device.state.lock();
                if state.has_writers {
                    pr_err!(
                        "Failed to get write access for Device {}. Already in use.\n",
                        device.id
                    );
                    return Err(EACCES);
                } else {
                    pr_debug!("Mark Device {} as write accessed.\n", device.id);
                    state.has_writers = true;
                }
            }
            // Handle read/write access attempt
            O_RDWR => {
                let mut state = device.state.lock();
                if state.has_readers || state.has_writers {
                    pr_err!(
                        "Failed to get read/write access for Device {}. Already in use.\n",
                        device.id
                    );
                    return Err(EACCES);
                } else {
                    pr_debug!("Mark Device {} as read/write accessed.\n", device.id);
                    state.has_readers = true;
                    state.has_writers = true;
                }
            }
            _ => {
                pr_err!("Unhandled access flags. Return Error.\n");
                return Err(EACCES);
            }
        };
        Ok(device)
    }

    fn release(device: Self::Data, file: &file::File) {
        // Release: Implements "backend" of syscall close. Return mutual access
        // acquired in open call.
        pr_debug!("Called release(...)\n");

        // Free usage based access mode
        match file.flags() & O_ACCMODE {
            O_RDONLY => {
                pr_debug!("Mark Device {} as not read accessed.\n", device.id);
                device.state.lock().has_readers = false;
            }
            O_WRONLY => {
                pr_debug!("Mark Device {} as not write accessed.\n", device.id);
                device.state.lock().has_writers = false;
            }
            O_RDWR => {
                pr_debug!("Mark Device {} as not read/write accessed.\n", device.id);
                let mut state = device.state.lock();
                state.has_readers = true;
                state.has_writers = true;
            }
            _ => {
                pr_err!("Unhandled access flags. Do nothing.\n");
            }
        };
    }

    fn write(
        _data: <Self::Data as ForeignOwnable>::Borrowed<'_>,
        _file: &file::File,
        _buffer: &mut impl IoBufferReader,
        _offset: u64,
    ) -> Result<usize> {
        pr_debug!("Called write(...)\n");
        Err(EOPNOTSUPP)
    }

    fn read(
        _data: <Self::Data as ForeignOwnable>::Borrowed<'_>,
        _file: &file::File,
        _buffer: &mut impl IoBufferWriter,
        _offset: u64,
    ) -> Result<usize> {
        pr_debug!("Called read(...)\n");
        Err(EOPNOTSUPP)
    }
}
