#
# DO NOT MODIFY THIS FILE.
# Thisfile generated from similar file t/type_uint8.t
# all instances of "int8" have been changed to "int16"
#
use strict;
use warnings;
use Test::More tests => 20;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'uint16', 'void', 'int', 'size_t',
  ['uint16 *' => 'uint16_p'],
  ['uint16 [10]' => 'uint16_a'],
  ['uint16 []' => 'uint16_a2'],
  ['(uint16)->uint16' => 'uint16_c'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

attach [uint16_add => 'add'] => [uint16, uint16] => uint16;
attach [uint16_inc => 'inc'] => [uint16_p, uint16] => uint16_p;
attach [uint16_sum => 'sum'] => [uint16_a] => uint16;
attach [uint16_sum2 => 'sum2'] => [uint16_a2,size_t] => uint16;
attach [uint16_array_inc => 'array_inc'] => [uint16_a] => void;
attach [pointer_null => 'null'] => [] => uint16_p;
attach [pointer_is_null => 'is_null'] => [uint16_p] => int;
attach [uint16_static_array => 'static_array'] => [] => uint16_a;
attach [pointer_null => 'null2'] => [] => uint16_a;

is add(1,2), 3, 'add(1,2) = 3';
is do { no warnings; add() }, 0, 'add() = 0';

my $i = 3;
is ${inc(\$i, 4)}, 7, 'inc(\$i,4) = \7';

is $i, 3+4, "i=3+4";

is ${inc(\3,4)}, 7, 'inc(\3,4) = \7';

my @list = (1,2,3,4,5,6,7,8,9,10);

is sum(\@list), 55, 'sum([1..10]) = 55';
is sum2(\@list, scalar @list), 55, 'sum2([1..10],10) = 55';

array_inc(\@list);
do { local $SIG{__WARN__} = sub {}; array_inc() };

is_deeply \@list, [2,3,4,5,6,7,8,9,10,11], 'array increment';

is null(), undef, 'null() == undef';
is is_null(undef), 1, 'is_null(undef) == 1';
is is_null(), 1, 'is_null() == 1';
is is_null(\22), 0, 'is_null(22) == 0';

is_deeply static_array(), [1,4,6,8,10,12,14,16,18,20], 'static_array = [1,4,6,8,10,12,14,16,18,20]';

is null2(), undef, 'null2() == undef';

my $closure = closure { $_[0]+2 };
attach [uint16_set_closure => 'set_closure'] => [uint16_c] => void;
attach [uint16_call_closure => 'call_closure'] => [uint16] => uint16;

set_closure($closure);
is call_closure(2), 4, 'call_closure(2) = 4';

$closure = closure { undef };
set_closure($closure);
is do { no warnings; call_closure(2) }, 0, 'call_closure(2) = 0';

subtest 'custom type input' => sub {
  plan tests => 2;
  custom_type type1 => { native_type => 'uint16', perl_to_native => sub { is $_[0], 2; $_[0]*2 } };
  attach [uint16_add => 'custom_add'] => ['type1',uint16] => uint16;
  is custom_add(2,1), 5, 'custom_add(2,1) = 5';
};

subtest 'custom type output' => sub {
  plan tests => 2;
  custom_type type2 => { native_type => 'uint16', native_to_perl => sub { is $_[0], 2; $_[0]*2 } };
  attach [uint16_add => 'custom_add2'] => [uint16,uint16] => 'type2';
  is custom_add2(1,1), 4, 'custom_add2(1,1) = 4';
};

subtest 'custom type post' => sub {
  plan tests => 2;
  custom_type type3 => { native_type => 'uint16', perl_to_native_post => sub { is $_[0], 1 } };
  attach [uint16_add => 'custom_add3'] => ['type3',uint16] => uint16;
  is custom_add3(1,2), 3, 'custom_add3(1,2) = 3';
};

attach [pointer_is_null => 'closure_pointer_is_null'] => ['()->void'] => int;
is closure_pointer_is_null(), 1, 'closure_pointer_is_null() = 1';
