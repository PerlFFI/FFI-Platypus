use strict;
use warnings;
use Test::More;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;

my $closure = $ffi->closure(sub { $_[0] + 1});
isa_ok $closure, 'FFI::Platypus::Closure';
is $closure->(1), 2, 'closure.(1) = 2';

my $c = sub { $_[0] + 2 };
$closure = $ffi->closure($c);
isa_ok $closure, 'FFI::Platypus::Closure';
is $closure->(1), 3, 'closure.(1) = 3';

$closure = $ffi->closure($c);
isa_ok $closure, 'FFI::Platypus::Closure';
is $closure->(1), 3, 'closure.(1) = 3';

eval { $closure->sticky };
is $@, '', 'able to call sticky';

done_testing;
