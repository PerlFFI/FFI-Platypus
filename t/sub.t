use strict;
use warnings;
use Test::More tests => 11;
use FindBin ();
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'testlib');
use FFI::TestLib;
use FFI::Platypus qw( ffi_type ffi_signature ffi_lib ffi_sub );

my $isalpha;
my $return_passed_integer_value;

BEGIN {
  our $char  = ffi_type c => 'char';
  our $short = ffi_type c => 'short';
  our $int   = ffi_type c => 'int';
  our $long  = ffi_type c => 'long';
  our $sig1  = ffi_signature $int, $int;

  $isalpha = ffi_sub([], 'isalpha', $sig1);

  my $config = FFI::TestLib->config;
  our $testlib = ffi_lib $config->{lib};
  
  $return_passed_integer_value = ffi_sub([$testlib], 'return_passed_integer_value', $sig1);
  
  our $sig2 = ffi_signature $long, $char;
  our $sig3 = ffi_signature $long, $short;
  our $sig4 = ffi_signature $long, $int;
  our $sig5 = ffi_signature $long, $long;
  
  ffi_sub [$testlib], 'char_to_long', $sig2;
  ffi_sub [$testlib], 'short_to_long', $sig3;
  ffi_sub [$testlib], 'int_to_long', $sig4;
  ffi_sub [$testlib], 'long_to_long', $sig5;
  
  our $sig6 = ffi_signature $int, map { $int } 1..10;
  ffi_sub [$testlib], 'sum_integer_values10', $sig6;
  
  our $sig7 = ffi_signature $int, $int, $int;
  ffi_sub [$testlib], 'add_integer_value', $sig7;
}

isa_ok $isalpha, 'FFI::Platypus::Sub';

ok  isalpha(ord 'f'), "isalpha('f') = true";
ok !isalpha(ord '0'), "isalpha('0') = false";

is return_passed_integer_value(1), 1, 'return_passed_integer_value(1) = 1';
is return_passed_integer_value(42), 42, 'return_passed_integer_value(1) = 42';

is char_to_long(42),    42, 'char_to_long';
is short_to_long(100), 100, 'short_to_long';
is int_to_long(200),   200, 'int_to_long';
is long_to_long(500),  500, 'long_to_long';

is sum_integer_values10(1,2,3,4,5,6,7,8,9,10), 1+2+3+4+5+6+7+8+9+10, 'sum_integer_values10';

is add_integer_value(1,2), 3, 'add_integer_value';
