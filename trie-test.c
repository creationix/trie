#include "trie.c"
#include <assert.h>
#include <stdio.h>

static void test_basic_functionality() {
  uint8_t trie8[3] = {
      0b00010110,  // bitfield
      39,
      42,
  };

  //   try expectEqual(@intCast(u8, 39), try trieWalk(u8, u8, &trie8, 1));
  //   try expectError(error.NotFound, trieWalk(u8, u8, &trie8, 3));
  //   try expectError(error.OutOfRange, trieWalk(u8, u8, &trie8, 4));
}

int main() {
  printf("test_basic_functionality...\n");
  test_basic_functionality();
}
