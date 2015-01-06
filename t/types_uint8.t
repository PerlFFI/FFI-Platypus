use strict;
use warnings;
use Test::More tests => 3;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'uint8',
  ['uint8 *' => 'uint8_p'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

function [uint8_add => 'add'] => [uint8, uint8] => uint8;
function [uint8_inc => 'inc'] => [uint8_p, uint8] => uint8_p;

is add(1,2), 3, 'add(1,2) = 3';

my $i = 3;
is_deeply inc(\$i, 4), \7, 'inc(\$i,4) = \7';

is_deeply inc(\3,4), \7, 'inc(\3,4) = \7';
