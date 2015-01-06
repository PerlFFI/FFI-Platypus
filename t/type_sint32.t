#
# DO NOT MODIFY THIS FILE.
# Thisfile generated from similar file t/type_sint8.t
# all instances of "int8" have been changed to "int32"
#
use strict;
use warnings;
use Test::More tests => 10;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'sint32', 'void', 'int',
  ['sint32 *' => 'sint32_p'],
  ['sint32 [10]' => 'sint32_a'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

function [sint32_add => 'add'] => [sint32, sint32] => sint32;
function [sint32_inc => 'inc'] => [sint32_p, sint32] => sint32_p;
function [sint32_sum => 'sum'] => [sint32_a] => sint32;
function [sint32_array_inc => 'array_inc'] => [sint32_a] => void;
function [pointer_null => 'null'] => [] => sint32_p;
function [pointer_is_null => 'is_null'] => [sint32_p] => int;
function [sint32_static_array => 'static_array'] => [] => sint32_a;
function [pointer_null => 'null2'] => [] => sint32_a;

is add(-1,2), 1, 'add(-1,2) = 1';

my $i = -3;
is_deeply inc(\$i, 4), \1, 'inc(\$i,4) = \1';

is_deeply inc(\-3,4), \1, 'inc(\-3,4) = \1';

my @list = (-5,-4,-3,-2,-1,0,1,2,3,4);

is sum(\@list), -5, 'sum([-5..4]) = -5';

array_inc(\@list);

is_deeply \@list, [-4,-3,-2,-1,0,1,2,3,4,5], 'array increment';

is null(), undef, 'null() == undef';
is is_null(undef), 1, 'is_null(undef) == 1';
is is_null(\22), 0, 'is_null(22) == 0';

is_deeply static_array(), [-1,2,-3,4,-5,6,-7,8,-9,10], 'static_array = [-1,2,-3,4,-5,6,-7,8,-9,10]';

is null2(), undef, 'null2() == undef';
