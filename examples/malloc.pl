use strict;
use warnings;
use FFI::Platypus::Declare;
use FFI::Platypus::Memory qw( malloc free memcpy );

my $buffer = malloc 12;

memcpy $buffer, cast('string' => 'opaque', "hello there"), length "hello there\0";

print cast('opaque' => 'string', $buffer), "\n";

free $buffer;
