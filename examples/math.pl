use strict;
use warnings;
use FFI::Platypus;
use FFI::CheckLib;

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib(undef);
$ffi->attach(puts => ['string'] => 'int');
$ffi->attach(fdim => ['double','double'] => 'double');

puts(fdim(7.0, 2.0));

$ffi->attach(cos => ['double'] => 'double');

puts(cos(2.0));

$ffi->attach(fmax => ['double', 'double'] => 'double');

puts(fmax(2.0,3.0));
