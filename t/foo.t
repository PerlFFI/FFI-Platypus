use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus;

FFI::Platypus::attach_function("main::roger");
main::roger();

pass 'okay then';
