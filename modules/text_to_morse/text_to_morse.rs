// Note: Set kernel loglevel to debug: echo "7" > /sys/kernel/printk

// TODO: Todo port to miscdev

// TODO: Implement file operations
// TODO: Pass blink frequency as kernel parameter
// TODO: Figure timer stuff out
use kernel::prelude::*;
use kernel::chrdev;
use kernel::file;
use kernel::io_buffer::{IoBufferReader, IoBufferWriter};
use kernel::sync::{Arc, ArcBorrow, Mutex};

// Constants
const MAX_DEVICES: usize = 8;

// Kernel module registration.
module! {
    type: Module,
    name: "text_to_morse",
    author: "Simon Brummer <simon.brummer@posteo.de>",
    description: "Module converting text to morse code",
    license: "Dual MPL/GPL",
    params: {
        DEVICES: usize {
            default: 4,
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
        let mut registry = chrdev::Registration::new_pinned(name, 0, module)?;
        for number in 0..devices {
            pr_info!("Registering device number {}\n", number);

            let device = Device::new();
            // NOTE: How to pass open data into device registration
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
struct Device {
    // Access management flags
    has_readers: bool,
    has_writers: bool,
}

impl Device {
    fn new() -> Arc<Mutex<Device>> {
        let device = Device{
            has_readers: false,
            has_writers: false,
        };
        Arc::new(Mutex::new(device))
    }
}

#[vtable]
impl file::Operations for Device {
    type Data = Arc<Mutex<Device>>;

    fn open(open_data: &(), _file: &file::File) -> Result<Arc<Mutex<Device>>> {
        // Open: Implement Device opening behavior. In this case it means:
        // - Exclusive read access: At most one reader is allow at all times.
        // - Exclusive write access: At most one writer is allow at all times.
        pr_debug!("Called open(...)\n");
        // TODO: Check Opening mode.

        // TODO: Check if already opened by other users. Return Error is this is the case
        //Ok(open_data.clone())
    }

    fn release(_data: Arc<Mutex<Device>>, _file: &file::File) {
        pr_debug!("Called release(...)\n");
        // TODO: Handle cleaup
    }

    fn write(
        _state: ArcBorrow<'_, Mutex<Device>>,
        _file: &file::File,
        _data: &mut impl IoBufferReader,
        _offset: u64,
    ) -> Result<usize> {
        pr_debug!("Called write(...)\n");
        Err(EOPNOTSUPP)
    }

    fn read(
        _state: ArcBorrow<'_, Mutex<Device>>,
        _file: &file::File,
        _data: &mut impl IoBufferWriter,
        _offset: u64,
    ) -> Result<usize> {
        pr_debug!("Called read(...)\n");
        Err(EOPNOTSUPP)
    }
}
