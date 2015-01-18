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

my $closure1 = closure { $_[0] * 2 };
set_closure($closure1);
puts(call_closure(2)); # prints "4"

my $closure2 = closure { $_[0] * 4 };
set_closure($closure2);
puts(call_closure(2)); # prints "8"
