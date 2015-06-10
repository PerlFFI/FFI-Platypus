use strict;
use warnings;
use Test::More;
BEGIN { plan skip_all => 'Test requires a threading Perl' unless eval q{ use threads; 1 } }
use FFI::CheckLib;
use FFI::Platypus;

plan tests => 2;

my $ffi = FFI::Platypus->new(lib => find_lib(lib => 'test', symbol => 'f0', libpath => 'libtest' ));

sub f0
{
  $ffi->function(f0 => ['uint8'] => 'uint8')->call(@_);
}

sub otherthread
{
  my $val = f0(22);
  undef $ffi;
  $val;
}

is(threads->create(\&otherthread)->join(), 22, 'works in a thread');

is f0(24), 24, 'works in main thread';
