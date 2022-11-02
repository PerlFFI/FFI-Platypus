use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => './array_sum.so',
);

$ffi->attach( array_sum => ['int*'] => 'int' );

print array_sum(undef), "\n";     # -1
print array_sum([0]), "\n";       # 0
print array_sum([1,2,3,0]), "\n"; # 6
