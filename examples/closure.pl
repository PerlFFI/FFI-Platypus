use strict;
use warnings;
use FFI::Platypus;

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib('./closure.so');
$ffi->type('(int)->int' => 'closure_t');

$ffi->attach(set_closure => ['closure_t'] => 'void');
$ffi->attach(call_closure => ['int'] => 'int');

my $closure1 = $ffi->closure(sub { $_[0] * 2 });
set_closure($closure1);
print  call_closure(2), "\n"; # prints "4"

my $closure2 = $ffi->closure(sub { $_[0] * 4 });
set_closure($closure2);
print call_closure(2), "\n"; # prints "8"
