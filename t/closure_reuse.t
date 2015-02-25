use strict;
use warnings;
use Test::More tests => 2;
use FFI::CheckLib;
use FFI::Platypus::Declare qw( void int );

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

my $closure = closure {
  if (@_) {
    return $_[0] * 7;
  }
  return 21;
};

attach [closure_set_closure1 => 'set_closure1'] => ['()->int'] => void;
attach [closure_set_closure2 => 'set_closure2'] => ['(int)->int'] => void;
attach [closure_call_closure1 => 'call_closure1'] => [] => int;
attach [closure_call_closure2 => 'call_closure2'] => [int] => int;

set_closure1($closure);
set_closure2($closure);

is call_closure1(), 21;
is call_closure2(42), 294;
