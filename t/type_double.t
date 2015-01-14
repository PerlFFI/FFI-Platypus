#
# DO NOT MODIFY THIS FILE.
# Thisfile generated from similar file t/type_float.t
# all instances of "float" have been changed to "double"
#
use strict;
use warnings;
use Test::More tests => 17;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'double', 'void', 'int',
  ['double *' => 'double_p'],
  ['double [10]' => 'double_a'],
  ['(double)->double' => 'double_c'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

function [double_add => 'add'] => [double, double] => double;
function [double_inc => 'inc'] => [double_p, double] => double_p;
function [double_sum => 'sum'] => [double_a] => double;
function [double_array_inc => 'array_inc'] => [double_a] => void;
function [pointer_null => 'null'] => [] => double_p;
function [pointer_is_null => 'is_null'] => [double_p] => int;
function [double_static_array => 'static_array'] => [] => double_a;
function [pointer_null => 'null2'] => [] => double_a;

is add(1.5,2.5), 4, 'add(1.5,2.5) = 4';
is eval { no warnings; add() }, 0.0, 'add() = 0.0';

my $i = 3.5;
is ${inc(\$i, 4.25)}, 7.75, 'inc(\$i,4.25) = \7.75';

is $i, 3.5+4.25, "i=3.5+4.25";

is ${inc(\3,4)}, 7, 'inc(\3,4) = \7';

my @list = (1,2,3,4,5,6,7,8,9,10);

is sum(\@list), 55, 'sum([1..10]) = 55';

array_inc(\@list);
do { local $SIG{__WARN__} = sub {}; array_inc(); };

is_deeply \@list, [2,3,4,5,6,7,8,9,10,11], 'array increment';

is null(), undef, 'null() == undef';
is is_null(undef), 1, 'is_null(undef) == 1';
is is_null(), 1, 'is_null() == 1';
is is_null(\22), 0, 'is_null(22) == 0';

is_deeply static_array(), [-5.5, 5.5, -10, 10, -15.5, 15.5, 20, -20, 25.5, -25.5], 'static_array = [-5.5, 5.5, -10, 10, -15.5, 15.5, 20, -20, 25.5, -25.5]';

is null2(), undef, 'null2() == undef';

my $closure = closure { $_[0]+2.25 };
function [double_set_closure => 'set_closure'] => [double_c] => void;
function [double_call_closure => 'call_closure'] => [double] => double;

set_closure($closure);
is call_closure(2.5), 4.75, 'call_closure(2.5) = 4.75';

$closure = closure { undef };
set_closure($closure);
is do { no warnings; call_closure(2.5) }, 0, 'call_closure(2.5) = 0';

subtest 'custom type input' => sub {
  plan tests => 2;
  custom_type double => type1 => sub { is $_[0], 1.25; $_[0]+0.25 }, undef;
  function [double_add => 'custom_add'] => ['type1',double] => double;
  is custom_add(1.25,2.5), 4, 'custom_add(1.25,2.5) = 4';
};

function [pointer_is_null => 'closure_pointer_is_null'] => ['()->void'] => int;
is closure_pointer_is_null(), 1, 'closure_pointer_is_null() = 1';

