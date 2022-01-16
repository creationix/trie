use std::slice;

const NOT_FOUND: i8 = -1;
const OUT_OF_BOUNDS: i8 = -2;

fn trie_walk(trie: &[u8], key: u64) -> i8 {
    let mut trie_offset: usize = 0;
    let mut bit_offset: u8 = 0;
    const HIGH_BIT: u8 = 0x80;

    loop {
        // Consume 3 bits from the key bitstream
        let index: u8 = 1 << ((key >> bit_offset) & 0b111);
        bit_offset += 3;

        // Read the bitfield from the trie
        let bitfield: u8 = trie[trie_offset];
        trie_offset += 1;

        if (bitfield & index) == 0 {
            return NOT_FOUND;
        }

        trie_offset += (bitfield & (index - 1)).count_ones() as usize;
        if trie_offset >= trie.len() {
            return OUT_OF_BOUNDS;
        }

        // Read the tagged pointer
        let pointer: u8 = trie[trie_offset];

        // If high bit is zero set, we're done!
        if (pointer & HIGH_BIT) == 0 {
            return pointer as i8;
        }

        // Follow the pointer, but ignore the bottom bit.
        trie_offset += (pointer & (HIGH_BIT - 1)) as usize;
        if trie_offset >= trie.len() {
            return OUT_OF_BOUNDS;
        }
    }
}

#[no_mangle]
pub extern "C" fn trie_walk_8(ptr: *const u8, len: usize, key: u64) -> i8 {
    let trie = unsafe {
        assert!(!ptr.is_null());
        slice::from_raw_parts(ptr, len)
    };
    return trie_walk(trie, key);
}
