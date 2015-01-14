use strict;
use warnings;
use Test::More tests => 9;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'string', 'int', 'void';

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
is is_null(), 1, 'is_null() = 1';
is is_null("foo"), 0, 'is_null("foo") = 0';

function [string_set_closure => 'set_closure']   => ['(string)->void'] => void;
function [string_call_closure => 'call_closure'] => [string]=>void;

my $save = 1;
my $closure = closure { $save = $_[0] };

set_closure($closure);
call_closure("hey there");
is $save, "hey there", "\$save = hey there";

call_closure(undef);
is $save, undef, "\$save = undef";
