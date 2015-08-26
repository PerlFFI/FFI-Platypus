use strict;
use warnings;
use FFI::Platypus;
use Test::More tests => 2;

my $ffi = FFI::Platypus->new;

eval { $ffi->type('(int,int)->void') };
is $@, '', 'good without space';

eval { $ffi->type('(int, int) -> void') };
is $@, '', 'good with space';
