use strict;
use warnings;
use Test::More tests => 5;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'uint8', 'void',
  ['uint8 *' => 'uint8_p'],
  ['uint8 [10]' => 'uint8_a'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

function [uint8_add => 'add'] => [uint8, uint8] => uint8;
function [uint8_inc => 'inc'] => [uint8_p, uint8] => uint8_p;
function [uint8_sum => 'sum'] => [uint8_a] => uint8;
function [uint8_array_inc => 'array_inc'] => [uint8_a] => void;

is add(1,2), 3, 'add(1,2) = 3';

my $i = 3;
is_deeply inc(\$i, 4), \7, 'inc(\$i,4) = \7';

is_deeply inc(\3,4), \7, 'inc(\3,4) = \7';

my @list = (1,2,3,4,5,6,7,8,9,10);

is sum(\@list), 55, 'sum([1..10]) = 55';

array_inc(\@list);

is_deeply \@list, [2,3,4,5,6,7,8,9,10,11], 'array increment';
