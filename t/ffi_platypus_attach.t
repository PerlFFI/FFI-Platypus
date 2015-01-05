use strict;
use warnings;
use Test::More tests => 3;
use FFI::Platypus;
use FFI::CheckLib;

my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 'libtest');

$ffi->attach('f0' => ['uint8'] => 'uint8');
$ffi->attach([f0=>'f1'] => ['uint8'] => 'uint8');
$ffi->attach([f0=>'Roger::f1'] => ['uint8'] => 'uint8');

is f0(22), 22, 'f0(22) = 22';
is f1(22), 22, 'f1(22) = 22';
is Roger::f1(22), 22, 'Roger::f1(22) = 22';

