use strict;
use warnings;
use Test::More tests => 2;
use FFI::Platypus::Declare;

is sizeof 'uint32', 4, 'sizeof uint32 = 4';
is sizeof 'uint32[2]', 8, 'sizeof uint32[2] = 8';

