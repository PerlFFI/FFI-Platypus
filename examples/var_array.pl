use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib('./var_array.so');

$ffi->attach( sum => [ 'int[]', 'int' ] => 'int' );

my @list = (1..100);

print sum(\@list, scalar @list), "\n";
