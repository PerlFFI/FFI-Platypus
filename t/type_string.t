use strict;
use warnings;
use Test::More tests => 6;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'string', 'int';

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

function 'string_matches_foobarbaz'     => [string] => int;
function 'string_return_foobarbaz'      => []       => string;
function [pointer_null => 'null']       => []       => string;
function [pointer_is_null => 'is_null'] => [string] => int;

ok string_matches_foobarbaz("foobarbaz"), "string_matches_foobarbaz(foobarbaz) = true";
ok !string_matches_foobarbaz("x"), "string_matches_foobarbaz(foobarbaz) = false";
is string_return_foobarbaz(), "foobarbaz", "string_return_foobarbaz() = foobarbaz";

is null(), undef, 'null() = undef';
is is_null(undef), 1, 'is_null(undef) = 1';
is is_null("foo"), 0, 'is_null("foo") = 0';
