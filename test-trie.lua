-- Test calling from Lua via FFI
-- Build with:
--     zig build-lib -dynamic -O ReleaseSmall trie.zig --strip

local ffi = require 'ffi'

local trie = ffi.load 'libtrie.so'
ffi.cdef[[ int32_t trieWalk32(uint32_t* trie, uint32_t len, uint64_t key); ]]

p(trie)

local trie32 = ffi.new("uint32_t[7]", {
    0b00010000001000000000001000000001,
    bit.bor(0x80000000, 4),
    0xdead,
    0xbeef,
    0x1337,
    0b00000000000000000000000000001000,
    0x1234567,
})

p(trie32)
p(trie.trieWalk32)

assert(trie.trieWalk32(trie32, 7, 9) == 0xdead)
assert(trie.trieWalk32(trie32, 7, 21) == 0xbeef)
assert(trie.trieWalk32(trie32, 7, 28) == 0x1337)
assert(trie.trieWalk32(trie32, 7, bit.lshift(3,5)) == 0x1234567)
assert(trie.trieWalk32(trie32, 7, 5) == -1)
