use strict;
use warnings;
use Test::More tests => 5;
use FindBin ();
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'testlib');
use FFI::TestLib;
use FFI::Platypus qw( ffi_type ffi_signature ffi_lib ffi_sub );

my $isalpha;
my $return_passed_integer_value;

BEGIN {
  our $int = ffi_type none => 'sint32';
  our $sig1 = ffi_signature $int, $int;

  $isalpha = ffi_sub([], 'isalpha', $sig1);

  my $config = FFI::TestLib->config;
  our $testlib = ffi_lib $config->{lib};
  
  $return_passed_integer_value = ffi_sub([$testlib], 'return_passed_integer_value', $sig1);
}

isa_ok $isalpha, 'FFI::Platypus::Sub';

ok  isalpha(ord 'f'), "isalpha('f') = true";
ok !isalpha(ord '0'), "isalpha('0') = false";

is return_passed_integer_value(1), 1, 'return_passed_integer_value(1) = 1';
is return_passed_integer_value(42), 42, 'return_passed_integer_value(1) = 42';
