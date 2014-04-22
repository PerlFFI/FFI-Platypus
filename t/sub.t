use strict;
use warnings;
use Test::More tests => 3;
use FFI::Platypus qw( ffi_type ffi_signature ffi_lib ffi_sub );

my $isalpha;

BEGIN {
  our $int = ffi_type none => 'sint32';
  our $sig = ffi_signature $int, $int;

  $isalpha = ffi_sub([], 'isalpha', $sig);
}

isa_ok $isalpha, 'FFI::Platypus::Sub';

ok  isalpha(ord 'f'), "isalpha('f') = true";
ok !isalpha(ord '0'), "isalpha('0') = false";
