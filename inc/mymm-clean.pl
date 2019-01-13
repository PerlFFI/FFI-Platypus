use strict;
use warnings;
use File::Glob qw( bsd_glob );
use lib 'inc';
use My::AutoConf;

My::AutoConf->clean;
unlink $_ for map { bsd_glob($_) } (
  't/ffi/_build/*.o',
  't/ffi/*.so',
  't/ffi/*.dll',
  't/ffi/*.bundle',
  'xs/*.o',
  'xs/*.obj',
  '_mm/*',
  'examples/*.o',
  'examples/*.so',
  'examples/*.dll',
  'examples/*.bundle',
  'examples/java/*.so',
  'examples/java/*.o',
  'config.log',
  'test*.o',
  'test*.c',
  '*.core',
  'core',
  'include/ffi_platypus_config.h',
  'FFI-Platypus-*.tar.gz',
);

rmdir '_mm' if -d '_mm';
rmdir 't/ffi/_build' if -d 't/ffi/_build';
