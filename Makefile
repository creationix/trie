test-all: test-zig test-lua

test-zig: trie.zig
	zig test trie.zig

test-lua: test-trie.lua libztrie.so libctrie.so
	luvit test-trie.lua

libztrie.so: trie.zig
	zig build-lib -dynamic -O ReleaseSmall trie.zig --strip --name ztrie

ztrie.wasm: trie.zig
	zig build-lib -target wasm32-freestanding -dynamic -O ReleaseSmall trie.zig --strip --name ztrie

libctrie.so: trie.c
	zig build-lib -dynamic -O ReleaseSmall $< --strip --name ctrie

ctrie.wasm: trie.c
	zig build-lib -target wasm32-freestanding -dynamic -O ReleaseSmall $< --strip --name ctrie

clean:
	rm -f lib*.so *.wasm
