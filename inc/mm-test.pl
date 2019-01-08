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
  verbose  => (!!$ENV{V} ? 2 : 1),
  alien    => [$config->share_config->get('alien')->{class}],
  cflags   => ['-Iinclude'],
  dir      => 't/ffi',
  platform => $config->platform,
)->build;

if($config->platform->which('cargo'))
{
  chdir 't/ffi/rusty';
  print "+ cargo build\n";
  system 'cargo', 'build';
  chdir '../../..';
}
        
