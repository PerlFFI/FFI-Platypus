use strict;
use warnings;
use Test::More tests => 3;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'sint8',
  ['sint8 *' => 'sint8_p'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

function [sint8_add => 'add'] => [sint8, sint8] => sint8;
function [sint8_inc => 'inc'] => [sint8_p, sint8] => sint8_p;

is add(-1,2), 1, 'add(-1,2) = 1';

my $i = -3;
is_deeply inc(\$i, 4), \1, 'inc(\$i,4) = \1';

is_deeply inc(\-3,4), \1, 'inc(\-3,4) = \1';
