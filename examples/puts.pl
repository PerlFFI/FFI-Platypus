use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new( api => 2, lib => undef );
$ffi->attach( puts => ['string'] => 'int' );

puts("hello world");
