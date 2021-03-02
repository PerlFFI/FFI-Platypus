use strict;
use warnings;
use FFI::Platypus 1.00;

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib(undef);

$ffi->attach(puts => ['string'] => 'int');
$ffi->attach(atoi => ['string'] => 'int');

puts(atoi('56'));
