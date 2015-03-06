use strict;
use warnings;
use FFI::Platypus::Declare
  'int', 'void', 'string',
  ['(int)->int' => 'closure_t'];

lib './closure.so';
lib undef; # for puts

attach set_closure => [closure_t] => void;
attach call_closure => [int] => int;
attach puts => [string] => int;

my $closure = closure { $_[0] * 6 };
my $opaque = cast closure_t => 'opaque', $closure;
set_closure($opaque);
puts(call_closure(2)); # prints "12"
