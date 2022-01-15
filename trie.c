#include <stddef.h>
#include <stdint.h>

enum errors {
  NOT_FOUND = -1,
  OUT_OF_BOUNDS = -2,
};

// Higest bit in 32-bit integer
#define HIGH_BIT 0x80000000

static int popcnt(int num);

int8_t trieWalk8(uint8_t* trie, uint8_t len, uint64_t key) {
  size_t trieOffset = 0;
  int bitOffset = 0;

  for (;;) {
    // Consume 3 bits from the key bitstream
    uint8_t index = 1 << ((key >> bitOffset) & 0b111);
    bitOffset += 3;

    // Read the bitfield from the trie
    uint8_t bitfield = trie[trieOffset];
    trieOffset += 1;

    if ((bitfield & index) == 0)
      return NOT_FOUND;

    trieOffset += popcnt(bitfield & (index - 1));
    if (trieOffset >= len)
      return OUT_OF_BOUNDS;

    // Read the tagged pointer
    uint8_t pointer = trie[trieOffset];

    // If high bit is zero set, we're done!
    if ((pointer & HIGH_BIT) == 0)
      return pointer;

    // Follow the pointer, but ignore the bottom bit.
    trieOffset += pointer & (HIGH_BIT - 1);
    if (trieOffset >= len)
      return OUT_OF_BOUNDS;
  }
}

int16_t trieWalk16(uint16_t* trie, uint16_t len, uint64_t key) {
  size_t trieOffset = 0;
  int bitOffset = 0;

  for (;;) {
    // Consume 4 bits from the key bitstream
    uint16_t index = 1 << ((key >> bitOffset) & 0b1111);
    bitOffset += 4;

    // Read the bitfield from the trie
    uint16_t bitfield = trie[trieOffset];
    trieOffset += 1;

    if ((bitfield & index) == 0)
      return NOT_FOUND;

    trieOffset += popcnt(bitfield & (index - 1));
    if (trieOffset >= len)
      return OUT_OF_BOUNDS;

    // Read the tagged pointer
    uint16_t pointer = trie[trieOffset];

    // If high bit is zero set, we're done!
    if ((pointer & HIGH_BIT) == 0)
      return pointer;

    // Follow the pointer, but ignore the bottom bit.
    trieOffset += pointer & (HIGH_BIT - 1);
    if (trieOffset >= len)
      return OUT_OF_BOUNDS;
  }
}

int32_t trieWalk32(uint32_t* trie, uint32_t len, uint64_t key) {
  size_t trieOffset = 0;
  int bitOffset = 0;

  for (;;) {
    // Consume 5 bits from the key bitstream
    uint32_t index = 1 << ((key >> bitOffset) & 0b11111);
    bitOffset += 5;

    // Read the bitfield from the trie
    uint32_t bitfield = trie[trieOffset];
    trieOffset += 1;

    if ((bitfield & index) == 0)
      return NOT_FOUND;

    trieOffset += popcnt(bitfield & (index - 1));
    if (trieOffset >= len)
      return OUT_OF_BOUNDS;

    // Read the tagged pointer
    uint32_t pointer = trie[trieOffset];

    // If high bit is zero set, we're done!
    if ((pointer & HIGH_BIT) == 0)
      return pointer;

    // Follow the pointer, but ignore the bottom bit.
    trieOffset += pointer & (HIGH_BIT - 1);
    if (trieOffset >= len)
      return OUT_OF_BOUNDS;
  }
}

int64_t trieWalk64(uint64_t* trie, uint64_t len, uint64_t key) {
  size_t trieOffset = 0;
  int bitOffset = 0;

  for (;;) {
    // Consume 6 its from the key bitstream
    uint64_t index = 1 << ((key >> bitOffset) & 0b111111);
    bitOffset += 6;

    // Read the bitfield from the trie
    uint64_t bitfield = trie[trieOffset];
    trieOffset += 1;

    if ((bitfield & index) == 0)
      return NOT_FOUND;

    trieOffset += popcnt(bitfield & (index - 1));
    if (trieOffset >= len)
      return OUT_OF_BOUNDS;

    // Read the tagged pointer
    uint64_t pointer = trie[trieOffset];

    // If high bit is zero set, we're done!
    if ((pointer & HIGH_BIT) == 0)
      return pointer;

    // Follow the pointer, but ignore the bottom bit.
    trieOffset += pointer & (HIGH_BIT - 1);
    if (trieOffset >= len)
      return OUT_OF_BOUNDS;
  }
}

// Calculate the number of 1 bits in an integer.
// clang can detect this and optimize to `popcnt`
static int popcnt(int num) {
  int count = 0;
  while (num) {
    count++;
    num &= (num - 1);
  }
  return count;
}
