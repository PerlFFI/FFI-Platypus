use strict;
use warnings;
use Test::More tests => 3;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'string', 'int';

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

function 'string_matches_foobarbaz' => [string] => int;
function 'string_return_foobarbaz'  => []       => string;

ok string_matches_foobarbaz("foobarbaz"), "string_matches_foobarbaz(foobarbaz) = true";
ok !string_matches_foobarbaz("x"), "string_matches_foobarbaz(foobarbaz) = false";
is string_return_foobarbaz(), "foobarbaz", "string_return_foobarbaz() = foobarbaz";
