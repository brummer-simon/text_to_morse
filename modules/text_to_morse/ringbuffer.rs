use kernel::prelude::*;

// TODO: Document me
pub(crate) struct Ringbuffer<T, const N: usize> {
    buffer: [T; N], // Array used to store objects
    rpos: usize,    // Current read position
    wpos: usize,    // Current write position
    used: usize,    // Number of used slots in buffer
}

impl<T: Copy, const N: usize> Ringbuffer<T, N> {
    // TODO: Document me
    pub(crate) fn new() -> Self {
        Self {
            buffer: unsafe { core::mem::zeroed() },
            rpos: 0,
            wpos: 0,
            used: 0,
        }
    }

    // TODO: Document me
    pub(crate) fn try_push(&mut self, val: T) -> Result<()> {
        if self.used >= N {
            return Err(ENOMEM);
        }

        self.buffer[self.wpos] = val;
        self.used += 1;
        self.wpos += 1;

        if self.wpos >= N {
            self.wpos = 0;
        }
        Ok(())
    }

    // TODO: Document me
    pub(crate) fn try_pop(&mut self) -> Result<T> {
        if self.used <= 0 {
            return Err(ENODATA);
        }

        let val = self.buffer[self.rpos];

        self.used -= 1;
        self.rpos += 1;

        if self.rpos >= N {
            self.rpos = 0
        }
        Ok(val)
    }

    // TODO: Document me
    pub(crate) fn len(&self) -> usize {
        self.used
    }

    // TODO: Document me
    pub(crate) fn free(&self) -> usize {
        self.size() - self.used
    }

    // TODO: Document me
    pub(crate) fn size(&self) -> usize {
        N
    }

    // TODO: Document me
    pub(crate) fn is_empty(&self) -> bool {
        self.len() == 0
    }

    // TODO: Document me
    pub(crate) fn is_full(&self) -> bool {
        self.free() == 0
    }

}
