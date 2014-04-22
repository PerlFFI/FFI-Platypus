use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus;

FFI::Platypus::ffi_attach_function("main::foo");
FFI::Platypus::ffi_attach_function("main::bar");
main::foo();
main::bar();
main::foo();

pass 'okay then';
