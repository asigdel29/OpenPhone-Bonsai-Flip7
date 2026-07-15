#include <assert.h>
#include <stddef.h>
#include <stdint.h>

struct request { uint32_t version; const uint8_t *bytes; size_t bytes_len; uint64_t cancellation_token; };
extern int openphone_zig_abi_validate_request(const struct request *);
extern uint32_t openphone_zig_abi_version(void);

int main(void) {
  const uint8_t payload[] = "{}";
  struct request valid = {1, payload, sizeof(payload) - 1, 7};
  struct request null_bytes = {1, 0, 1, 7};
  struct request oversized = {1, payload, 65537, 7};
  assert(openphone_zig_abi_version() == 1);
  assert(openphone_zig_abi_validate_request(&valid) == 0);
  assert(openphone_zig_abi_validate_request(&null_bytes) == -3);
  assert(openphone_zig_abi_validate_request(&oversized) == -2);
  assert(openphone_zig_abi_validate_request(0) == -1);
}
