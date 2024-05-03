// SPDX-License-Identifier: Dual MPL/GPL

//! Kernel Module to convert UTF-8 text to morse code.
//! Author: Simon Brummer <simon.brummer@posteo.de>

mod ringbuffer;
use ringbuffer::Ringbuffer;

mod morse;
use morse::morse_code_from;

use alloc::{string::String, vec::Vec};
use kernel::{
    chrdev,
    file::{
        self,
        flags::{O_ACCMODE, O_RDONLY, O_RDWR, O_WRONLY},
    },
    io_buffer::{IoBufferReader, IoBufferWriter},
    prelude::*,
    sync::{smutex::Mutex, Arc, CondVar},
    ForeignOwnable,
};

// Constants and static data
const MAX_DEVICES: usize = 16;
const BUFFER_SIZE: usize = 256;

kernel::init_static_sync! {
    static READ_CONDITION: CondVar;
    static WRITE_CONDITION: CondVar;
}

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

/// Core kernel module containing all module data.
struct Module {
    // Character device registration object.
    _registry: Pin<Box<chrdev::Registration<MAX_DEVICES>>>,
}

impl kernel::Module for Module {
    fn init(name: &'static CStr, module: &'static ThisModule) -> Result<Self> {
        pr_info!("Loading module text_to_morse.\n");

        // Create requested number of devices. If too much devices
        // shall be created fail on loading with EOVERFLOW.
        let devices = DEVICES.read().clone();
        if MAX_DEVICES < devices {
            pr_crit!(
                "Error: Unable to create more devices than {}. \
                 Change parameter DEVICES accordingly.\n",
                MAX_DEVICES
            );
            return Err(EOVERFLOW);
        }

        let mut registry = chrdev::Registration::new_pinned(name, 0, module)?;
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
        pr_info!("Unloading module text_to_morse.\n");
    }
}

/// Mutable inner state of a Device
struct DeviceInner {
    has_readers: bool,                  // Flag to indicate if a device is read accessed
    has_writers: bool,                  // Flag to indicate if a device is write accessed
    queue: Ringbuffer<u8, BUFFER_SIZE>, // Ringbuffer containing transformed morse code.
}

impl DeviceInner {
    /// Create a new DeviceInner object
    fn new() -> Self {
        Self {
            has_readers: false,
            has_writers: false,
            queue: Ringbuffer::new(),
        }
    }
}

/// Character device implementing text to morse conversion.
struct Device {
    id: u16,                   // Constant Id of the device.
    inner: Mutex<DeviceInner>, // Mutable inner device state, protected by a Mutex
}

impl Device {
    /// Try to create a new character device.
    ///
    /// # Arguments:
    /// * id: The id of the new device to create.
    ///
    /// # Returns:
    /// On success, an Arc containing a new Device,
    /// on failure an Err containing return code ENOMEM.
    fn try_new(id: u16) -> Result<Arc<Self>> {
        let inner = Mutex::new(DeviceInner::new());
        let device = Device { id, inner };
        Arc::try_new(device)
    }

