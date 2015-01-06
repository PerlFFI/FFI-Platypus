#
# DO NOT MODIFY THIS FILE.
# Thisfile generated from similar file t/type_uint8.t
# all instances of "int8" have been changed to "int32"
#
use strict;
use warnings;
use Test::More tests => 9;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'uint32', 'void', 'int',
  ['uint32 *' => 'uint32_p'],
  ['uint32 [10]' => 'uint32_a'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

function [uint32_add => 'add'] => [uint32, uint32] => uint32;
function [uint32_inc => 'inc'] => [uint32_p, uint32] => uint32_p;
function [uint32_sum => 'sum'] => [uint32_a] => uint32;
function [uint32_array_inc => 'array_inc'] => [uint32_a] => void;
function [pointer_null => 'null'] => [] => uint32_p;
function [pointer_is_null => 'is_null'] => [uint32_p] => int;
function [uint32_static_array => 'static_array'] => [] => uint32_a;
function [pointer_null => 'null2'] => [] => uint32_a;

is add(1,2), 3, 'add(1,2) = 3';

my $i = 3;
is_deeply inc(\$i, 4), \7, 'inc(\$i,4) = \7';

is_deeply inc(\3,4), \7, 'inc(\3,4) = \7';

my @list = (1,2,3,4,5,6,7,8,9,10);

is sum(\@list), 55, 'sum([1..10]) = 55';

array_inc(\@list);

is_deeply \@list, [2,3,4,5,6,7,8,9,10,11], 'array increment';

is null(), undef, 'null() == undef';
is is_null(undef), 1, 'is_null(undef) == 1';

is_deeply static_array(), [1,4,6,8,10,12,14,16,18,20], 'static_array = [1,4,6,8,10,12,14,16,18,20]';

is null2(), undef, 'null2() == undef';
