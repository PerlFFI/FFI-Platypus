#
# DO NOT MODIFY THIS FILE.
# Thisfile generated from similar file t/type_sint8.t
# all instances of "int8" have been changed to "int64"
#
use strict;
use warnings;
use Test::More tests => 19;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'sint64', 'void', 'int', 'size_t',
  ['sint64 *' => 'sint64_p'],
  ['sint64 [10]' => 'sint64_a'],
  ['sint64 []' => 'sint64_a2'],
  ['(sint64)->sint64' => 'sint64_c'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

attach [sint64_add => 'add'] => [sint64, sint64] => sint64;
attach [sint64_inc => 'inc'] => [sint64_p, sint64] => sint64_p;
attach [sint64_sum => 'sum'] => [sint64_a] => sint64;
attach [sint64_sum2 => 'sum2'] => [sint64_a2,size_t] => sint64;
attach [sint64_array_inc => 'array_inc'] => [sint64_a] => void;
attach [pointer_null => 'null'] => [] => sint64_p;
attach [pointer_is_null => 'is_null'] => [sint64_p] => int;
attach [sint64_static_array => 'static_array'] => [] => sint64_a;
attach [pointer_null => 'null2'] => [] => sint64_a;

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
attach [sint64_set_closure => 'set_closure'] => [sint64_c] => void;
attach [sint64_call_closure => 'call_closure'] => [sint64] => sint64;

set_closure($closure);
is call_closure(-2), -4, 'call_closure(-2) = -4';

$closure = closure { undef };
set_closure($closure);
is do { no warnings; call_closure(2) }, 0, 'call_closure(2) = 0';

subtest 'custom type input' => sub {
  plan tests => 2;
  custom_type type1 => { native_type => 'uint64', perl_to_native => sub { is $_[0], -2; $_[0]*2 } };
  attach [sint64_add => 'custom_add'] => ['type1',sint64] => sint64;
  is custom_add(-2,-1), -5, 'custom_add(-2,-1) = -5';
};

subtest 'custom type output' => sub {
  plan tests => 2;
  custom_type type2 => { native_type => 'sint64', native_to_perl => sub { is $_[0], -3; $_[0]*2 } };
  attach [sint64_add => 'custom_add2'] => [sint64,sint64] => 'type2';
  is custom_add2(-2,-1), -6, 'custom_add2(-2,-1) = -6';
};

attach [pointer_is_null => 'closure_pointer_is_null'] => ['()->void'] => int;
is closure_pointer_is_null(), 1, 'closure_pointer_is_null() = 1';

