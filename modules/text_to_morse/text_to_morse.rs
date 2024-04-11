/// TODO: Implement me
use kernel::prelude::*;

module! {
    type: TextToMorse,
    name: "text_to_morse",
    author: "Simon Brummer <simon.brummer@posteo.de>",
    description: "Module converting text to morse code",
    license: "Dual MPL/GPL",
}

struct TextToMorse {}

impl kernel::Module for TextToMorse {
    fn init(_name: &'static CStr, _module: &'static ThisModule) -> Result<Self> {
        pr_info!("Loading module: text_to_morse\n");
        Ok(TextToMorse {})
    }
}

impl Drop for TextToMorse {
    fn drop(&mut self) {
        pr_info!("Unloading module: text_to_morse\n");
    }
}
