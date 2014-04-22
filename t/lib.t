use strict;
use warnings;
use Test::More tests => 2;
use FFI::Platypus qw( ffi_lib );

my $clib = ffi_lib undef;
isa_ok $clib, 'FFI::Platypus::Lib';
is $clib->path_name, undef, 'clib.path_name = undef';
