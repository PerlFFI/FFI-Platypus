#include <bzlib.h>
#include <stdlib.h>

int
bzip2__new(bz_stream **stream, int blockSize100k, int verbosity, int workFactor )
{
  *stream = malloc(sizeof(bz_stream));
  (*stream)->bzalloc = NULL;
  (*stream)->bzfree  = NULL;
  (*stream)->opaque  = NULL;

  return BZ2_bzCompressInit(*stream, blockSize100k, verbosity, workFactor );
}
