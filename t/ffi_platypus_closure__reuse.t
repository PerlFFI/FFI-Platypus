use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib;

my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi');

my $closure = $ffi->closure(sub {
  if (@_) {
    return $_[0] * 7;
  }
  return 21;
});

$ffi->attach( [closure_set_closure1 => 'set_closure1'] => ['()->int'] => 'void');
$ffi->attach( [closure_set_closure2 => 'set_closure2'] => ['(int)->int'] => 'void');
$ffi->attach( [closure_call_closure1 => 'call_closure1'] => [] => 'int');
$ffi->attach( [closure_call_closure2 => 'call_closure2'] => ['int'] => 'int');

set_closure1($closure);
set_closure2($closure);

is call_closure1(), 21;
is call_closure2(42), 294;

done_testing;
