use strict;
use warnings;
use Test::More tests => 14;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'sint8', 'void', 'int',
  ['sint8 *' => 'sint8_p'],
  ['sint8 [10]' => 'sint8_a'],
  ['(sint8)->sint8' => 'sint8_c'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

function [sint8_add => 'add'] => [sint8, sint8] => sint8;
function [sint8_inc => 'inc'] => [sint8_p, sint8] => sint8_p;
function [sint8_sum => 'sum'] => [sint8_a] => sint8;
function [sint8_array_inc => 'array_inc'] => [sint8_a] => void;
function [pointer_null => 'null'] => [] => sint8_p;
function [pointer_is_null => 'is_null'] => [sint8_p] => int;
function [sint8_static_array => 'static_array'] => [] => sint8_a;
function [pointer_null => 'null2'] => [] => sint8_a;

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
function [sint8_set_closure => 'set_closure'] => [sint8_c] => void;
function [sint8_call_closure => 'call_closure'] => [sint8] => sint8;

set_closure($closure);
is call_closure(-2), -4, 'call_closure(-2) = -4';

$closure = closure { undef };
set_closure($closure);
is do { no warnings; call_closure(2) }, 0, 'call_closure(2) = 0';

subtest 'custom type input' => sub {
  plan tests => 1;
  custom_type sint8 => type1 => sub { $_[0]*2 }, undef;
  function [sint8_add => 'custom_add'] => ['type1',sint8] => sint8;
  is custom_add(-2,-1), -5, 'custom_add(-2,-1) = -5';
};
