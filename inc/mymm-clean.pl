use strict;
use warnings;
use File::Glob qw( bsd_glob );
use lib 'inc';
use My::AutoConf;

My::AutoConf->clean;
unlink $_ for map { bsd_glob($_) } (
  't/ffi/*.o',
  't/ffi/*.obj',
  't/ffi/*.so',
  't/ffi/*.dll',
  't/ffi/*.bundle',
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
  'include/ffi_platypus_probe.h',
);

rmdir '_mm' if -d '_mm';
