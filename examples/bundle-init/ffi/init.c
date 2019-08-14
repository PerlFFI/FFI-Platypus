#include <ffi_platypus_bundle.h>

char buffer[512];
const char *version;
void (*say)(const char *);

void
ffi_pl_bundle_init(const char *package, int argc, void *argv[])
{
  version = argv[0];
  say     = argv[1];

  say("in init!");

  snprintf(buffer, 512, "package = %s, version = %s", package, version);
  say(buffer);

  snprintf(buffer, 512, "args = %d", argc);
  say(buffer);
}

void
ffi_pl_bundle_fini(const char *package)
{
  say("in fini!");
}
