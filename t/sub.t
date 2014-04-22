use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus qw( ffi_type ffi_signature ffi_lib ffi_sub );

my $int = ffi_type none => 'sint32';
my $sig = ffi_signature $int, $int;
my $lib = ffi_lib undef;

my $isalpha = ffi_sub($lib, 'isalpha', 'main::isalpha', $sig);
isa_ok $isalpha, 'FFI::Platypus::Sub';

main::isalpha(1);
