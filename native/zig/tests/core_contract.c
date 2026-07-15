#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

struct core;
struct request { const uint8_t *bytes; size_t bytes_len; uint64_t cancellation_token; };
extern struct core *openphone_zig_core_create(void);
extern int openphone_zig_core_cancel(struct core *, uint64_t);
extern int openphone_zig_core_generate(struct core *, const struct request *);
extern ptrdiff_t openphone_zig_core_copy_result(struct core *, uint8_t *, size_t);
extern void openphone_zig_core_destroy(struct core *);

int main(void) {
  struct core *core = openphone_zig_core_create(); uint8_t result[3] = {0};
  const uint8_t bytes[] = "ok"; struct request request = {bytes, 2, 9};
  assert(core && openphone_zig_core_generate(core, &request) == 0);
  assert(openphone_zig_core_copy_result(core, result, sizeof(result)) == 2);
  assert(memcmp(result, bytes, 2) == 0);
  assert(openphone_zig_core_cancel(core, 10) == 0);
  request.cancellation_token = 10;
  assert(openphone_zig_core_generate(core, &request) == -5);
  assert(openphone_zig_core_generate(core, 0) == -2);
  openphone_zig_core_destroy(core);
}