    /// Lookup or try to allocate a specific device.
    ///
    /// Arguments:
    /// * id: The device id to get or to create new device with.
    ///
    /// Returns:
    /// On success, an Arc to the found / newly allocated device,
    /// on failure an Err containing return code ENOMEM.
    fn get_or_try_allocate_device(id: u16) -> Result<Arc<Device>> {
        static DEVICES_POOL: Mutex<Vec<Arc<Device>>> = Mutex::new(Vec::new());

        let mut device_pool = DEVICES_POOL.lock();
        let device = device_pool.iter().find(|device| device.id == id);

        match device {
            None => {
                pr_info!(
                    "Device pool contains no device with id {}. Try to allocate new one.\n",
                    id
                );

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
    type OpenData = ();
    type Data = Arc<Device>;

    /// Syscall open implementation
    ///
    /// # Arguments:
    /// * _: Reference to OpenData. Currently only unit type is supported.
    /// * file: Reference kernel file data structure.
    ///
    /// # Returns:
    /// On success: An Ok containing an Arc to the Device, on failure
    /// an Err containing one of the following error codes:
    /// * ENOMEM: A new device must be allocated and this fails.
    /// * EACCESS: Opening the device violates exclusive access rules.
    ///
    /// # Notes:
    /// To function properly, this device relies on exclusive access for reading and/or writing.
    fn open(_: &Self::OpenData, file: &file::File) -> Result<Self::Data> {
        // Try to access device associated with file
        let dev_id = file.minor_id();
        let device = match Device::get_or_try_allocate_device(dev_id) {
            Ok(device) => {
                pr_info!("Open device {}\n", device.id);
                device
            }
            Err(errno) => {
                pr_err!("Failed to open device {}. Error was: {:?}\n", dev_id, errno);
                return Err(errno);
            }
        };

        // Handle requested access mode
        match file.flags() & O_ACCMODE {
            // Read only access attempt
            O_RDONLY => {
                let mut inner = device.inner.lock();
                if inner.has_readers {
                    pr_err!(
                        "Failed to get read access for Device {}. Already in use.\n",
                        device.id
                    );
                    return Err(EACCES);
                } else {
                    pr_info!("Mark Device {} as read accessed.\n", device.id);
                    inner.has_readers = true;
                }
            }
            // Write only access attempt
            O_WRONLY => {
                let mut inner = device.inner.lock();
                if inner.has_writers {
                    pr_err!(
                        "Failed to get write access for Device {}. Already in use.\n",
                        device.id
                    );
                    return Err(EACCES);
                } else {
                    pr_info!("Mark Device {} as write accessed.\n", device.id);
                    inner.has_writers = true;
                }
            }
            // Read/write access attempt
            O_RDWR => {
                let mut inner = device.inner.lock();
                if inner.has_readers || inner.has_writers {
                    pr_err!(
                        "Failed to get read/write access for Device {}. Already in use.\n",
                        device.id
                    );
                    return Err(EACCES);
                } else {
                    pr_info!("Mark Device {} as read/write accessed.\n", device.id);
                    inner.has_readers = true;
                    inner.has_writers = true;
                }
            }
            _ => {
                pr_err!("Unexpected access flags. Return Error.\n");
                return Err(EACCES);
            }
        };

        pr_info!("Opened device {} successfully\n", device.id);
        Ok(device)
    }

    /// Syscall release implementation
    ///
    /// # Arguments:
    /// * device: Reference to Device to release
    /// * file: Reference kernel file data structure.
    ///
    /// # Notes:
    /// This function resets the exclusive access flags set in open.
    fn release(device: Self::Data, file: &file::File) {
        pr_info!("Release device {}\n", device.id);

        match file.flags() & O_ACCMODE {
            // Return read only access
            O_RDONLY => {
                pr_info!("Unmark Device {} as read accessed.\n", device.id);
                device.inner.lock().has_readers = false;
            }
            // Return write only access
            O_WRONLY => {
                pr_info!("Unmark Device {} as write accessed.\n", device.id);
                device.inner.lock().has_writers = false;
            }
            // Return read/write access
            O_RDWR => {
                pr_info!("Unmark Device {} as read/write accessed.\n", device.id);
                let mut inner = device.inner.lock();
                inner.has_readers = true;
                inner.has_writers = true;
            }
            _ => {
                pr_err!("Unexpected access flags. This should never happen. Do nothing.\n");
            }
        };

        pr_info!("Released device {} successfully\n", device.id);
    }

    /// Syscall write implementation
    ///
    /// # Arguments:
    /// * device: Reference to Device to write data into.
    /// * _file: Reference kernel file data structure.
    /// * buffer: Reference to buffered reader containing the data to write.
    /// * offset: Buffer offset parameter.
    ///
    /// # Returns:
    /// On success: An Ok containing the number of successfully written bytes, on failure
    /// an Err containing one of the following error codes:
    /// * EINVAL: Given buffer contains not a single, valid UTF-8 codepoint.
    /// * EINVAL: Given buffer not enough bytes to contain a codepoint.
    ///
    /// # Notes:
    /// * write is meant from a user space perspective. If a process from user space wants to write
    ///   into a file, the file must read from content from user space.
    /// * From a user space side, buffered data may be passed chunk wise to the read function.
    ///   If UTF-8 verification fails this does not mean that entire byte sequence is garbage,
    ///   if might be a case of a miss-aligned buffer and the next attempt contains all expected
    ///   bytes -> If any errors occur and there have been successfully written bytes, return the
    ///   number of written bytes instead of an error.
    fn write(
        device: <Self::Data as ForeignOwnable>::Borrowed<'_>,
        _file: &file::File,
        buffer: &mut impl IoBufferReader,
        offset: u64,
    ) -> Result<usize> {
        pr_info!("Try to write {} into device {}\n", buffer.len(), device.id);
        pr_info!("Write: Offset is {}\n", offset);

        // Wait until there is space to store
        let mut inner = device.inner.lock();
        while inner.queue.is_full() {
            pr_info!(
                "Device {} buffer is full. Wait until space is available.\n",
                device.id
            );

            if WRITE_CONDITION.wait(&mut inner) {
                pr_info!("Signal received, nothing was written. Return.\n");
                return Ok(0);
            }
        }
        pr_info!(
            "Device {} buffer has space. Write as much as possible.\n",
            device.id
        );

        // Parse buffer char by char. Since a char is a UTF-8 codepoint with variable length
        // encoding, try to extract a char from buffer, verify its encoding and convert
        // it afterwards to the associated morse code representation until one
        // of the following events happen:
        // - The given buffer is drained
        // - The calling process receives a signal.
        // - Or something else has gone wrong.
        let mut total_bytes_read = 0usize;
        while !inner.queue.is_full() {
            let result = try_read_char(buffer).and_then(|char| {
                let read_bytes = char.len_utf8();
                let morse_code = morse_code_from(char);
                pr_info!("Try to store given char '{}' as '{}'\n", char, morse_code);

                // Wait until there is enough space available to store morse_code
                let morse_code = morse_code.as_bytes();
                while inner.queue.free() <= morse_code.len() {
                    if WRITE_CONDITION.wait(&mut inner) {
                        pr_info!("Device {} received signal.\n", device.id);
                        return Ok(());
                    }
                }

                // Store morse_code in buffer.
                morse_code
                    .iter()
                    .try_for_each(|byte| inner.queue.try_push(*byte))
                    .unwrap(); // Due to the previous check, it should never fail.

                total_bytes_read += read_bytes;
                Ok(())
            });

            if let Err(errno) = result {
                if total_bytes_read > 0 {
                    break;
                }
                if let Some(error_name) = errno.name() {
                    pr_err!("Failed to read bytes. Error was {}\n", error_name);
                } else {
                    pr_err!("Failed to read bytes due to unknown error.\n");
                }
                return Err(errno);
            }
        }

        pr_info!(
            "Written {} bytes into device {}. Notify all readers.\n",
            total_bytes_read,
            device.id
        );

        READ_CONDITION.notify_all();
        Ok(total_bytes_read)
    }

    /// Syscall read implementation
    ///
    /// # Arguments:
    /// * device: Reference to Device to write data into.
    /// * _file: Reference kernel file data structure.
    /// * buffer: Reference to buffered write containing read data after the call.
    /// * offset: Buffer offset parameter.
    ///
    /// # Returns:
    /// An Ok containing the number of successfully read bytes.
    ///
    /// # Notes:
    /// * read is meant from a user space perspective. If a process from user space wants to read
    ///   from a file, the file must write its contents to user space.
    fn read(
        device: <Self::Data as ForeignOwnable>::Borrowed<'_>,
        _file: &file::File,
        buffer: &mut impl IoBufferWriter,
        offset: u64,
    ) -> Result<usize> {
        pr_info!("Try to read {} from device {}\n", buffer.len(), device.id);
        pr_info!("Read: Offset is {}\n", offset);

        // Wait sleep until read condition is fulfilled. Or a signal was received.
        let mut inner = device.inner.lock();

        while inner.queue.is_empty() {
            pr_info!(
                "Device {} is empty. Wait sleep until data is available.\n",
                device.id
            );

            if READ_CONDITION.wait(&mut inner) {
                pr_info!("Signal received, nothing to read. Return\n");
                return Ok(0);
            }
        }
        pr_info!("Device {} has data. Read as much as possible.\n", device.id);

        // Transfer bytes from queue to buffer until either the buffer or the queue is empty.
        let mut total_bytes_written = 0usize;
        while !buffer.is_empty() {
            match inner.queue.try_pop().and_then(|byte| buffer.write(&byte)) {
                Ok(_) => total_bytes_written += 1,
                Err(_) => break,
            }
        }

        pr_info!(
            "Read {} from device {}. Notify writers.\n",
            total_bytes_written,
            device.id
        );
        WRITE_CONDITION.notify_all();
        Ok(total_bytes_written)
    }
}

/// Try to read a UTF-8 char from given buffer
///
/// # Arguments:
/// * buffer: The buffer to read from.
///
/// # Returns:
/// On success: An Ok containing char read from buffer argument, on failure
/// an Err containing one of the following error codes:
/// * EINVAL: The given buffer contains no valid UTF-8 character start byte.
/// * EINVAL: The given buffer is to short to contain a UTF-8 character.
/// * ENOMEM: Temporary data structures ran out of memory. This should not happen...
///
fn try_read_char(buffer: &mut impl IoBufferReader) -> Result<char> {
    // Bitfiddling constants to determine byte length of expected char.
    const MASK_1BYTE: u8 = 0b10000000;
    const BITS_1BYTE: u8 = 0b00000000;
    const MASK_2BYTE: u8 = 0b11100000;
    const BITS_2BYTE: u8 = 0b11000000;
    const MASK_3BYTE: u8 = 0b11110000;
    const BITS_3BYTE: u8 = 0b11100000;
    const MASK_4BYTE: u8 = 0b11111000;
    const BITS_4BYTE: u8 = 0b11110000;

    // Read first byte to determine the number of bytes of this character.
    let byte: u8 = buffer.read().map_err(|_| EINVAL)?;
    let remaining_bytes = if (byte & MASK_1BYTE) == BITS_1BYTE {
        Ok(0)
    } else if (byte & MASK_2BYTE) == BITS_2BYTE {
        Ok(1)
    } else if (byte & MASK_3BYTE) == BITS_3BYTE {
        Ok(2)
    } else if (byte & MASK_4BYTE) == BITS_4BYTE {
        Ok(3)
    } else {
        Err(EINVAL)
    }?;

    // Read additional bytes, convert them to a 1 char in a String (verifies UTF8 encoding)
    // and return read character.
    let mut bytes = Vec::new();
    bytes.try_push(byte).map_err(|_| ENOMEM)?;

    for _ in 0..remaining_bytes {
        let byte: u8 = buffer.read().map_err(|_| EINVAL)?;
        bytes.try_push(byte).map_err(|_| ENOMEM)?;
    }

    let string = String::from_utf8(bytes).map_err(|_| EINVAL)?;
    string.chars().nth(0).ok_or_else(|| EINVAL)
}
