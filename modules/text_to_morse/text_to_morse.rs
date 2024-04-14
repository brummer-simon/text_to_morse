// TODO: Set kernel loglevel
// TODO: Implement file operations
// TODO: Pass blink frequency as kernel parameter
// TODO: Figure timer stuff out
use kernel::chrdev;
use kernel::file;
use kernel::prelude::*;

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
    // TODO: Add data buffer and all that stuff
}

#[vtable]
impl file::Operations for Device {
    fn open(_shared: &(), _file: &file::File) -> Result {
        pr_debug!("Called open(...)\n");
        // TODO: Check if already opened by other users!
        Ok(())
    }

    // Implement: release, read, write, maybe an async read????
}
