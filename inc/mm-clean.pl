use strict;
use warnings;
use File::Glob qw( bsd_glob );

unlink $_ for map { bsd_glob($_) } (
  'ffi/_build/*',
  't/ffi/_build/*',
  't/ffi/*.so',
  't/ffi/*.dll',
  't/ffi/*.bundle',
  'xs/*.o',
  'xs/*.obj',
  'examples/*.o',
  'examples/*.so',
  'examples/*.dll',
  'examples/*.bundle',
  'corpus/ffi_build/project1/_build/*',
  'config.log',
  'test*.o',
  'test*.c',
  '*.core',
  'core',
  'include/ffi_platypus_config.h',
  'FFI-Platypus-*.tar.gz',
);

rmdir 'ffi/_build' if -d 'ffi/_build';
rmdir 't/ffi/_build' if -d 't/ffi/_build';
rmdir 'corpus/ffi_build/project1/_build' if -d 'corpus/ffi_build/project1/_build';
