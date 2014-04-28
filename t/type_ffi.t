use strict;
use warnings;
use Test::More tests => 12;
use FFI::Platypus qw( ffi_type );

my $void = ffi_type 'ffi', 'void';
isa_ok $void, 'FFI::Platypus::Type';
is $void->size, 1, 'size = 1';
is $void->language, 'ffi', 'language = ffi';
is $void->name, 'void', 'name = void';
note "libffi_type = ", $void->_libffi_type, if $void->can('_libffi_type');

my $uint8 = ffi_type 'ffi', 'uint8';
isa_ok $uint8, 'FFI::Platypus::Type';
is $uint8->size, 1, 'size = 1';
is $uint8->language, 'ffi', 'language = ffi';
is $uint8->name, 'uint8', 'name = uint8';
note "libffi_type = ", $uint8->_libffi_type, if $uint8->can('_libffi_type');

my $uint16 = ffi_type 'ffi', 'uint16';
isa_ok $uint16, 'FFI::Platypus::Type';
is $uint16->size, 2, 'size = 2';
is $uint16->language, 'ffi', 'language = ffi';
is $uint16->name, 'uint16', 'name = uint16';
note "libffi_type = ", $uint16->_libffi_type, if $uint16->can('_libffi_type');
