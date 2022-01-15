const std = @import("std");
// const HashAlgo = std.hash.Fnv1a_64;
const HashAlgo = std.hash.CityHash64;

fn trieWalk(comptime T: type, comptime H: type, trie: []const T, key: H) !T {
    const numBits: comptime_int = log2BitsSizeOf(T);
    const highBit: comptime_int = (1 << (@bitSizeOf(T) - 1));
    const ptrMask: comptime_int = highBit - 1;

    // std.debug.print("key {b:0>64}\n", .{key});

    var trieOffset: usize = 0;
    var bitOffset: U(log2BitsSizeOf(H)) = 0;

    while (true) {
        // Consume numBits from the key bitstream
        var index: T = @intCast(T, 1) << @truncate(U(numBits), key >> bitOffset);
        // std.debug.print("bitOffset {} index {}\n", .{ bitOffset, index });
        bitOffset +%= numBits;

        // Read the bitfield from the trie
        var bitfield: T = trie[trieOffset];
        trieOffset += 1;

        // std.debug.print("bitOffset={} bitfield={b:0>64} index={b:0>64}\n", .{ bitOffset, bitfield, index });
        // If the nib isn't in the bitfield, it's missing.
        if ((bitfield & index) == 0) return error.NotFound;

        // std.debug.print("@popCount(T, bitfield & (index - 1)) {}\n", .{@popCount(T, bitfield & (index - 1))});
        // Otherwise use popcnt to jump the pointer.
        trieOffset += @popCount(T, bitfield & (index - 1));
        if (trieOffset >= trie.len) return error.OutOfRange;

        // Read the tagged pointer
        var pointer: T = trie[trieOffset];

        // If high bit is zero set, we're done!
        if ((pointer & highBit) == 0) return pointer & ptrMask;

        // Follow the pointer, but ignore the bottom bit.
        trieOffset += @intCast(usize, pointer & ptrMask);
        if (trieOffset >= trie.len) return error.OutOfRange;
    }
}

const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;

fn getIndex(comptime T: type, key: []const u8, shift: comptime_int) U(1 << @bitSizeOf(T)) {
    return @intCast(U(1 << @bitSizeOf(T)), 1) << @truncate(u3, HashAlgo.hash(key) >> shift);
}

test "basic functionality" {
    var trie8 = [_]u8{
        0b00010110, // Bitfield
        39,
        42,
    };
    try expectEqual(@intCast(u8, 42), try trieWalk(u8, u8, &trie8, 2));
    try expectEqual(@intCast(u8, 39), try trieWalk(u8, u8, &trie8, 1));
    try expectError(error.NotFound, trieWalk(u8, u8, &trie8, 3));
    try expectError(error.OutOfRange, trieWalk(u8, u8, &trie8, 4));
}

test "multiple levels" {
    const trie8 = [_]u8{
        0b11111000, // key 0b100 -> 4
        0xde,
        0x80 | 4,
        0xad,
        0xbe,
        0xef,
        0b00000110, // key 0b010 -> 2
        21, // Value to skip
        0x80 | 1, // another pointer
        0b00101001, // key 0b011 -> 3
        10,
        20, // Shoud hit this one
        30,
    };
    try expectEqual(@intCast(u8, 20), try trieWalk(u8, u16, &trie8, 4 | 2 << 3 | 3 << 6));
}

test "16 bit sizes" {
    const trie16 = [_]u16{
        0b0010101000100000,
        0x7fff,
        0xded,
        0x8000 | 2,
        0xbef,
        0b1000000000010000,
        0x111,
        0x222,
    };
    try expectEqual(@intCast(u16, 0xded), try trieWalk(u16, u8, &trie16, 9));
    try expectEqual(@intCast(u16, 0xbef), try trieWalk(u16, u8, &trie16, 13));
    try expectEqual(@intCast(u16, 0x111), try trieWalk(u16, u8, &trie16, 11 | 4 << 4));
    try expectEqual(@intCast(u16, 0x222), try trieWalk(u16, u8, &trie16, 11 | 15 << 4));
}

test "32 bit sizes" {
    const trie32 = [_]u32{
        0b00010000001000000000001000000001, // bitfield
        0x80000000 | 4,
        0xdead,
        0xbeef,
        0x1337,
        0b00000000000000000000000000001000, // bitfield
        0x1234567,
    };
    try expectEqual(@intCast(u32, 0xdead), try trieWalk(u32, u16, &trie32, 9));
    try expectEqual(@intCast(u32, 0xbeef), try trieWalk(u32, u16, &trie32, 21));
    try expectEqual(@intCast(u32, 0x1337), try trieWalk(u32, u16, &trie32, 28));
    try expectEqual(@intCast(u32, 0x1234567), try trieWalk(u32, u16, &trie32, 0 | 3 << 5));
}

test "64 bit sizes" {
    std.debug.print("\n", .{});
    const trie64 = [_]u64{
        0b0000010000000000000000100000000000000000000001000000000000000010, // bitfield
        0x8000000000000000 | 4,
        0x1337dead,
        0x1337beef,
        0x13371337,
        0b0100000000000000000000000000000000000000000000000000000000000000, // bitfield
        0x123456789abcdef,
    };
    try expectEqual(@intCast(u64, 0x1337dead), try trieWalk(u64, u16, &trie64, 18));
    try expectEqual(@intCast(u64, 0x1337beef), try trieWalk(u64, u16, &trie64, 41));
    try expectEqual(@intCast(u64, 0x13371337), try trieWalk(u64, u16, &trie64, 58));
    try expectEqual(@intCast(u64, 0x123456789abcdef), try trieWalk(u64, u16, &trie64, 1 | 62 << 6));
}

// Calculate number of bits needed to shift a given integer size
fn log2BitsSizeOf(comptime T: type) comptime_int {
    var s = @bitSizeOf(T);
    std.debug.assert(@popCount(u16, s) == 1); // Must be power of 2
    var bits = 0;
    while (s > 1) {
        s >>= 1;
        bits += 1;
    }
    return bits;
}

// Create an unsigned integer type from a number of bits
const TypeInfo = @import("std").builtin.TypeInfo;
fn U(comptime numBits: comptime_int) type {
    return @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = numBits } });
}

export fn trieWalk8(trie: [*]u8, len: usize, key: u64) i8 {
    if (trieWalk(u8, u64, trie[0..len], key)) |num| {
        return @intCast(i8, num);
    } else |err| return switch (err) {
        error.NotFound => -1,
        error.OutOfRange => -2,
    };
}

export fn trieWalk16(trie: [*]u16, len: usize, key: u64) i16 {
    if (trieWalk(u16, u64, trie[0..len], key)) |num| {
        return @intCast(i16, num);
    } else |err| return switch (err) {
        error.NotFound => -1,
        error.OutOfRange => -2,
    };
}

export fn trieWalk32(trie: [*]u32, len: usize, key: u64) i32 {
    if (trieWalk(u32, u64, trie[0..len], key)) |num| {
        return @intCast(i32, num);
    } else |err| return switch (err) {
        error.NotFound => -1,
        error.OutOfRange => -2,
    };
}

export fn trieWalk64(trie: [*]u64, len: usize, key: u64) i64 {
    if (trieWalk(u64, u64, trie[0..len], key)) |num| {
        return @intCast(i64, num);
    } else |err| return switch (err) {
        error.NotFound => -1,
        error.OutOfRange => -2,
    };
}
