use strict;
use warnings;
use Test::More tests => 3;
use FFI::CheckLib;
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

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

attach memcmp4 => ['buffer_t', 'buffer_t'] => 'int';

my $str1 = "test";
my $str2 = "test2";
is !!memcmp4($str1, $str2), 1;
is memcmp4($str1, $str1), 0;
