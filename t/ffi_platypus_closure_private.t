use strict;
use warnings;
use Test::More tests => 4;
use FFI::Platypus;

my $closure = FFI::Platypus::Closure->new(sub { $_[0] + 1});
isa_ok $closure, 'FFI::Platypus::Closure';
is $closure->(1), 2, 'closure.(1) = 2';
is $closure->add_data( 42 => "hi there" ), "hi there", 'closure.add_data( 42, "hi there")';
is $closure->get_data( 42 ), "hi there", 'closure.get_data( 42 ) = "hi there"';
