use strict;
use warnings;
use Test::More tests => 18;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'float', 'void', 'int',
  ['float *' => 'float_p'],
  ['float [10]' => 'float_a'],
  ['(float)->float' => 'float_c'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

function [float_add => 'add'] => [float, float] => float;
function [float_inc => 'inc'] => [float_p, float] => float_p;
function [float_sum => 'sum'] => [float_a] => float;
function [float_array_inc => 'array_inc'] => [float_a] => void;
function [pointer_null => 'null'] => [] => float_p;
function [pointer_is_null => 'is_null'] => [float_p] => int;
function [float_static_array => 'static_array'] => [] => float_a;
function [pointer_null => 'null2'] => [] => float_a;

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
function [float_set_closure => 'set_closure'] => [float_c] => void;
function [float_call_closure => 'call_closure'] => [float] => float;

set_closure($closure);
is call_closure(2.5), 4.75, 'call_closure(2.5) = 4.75';

$closure = closure { undef };
set_closure($closure);
is do { no warnings; call_closure(2.5) }, 0, 'call_closure(2.5) = 0';

subtest 'custom type input' => sub {
  plan tests => 2;
  custom_type float => type1 => { perl_to_ffi => sub { is $_[0], 1.25; $_[0]+0.25 } };
  function [float_add => 'custom_add'] => ['type1',float] => float;
  is custom_add(1.25,2.5), 4, 'custom_add(1.25,2.5) = 4';
};

subtest 'custom type output' => sub {
  plan tests => 2;
  custom_type float => type2 => { ffi_to_perl => sub { is $_[0], 2.0; $_[0]+0.25 } };
  function [float_add => 'custom_add2'] => [float,float] => 'type2';
  is custom_add2(1,1), 2.25, 'custom_add2(1,1) = 2.25';
};

function [pointer_is_null => 'closure_pointer_is_null'] => ['()->void'] => int;
is closure_pointer_is_null(), 1, 'closure_pointer_is_null() = 1';

