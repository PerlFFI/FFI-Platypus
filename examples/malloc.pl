use strict;
use warnings;
use FFI::Platypus::Memory qw( malloc cast free memcpy );

my $buffer = malloc 12;

memcpy $buffer, cast('string' => 'pointer', "hello there"), length "hello there\0";

print cast('pointer' => 'string', $buffer), "\n";

free $buffer;
