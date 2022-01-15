libtrie.so: trie.zig
  zig build-lib -dynamic -O ReleaseSmall trie.zig --strip
 
test: test-trie.lua libtrie.so 
  luvit test-trie.lua
