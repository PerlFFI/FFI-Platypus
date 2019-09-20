use strict;
use warnings;
use FFI::Platypus;
use FFI::Platypus::Memory qw( malloc free memcpy );

my $ffi = FFI::Platypus->new( api => 1 );
my $buffer = malloc 12;

memcpy $buffer, $ffi->cast('string' => 'opaque', "hello there"), length "hello there\0";

print $ffi->cast('opaque' => 'string', $buffer), "\n";

free $buffer;
