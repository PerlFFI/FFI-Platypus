use strict;
use warnings;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;
$ffi->lib(undef);

$ffi->attach(puts => ['string'] => 'int');
$ffi->attach(getpid => [] => 'int');

puts(getpid());
