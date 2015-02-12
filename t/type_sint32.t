#
# DO NOT MODIFY THIS FILE.
# Thisfile generated from similar file t/type_sint8.t
# all instances of "int8" have been changed to "int32"
#
use strict;
use warnings;
use Test::More tests => 19;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'sint32', 'void', 'int', 'size_t',
  ['sint32 *' => 'sint32_p'],
  ['sint32 [10]' => 'sint32_a'],
  ['sint32 []' => 'sint32_a2'],
  ['(sint32)->sint32' => 'sint32_c'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

attach [sint32_add => 'add'] => [sint32, sint32] => sint32;
attach [sint32_inc => 'inc'] => [sint32_p, sint32] => sint32_p;
attach [sint32_sum => 'sum'] => [sint32_a] => sint32;
attach [sint32_sum2 => 'sum2'] => [sint32_a2,size_t] => sint32;
attach [sint32_array_inc => 'array_inc'] => [sint32_a] => void;
attach [pointer_null => 'null'] => [] => sint32_p;
attach [pointer_is_null => 'is_null'] => [sint32_p] => int;
attach [sint32_static_array => 'static_array'] => [] => sint32_a;
attach [pointer_null => 'null2'] => [] => sint32_a;

is add(-1,2), 1, 'add(-1,2) = 1';
is do { no warnings; add() }, 0, 'add() = 0';

my $i = -3;
is ${inc(\$i, 4)}, 1, 'inc(\$i,4) = \1';

is $i, 1, "i=1";

is ${inc(\-3,4)}, 1, 'inc(\-3,4) = \1';

my @list = (-5,-4,-3,-2,-1,0,1,2,3,4);

is sum(\@list), -5, 'sum([-5..4]) = -5';
is sum2(\@list,scalar @list), -5, 'sum([-5..4],10) = -5';

array_inc(\@list);
do { local $SIG{__WARN__} = sub {}; array_inc() };

is_deeply \@list, [-4,-3,-2,-1,0,1,2,3,4,5], 'array increment';

is null(), undef, 'null() == undef';
is is_null(undef), 1, 'is_null(undef) == 1';
is is_null(), 1, 'is_null() == 1';
is is_null(\22), 0, 'is_null(22) == 0';

is_deeply static_array(), [-1,2,-3,4,-5,6,-7,8,-9,10], 'static_array = [-1,2,-3,4,-5,6,-7,8,-9,10]';

is null2(), undef, 'null2() == undef';

my $closure = closure { $_[0]-2 };
attach [sint32_set_closure => 'set_closure'] => [sint32_c] => void;
attach [sint32_call_closure => 'call_closure'] => [sint32] => sint32;

set_closure($closure);
is call_closure(-2), -4, 'call_closure(-2) = -4';

$closure = closure { undef };
set_closure($closure);
is do { no warnings; call_closure(2) }, 0, 'call_closure(2) = 0';

subtest 'custom type input' => sub {
  plan tests => 2;
  custom_type type1 => { native_type => 'uint32', perl_to_native => sub { is $_[0], -2; $_[0]*2 } };
  attach [sint32_add => 'custom_add'] => ['type1',sint32] => sint32;
  is custom_add(-2,-1), -5, 'custom_add(-2,-1) = -5';
};

subtest 'custom type output' => sub {
  plan tests => 2;
  custom_type type2 => { native_type => 'sint32', native_to_perl => sub { is $_[0], -3; $_[0]*2 } };
  attach [sint32_add => 'custom_add2'] => [sint32,sint32] => 'type2';
  is custom_add2(-2,-1), -6, 'custom_add2(-2,-1) = -6';
};

attach [pointer_is_null => 'closure_pointer_is_null'] => ['()->void'] => int;
is closure_pointer_is_null(), 1, 'closure_pointer_is_null() = 1';

