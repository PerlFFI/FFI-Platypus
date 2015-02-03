use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus;

my $ffi = eval { FFI::Platypus->new };
diag $@ if $@;
isa_ok $ffi, 'FFI::Platypus';
