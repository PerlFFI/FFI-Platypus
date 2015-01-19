use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus::Memory qw( malloc );
use FFI::Platypus::Declare
  qw( void opaque string ),
  [ '::PointerSizeBuffer' => 'buffer_t2' ];

load_custom_type '::PointerSizeBuffer' => 'buffer_t';

lib undef;
attach memcpy => [opaque, 'buffer_t'] => void;

my $string  = "luna park\0";
my $pointer = malloc length $string;
memcpy($pointer, $string);

my $string2 = cast opaque => string, $pointer;

is $string2, 'luna park';
