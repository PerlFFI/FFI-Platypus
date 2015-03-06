use strict;
use warnings;
use Test::More tests => 5;
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

$ffi->attach([f0 => 'f0_wrap'] => ['uint8'] => uint8 => sub {
  my($inner, $value) = @_;
  
  return $inner->($value+1)+2;
});

$ffi->attach([f0 => 'f0_wrap2'] => ['uint8'] => uint8 => '$' => sub {
  my($inner, $value) = @_;
  
  return $inner->($value+1)+2;
});

is f0_wrap(22), 25, 'f0_wrap(22) = 25';
is f0_wrap2(22), 25, 'f0_wrap(22) = 25';
