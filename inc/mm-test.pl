use strict;
use warnings;
use lib 'lib';
use FFI::Build;
use lib 'inc';
use My::Config;
use My::ShareConfig;

my $config = My::Config->new;

FFI::Build->new(
  'test',
  source   => ['t/ffi/*.c'],
  verbose  => 1,
  alien    => [$config->build_config->get('alien')->{class}],
  cflags   => ['-Iinclude'],
  dir      => 't/ffi',
  platform => $config->platform,
)->build;

