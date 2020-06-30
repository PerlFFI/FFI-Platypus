use strict;
use warnings;
use Test::More;
BEGIN { plan skip_all => 'Test requires a threading Perl' unless eval q{ use threads; 1 } }
use FFI::CheckLib;
use FFI::Platypus;
use Config;

if("$^V" eq "v5.10.0")
{
  diag '';
  diag '';
  diag '';
  diag "Note that there are known but unresolved issues with Platypus on threaded 5.10.0 Perls.";
  diag "If you know that you will not be using threads you can safely ignore any failures with";
  diag "this test.  If you need threads you can either upgrade to 5.10.1+ or downgrade to 5.8.9-";
  diag '';
  diag "You can also follow along with this issue here:";
  diag "https://github.com/PerlFFI/FFI-Platypus/issues/68";
  diag '';
  diag '';
}

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
