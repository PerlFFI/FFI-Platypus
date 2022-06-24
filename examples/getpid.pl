use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib(undef);

$ffi->attach(puts => ['string'] => 'int');
$ffi->attach(getpid => [] => 'int');

puts(getpid());
