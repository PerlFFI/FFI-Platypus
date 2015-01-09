#
# DO NOT MODIFY THIS FILE.
# Thisfile generated from similar file t/type_sint8.t
# all instances of "int8" have been changed to "int64"
#
use strict;
use warnings;
use Test::More tests => 14;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'sint64', 'void', 'int',
  ['sint64 *' => 'sint64_p'],
  ['sint64 [10]' => 'sint64_a'],
  ['(sint64)->sint64' => 'sint64_c'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

function [sint64_add => 'add'] => [sint64, sint64] => sint64;
function [sint64_inc => 'inc'] => [sint64_p, sint64] => sint64_p;
function [sint64_sum => 'sum'] => [sint64_a] => sint64;
function [sint64_array_inc => 'array_inc'] => [sint64_a] => void;
function [pointer_null => 'null'] => [] => sint64_p;
function [pointer_is_null => 'is_null'] => [sint64_p] => int;
function [sint64_static_array => 'static_array'] => [] => sint64_a;
function [pointer_null => 'null2'] => [] => sint64_a;

is add(-1,2), 1, 'add(-1,2) = 1';

my $i = -3;
is ${inc(\$i, 4)}, 1, 'inc(\$i,4) = \1';

is $i, 1, "i=1";

is ${inc(\-3,4)}, 1, 'inc(\-3,4) = \1';

my @list = (-5,-4,-3,-2,-1,0,1,2,3,4);

is sum(\@list), -5, 'sum([-5..4]) = -5';

array_inc(\@list);

is_deeply \@list, [-4,-3,-2,-1,0,1,2,3,4,5], 'array increment';

is null(), undef, 'null() == undef';
is is_null(undef), 1, 'is_null(undef) == 1';
is is_null(\22), 0, 'is_null(22) == 0';

is_deeply static_array(), [-1,2,-3,4,-5,6,-7,8,-9,10], 'static_array = [-1,2,-3,4,-5,6,-7,8,-9,10]';

is null2(), undef, 'null2() == undef';

my $closure = closure { $_[0]-2 };
function [sint64_set_closure => 'set_closure'] => [sint64_c] => void;
function [sint64_call_closure => 'call_closure'] => [sint64] => sint64;

set_closure($closure);
is call_closure(-2), -4, 'call_closure(-2) = -4';

$closure = closure { undef };
set_closure($closure);
is do { no warnings; call_closure(2) }, 0, 'call_closure(2) = 0';

pass 'extra test';
