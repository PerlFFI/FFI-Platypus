#
# DO NOT MODIFY THIS FILE.
# Thisfile generated from similar file t/type_uint8.t
# all instances of "int8" have been changed to "int16"
#
use strict;
use warnings;
use Test::More tests => 10;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'uint16', 'void', 'int',
  ['uint16 *' => 'uint16_p'],
  ['uint16 [10]' => 'uint16_a'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

function [uint16_add => 'add'] => [uint16, uint16] => uint16;
function [uint16_inc => 'inc'] => [uint16_p, uint16] => uint16_p;
function [uint16_sum => 'sum'] => [uint16_a] => uint16;
function [uint16_array_inc => 'array_inc'] => [uint16_a] => void;
function [pointer_null => 'null'] => [] => uint16_p;
function [pointer_is_null => 'is_null'] => [uint16_p] => int;
function [uint16_static_array => 'static_array'] => [] => uint16_a;
function [pointer_null => 'null2'] => [] => uint16_a;

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
is is_null(\22), 0, 'is_null(22) == 0';

is_deeply static_array(), [1,4,6,8,10,12,14,16,18,20], 'static_array = [1,4,6,8,10,12,14,16,18,20]';

is null2(), undef, 'null2() == undef';
