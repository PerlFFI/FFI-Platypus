#include <bzlib.h>
#include <stdlib.h>

int
bzip2__new(bz_stream **stream, int blockSize100k, int verbosity, int workFactor )
{
  *stream = calloc(1, sizeof(bz_stream));

  return BZ2_bzCompressInit(*stream, blockSize100k, verbosity, workFactor );
}
