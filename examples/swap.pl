use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api => 1,
  lib => './swap.so',
);

$ffi->attach( swap => ['int*','int*'] );

my $a = 1;
my $b = 2;

print "[a,b] = [$a,$b]\n";

swap( \$a, \$b );

print "[a,b] = [$a,$b]\n";
