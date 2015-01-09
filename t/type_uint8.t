use strict;
use warnings;
use Test::More tests => 12;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'uint8', 'void', 'int',
  ['uint8 *' => 'uint8_p'],
  ['uint8 [10]' => 'uint8_a'],
  ['(uint8)->uint8' => 'uint8_c'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

function [uint8_add => 'add'] => [uint8, uint8] => uint8;
function [uint8_inc => 'inc'] => [uint8_p, uint8] => uint8_p;
function [uint8_sum => 'sum'] => [uint8_a] => uint8;
function [uint8_array_inc => 'array_inc'] => [uint8_a] => void;
function [pointer_null => 'null'] => [] => uint8_p;
function [pointer_is_null => 'is_null'] => [uint8_p] => int;
function [uint8_static_array => 'static_array'] => [] => uint8_a;
function [pointer_null => 'null2'] => [] => uint8_a;

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

my $closure = closure { $_[0]+2 };
function [uint8_set_closure => 'set_closure'] => [uint8_c] => void;
function [uint8_call_closure => 'call_closure'] => [uint8] => uint8;

set_closure($closure);
is call_closure(2), 4, 'call_closure(2) = 4';

$closure = closure { undef };
set_closure($closure);
is do { no warnings; call_closure(2) }, 0, 'call_closure(2) = 0';

