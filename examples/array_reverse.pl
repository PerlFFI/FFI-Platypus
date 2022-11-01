use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api => 1,
  lib => './array_reverse.so',
);

$ffi->attach( array_reverse   => ['int[]','int'] );
$ffi->attach( array_reverse10 => ['int[10]'] );

my @a = (1..10);
array_reverse10( \@a );
print "$_ " for @a;
print "\n";

@a = (1..20);
array_reverse( \@a, 20 );
print "$_ " for @a;
print "\n";
