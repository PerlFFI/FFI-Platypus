use strict;
use warnings;
use Test::More tests => 20;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'uint8', 'void', 'int', 'size_t',
  ['uint8 *' => 'uint8_p'],
  ['uint8 [10]' => 'uint8_a'],
  ['uint8 []' => 'uint8_a2'],
  ['(uint8)->uint8' => 'uint8_c'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

attach [uint8_add => 'add'] => [uint8, uint8] => uint8;
attach [uint8_inc => 'inc'] => [uint8_p, uint8] => uint8_p;
attach [uint8_sum => 'sum'] => [uint8_a] => uint8;
attach [uint8_sum2 => 'sum2'] => [uint8_a2,size_t] => uint8;
attach [uint8_array_inc => 'array_inc'] => [uint8_a] => void;
attach [pointer_null => 'null'] => [] => uint8_p;
attach [pointer_is_null => 'is_null'] => [uint8_p] => int;
attach [uint8_static_array => 'static_array'] => [] => uint8_a;
attach [pointer_null => 'null2'] => [] => uint8_a;

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
attach [uint8_set_closure => 'set_closure'] => [uint8_c] => void;
attach [uint8_call_closure => 'call_closure'] => [uint8] => uint8;

set_closure($closure);
is call_closure(2), 4, 'call_closure(2) = 4';

$closure = closure { undef };
set_closure($closure);
is do { no warnings; call_closure(2) }, 0, 'call_closure(2) = 0';

subtest 'custom type input' => sub {
  plan tests => 2;
  custom_type type1 => { native_type => 'uint8', perl_to_native => sub { is $_[0], 2; $_[0]*2 } };
  attach [uint8_add => 'custom_add'] => ['type1',uint8] => uint8;
  is custom_add(2,1), 5, 'custom_add(2,1) = 5';
};

subtest 'custom type output' => sub {
  plan tests => 2;
  custom_type type2 => { native_type => 'uint8', native_to_perl => sub { is $_[0], 2; $_[0]*2 } };
  attach [uint8_add => 'custom_add2'] => [uint8,uint8] => 'type2';
  is custom_add2(1,1), 4, 'custom_add2(1,1) = 4';
};

subtest 'custom type post' => sub {
  plan tests => 2;
  custom_type type3 => { native_type => 'uint8', perl_to_native_post => sub { is $_[0], 1 } };
  attach [uint8_add => 'custom_add3'] => ['type3',uint8] => uint8;
  is custom_add3(1,2), 3, 'custom_add3(1,2) = 3';
};

attach [pointer_is_null => 'closure_pointer_is_null'] => ['()->void'] => int;
is closure_pointer_is_null(), 1, 'closure_pointer_is_null() = 1';
