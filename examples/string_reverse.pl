use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => './string_reverse.so',
);

$ffi->attach( string_reverse => ['string'] => 'string' );

print string_reverse("\nHello world");

string_reverse(undef);
