use strict;
use warnings;
use Test::More;
use FFI::CheckLib;
use FFI::Platypus;
use File::Spec;

BEGIN
{
  my $path;
  foreach my $inc (@INC)
  {
    $path = File::Spec->catfile($inc, 'forks.pm');
    last if -f $path;
  }

  plan skip_all => 'Test requires forks' unless defined $path && -f $path;
}

use forks;

my $ffi = FFI::Platypus->new(lib => find_lib(lib => 'test', symbol => 'f0', libpath => 't/ffi' ));

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

done_testing;
