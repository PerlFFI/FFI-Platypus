use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus;

my $type = FFI::Platypus::type->new;
isa_ok $type, 'FFI::Platypus::type';
