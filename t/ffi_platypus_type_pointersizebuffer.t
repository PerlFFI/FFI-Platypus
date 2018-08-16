use strict;
use warnings;
use Test::More;
use FFI::CheckLib;
use FFI::Platypus;
use FFI::Platypus::Memory qw( malloc );

my $ffi = FFI::Platypus->new;

$ffi->load_custom_type('::PointerSizeBuffer' => 'buffer_t');
$ffi->load_custom_type('::PointerSizeBuffer' => 'buffer_t2');

$ffi->lib(undef);
$ffi->attach(memcpy => ['opaque', 'buffer_t'] => 'void');

my $string  = "luna park\0";
my $pointer = malloc length $string;
memcpy($pointer, $string);

my $string2 = $ffi->cast('opaque' => 'string', $pointer);

is $string2, 'luna park';

SKIP: {

  eval { $ffi->attach(snprintf => ['buffer_t', 'string' ] => 'int') };
  skip "test require working snprintf", 2 if $@;

  is snprintf($string2, "this is a very long string"), 26;
  is $string2, "this is \000";

}

$ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi');

$ffi->attach(memcmp4 => ['buffer_t', 'buffer_t'] => 'int');

my $str1 = "test";
my $str2 = "test2";
is !!memcmp4($str1, $str2), 1;
is memcmp4($str1, $str1), 0;

done_testing;
