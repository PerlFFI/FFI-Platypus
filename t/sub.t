use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus qw( ffi_type ffi_signature ffi_lib ffi_sub );

my $isalpha;

BEGIN {
  my $int = ffi_type none => 'sint32';
  my $sig = ffi_signature $int, $int;

  $isalpha = ffi_sub([], 'isalpha', $sig);
}

isa_ok $isalpha, 'FFI::Platypus::Sub';

isalpha(1);
