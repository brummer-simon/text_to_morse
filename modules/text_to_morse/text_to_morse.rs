use kernel::prelude::*;

module! {
    type: TextToMorse,
    name: "TextToMorse",
    author: "Simon Brummer <simon.brummer@posteo.de>",
    description: "Module converting text to morse code",
    license: "GPL",
}

struct TextToMorse {

}

impl kernel::Module for TextToMorse {
    fn init(_module: &'static ThisModule) -> Result<Self> {
        pr_info!("TextToMorse init\n");
        Ok(TextToMorse {})
    }
}

impl Drop for TextToMorse {
    fn drop(&mut self) {
        pr_info!("TextToMorse exit\n");
    }
}
