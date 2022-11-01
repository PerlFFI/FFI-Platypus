use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::Platypus::Memory qw( malloc free memcpy strdup );

my $ffi = FFI::Platypus->new( api => 2 );
my $buffer = malloc 14;
my $ptr_string = strdup("hello there!!\n");

memcpy $buffer, $ptr_string, 15;

print $ffi->cast('opaque' => 'string', $buffer);

free $ptr_string;
free $buffer;
