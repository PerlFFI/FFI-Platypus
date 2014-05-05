# FFI::Sweet = interface layer over FFI::Raw
# DSL inspired by ruby-ffi
use strict;
use warnings;
use v5.10;
use FFI::Sweet;

ffi_lib_in_process;
attach_function 'puts', [ _str ], _int;

puts("hi there");
