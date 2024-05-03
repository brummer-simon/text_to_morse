// SPDX-License-Identifier: Dual MPL/GPL
// Author: Simon Brummer <simon.brummer@posteo.de>

use kernel::prelude::*;

/// Simple, generic, array backed Ringbuffer with FIFO semantics.
pub(crate) struct Ringbuffer<T, const N: usize> {
    buffer: [T; N], // Array used to store objects
    rpos: usize,    // Current read position
    wpos: usize,    // Current write position
    used: usize,    // Number of used slots in buffer
}

impl<T: Copy, const N: usize> Ringbuffer<T, N> {
    /// Create a empty Ringbuffer
    ///
    /// # Returns
    /// An empty Ringbuffer
    pub(crate) fn new() -> Self {
        Self {
            buffer: unsafe { core::mem::zeroed() },
            rpos: 0,
            wpos: 0,
            used: 0,
        }
    }

    /// Try to append a value in the Ringbuffer.
    ///
    /// # Arguments
    /// * val: The value to store.
    ///
    /// # Returns
    /// In case the Ringbuffer is full, an Err containing ENOMEM is returned, otherwise
    /// an Ok containing the unit value is returned.
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

    /// Try to get a value from the Ringbuffer.
    ///
    /// # Returns
    /// In case the Ringbuffer is empty, an Err containing ENODATA is returned, otherwise
    /// an Ok the oldest value in the Ringbuffer.
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

    /// Get the number of currently stored objects in the Ringbuffer.
    ///
    /// # Returns
    /// The number of currently stored objects.
    pub(crate) fn len(&self) -> usize {
        self.used
    }

    /// Get the number of object that could be stored until the Ringbuffer is full.
    ///
    /// # Returns
    /// The number of free slots.
    pub(crate) fn free(&self) -> usize {
        self.size() - self.used
    }

    /// Get the total number of objects that can be stored in the Ringbuffer.
    ///
    /// # Returns
    /// The number of total slots.
    ///
    /// # Note
    /// This is equivalent to the generic parameter N given on type definition.
    pub(crate) fn size(&self) -> usize {
        N
    }

    /// Check if the Ringbuffer is empty.
    ///
    /// # Returns
    /// true if the entire Ringbuffer is empty, otherwise false.
    pub(crate) fn is_empty(&self) -> bool {
        self.len() == 0
    }

    /// Check if the Ringbuffer is full.
    ///
    /// # Returns
    /// true if the entire Ringbuffer is full, otherwise false.
    pub(crate) fn is_full(&self) -> bool {
        self.free() == 0
    }
}
