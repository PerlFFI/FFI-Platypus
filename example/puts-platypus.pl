# FFI::Platypus = libffi bindings for Perl
# written in XS
use strict;
use warnings;
use v5.10;
use FFI::Platypus;

ffi_sub [], puts => [ ffi_type c => 'int', ffi_type ffi => 'string' ];
puts("hi there");
