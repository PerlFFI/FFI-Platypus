# TODO: do something interesting with that memory
use FFI::Platypus::Memory qw( malloc );

my $buffer = malloc 42;
