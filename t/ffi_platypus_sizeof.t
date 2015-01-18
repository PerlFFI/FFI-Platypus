use strict;
use warnings;
use Test::More tests => 2;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;

is $ffi->sizeof('uint32'), 4, 'sizeof uint32 = 4';
is $ffi->sizeof('uint32[2]'), 8, 'sizeof uint32[2] = 8';

