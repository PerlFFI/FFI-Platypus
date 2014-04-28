use strict;
use warnings;
use Test::More tests => 15;
use FindBin ();
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'testlib');
use FFI::TestLib;
use FFI::Platypus qw( ffi_type ffi_signature ffi_lib ffi_sub );

my $isalpha;
my $return_passed_integer_value;

BEGIN {
  my $char  = ffi_type c => 'signed char';
  my $short = ffi_type c => 'short';
  my $int   = ffi_type c => 'int';
  my $long  = ffi_type c => 'long';

  $isalpha = ffi_sub([], 'isalpha', [$int, $int] );

  my $config = FFI::TestLib->config;
  my $testlib = ffi_lib $config->{lib};
  
  $return_passed_integer_value = ffi_sub([$testlib], 'return_passed_integer_value', [$int, $int]);
  
  ffi_sub [$testlib], 'char_to_long',  [$long, $char];
  ffi_sub [$testlib], 'short_to_long', [$long, $short];
  ffi_sub [$testlib], 'int_to_long',   [$long, $int];
  ffi_sub [$testlib], 'long_to_long',  [$long, $long];
  ffi_sub [$testlib], 'sum_integer_values10', [$int, map { $int } 1..10];  
  ffi_sub [$testlib], 'add_integer_value', [$int, $int, $int];
}

isa_ok $isalpha, 'FFI::Platypus::Sub';

ok  isalpha(ord 'f'), "isalpha('f') = true";
ok !isalpha(ord '0'), "isalpha('0') = false";

is return_passed_integer_value(1), 1, 'return_passed_integer_value(1) = 1';
is return_passed_integer_value(42), 42, 'return_passed_integer_value(1) = 42';

is char_to_long (42),   42, 'char_to_long';
is short_to_long(100), 100, 'short_to_long';
is int_to_long  (200), 200, 'int_to_long';
is long_to_long (500), 500, 'long_to_long';

is char_to_long (-42),   -42, 'char_to_long neg';
is short_to_long(-100), -100, 'short_to_long neg';
is int_to_long  (-200), -200, 'int_to_long neg';
is long_to_long (-500), -500, 'long_to_long neg';

is sum_integer_values10(1,2,3,4,5,6,7,8,9,10), 1+2+3+4+5+6+7+8+9+10, 'sum_integer_values10';

is add_integer_value(1,2), 3, 'add_integer_value';
