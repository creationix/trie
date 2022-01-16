test-all: test-zig test-c test-lua

test-zig: trie.zig
	zig test trie.zig

# Install `qemu-user-static`, `wine`, and `wine-binfmt` on ubuntu to run foreign binaries
test-c: trie-test.c trie.c
	@echo ""
	zig run --library c trie-test.c -static -target x86_64-linux-musl
	@echo ""
	zig run --library c trie-test.c -static -target aarch64-linux-musl
	@echo ""
	zig run --library c trie-test.c -static -target arm-linux-musleabi
	@echo ""
	zig run --library c trie-test.c -static -target x86_64-windows-gnu
	# @echo ""
	# zig run --library c trie-test.c -static -target aarch64-windows-gnu
	@echo ""
	zig run --library c trie-test.c -target x86_64-macos-gnu
	# zig run --library c trie-test.c -target aarch64-macos-gnu

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

rust: librtrie.so rtrie.wasm

librtrie.so: trie.rs
	rustc trie.rs --crate-type cdylib --crate-name rtrie -C opt-level=s -C strip=symbols -C panic=abort

rtrie.wasm: trie.rs
	rustc trie.rs --crate-type cdylib --crate-name rtrie -C opt-level=s -C strip=symbols --target wasm32-unknown-unknown

clean:
	rm -f lib*.so *.wasm
