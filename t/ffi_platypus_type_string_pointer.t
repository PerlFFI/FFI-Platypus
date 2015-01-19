use strict;
use warnings;
use Test::More tests => 3;
use FFI::CheckLib;
use FFI::Platypus::Declare
  qw( int string void ),
  [ '::StringPointer' => 'string_p'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';
attach string_pointer_pointer_get => [string_p] => string;
attach string_pointer_pointer_set => [string_p, string] => void;
attach pointer_pointer_is_null => [string_p] => int;
attach pointer_is_null => [string_p] => int;
attach string_pointer_pointer_return => [string] => string_p;
attach pointer_null => [] => string_p;

subtest 'arg pass in' => sub {
  plan tests => 3;
  is string_pointer_pointer_get(\"hello there"), "hello there", "not null";
  is pointer_pointer_is_null(\undef), 1, "\\undef is null";
  is pointer_is_null(undef), 1, "undef is null";
};

subtest 'arg pass out' => sub {
  plan tests => 2;

  my $string = '';
  string_pointer_pointer_set(\$string, "hi there");
  is $string, "hi there", "not null string = $string";
  
  my $string2;
  string_pointer_pointer_set(\$string2, "and another");
  is $string2, "and another", "not null string = $string2";  
  
};

subtest 'return value' => sub {
  plan tests => 3;
  
  my $string = "once more onto";

  is_deeply string_pointer_pointer_return($string), \"once more onto", "not null string = $string";
  is_deeply string_pointer_pointer_return(undef), \undef, "\\null";
  my $value = pointer_null();
  is $value, undef, "null";

};
