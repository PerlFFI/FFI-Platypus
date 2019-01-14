use strict;
use warnings;
use lib 'lib';
use FFI::Build;
use lib 'inc';
use My::ShareConfig;

my $share_config = My::ShareConfig->new;

FFI::Build->new(
  'test',
  source => ['t/ffi/*.c'],
  verbose => 1,
  alien => [$share_config->get('alien')->{class}],
  cflags => ['-Iinclude'],
  dir => 't/ffi',
)->build;

