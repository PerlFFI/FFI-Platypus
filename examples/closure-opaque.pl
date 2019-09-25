use strict;
use warnings;
use FFI::Platypus;

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib('./closure.so');
$ffi->type('(int)->int' => 'closure_t');

$ffi->attach(set_closure => ['closure_t'] => 'void');
$ffi->attach(call_closure => ['int'] => 'int');

my $closure = $ffi->closure(sub { $_[0] * 6 });
my $opaque = $ffi->cast(closure_t => 'opaque', $closure);
set_closure($opaque);
print call_closure(2), "\n"; # prints "12"
