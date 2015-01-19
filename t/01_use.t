use strict;
use warnings;
use Test::More tests => 7;

use_ok 'FFI::Platypus';
use_ok 'FFI::Platypus::Declare';
use_ok 'FFI::Platypus::Memory';
use_ok 'FFI::Platypus::Buffer';
use_ok 'FFI::Platypus::API';
use_ok 'FFI::Platypus::Type::PointerSizeBuffer';
use_ok 'FFI::Platypus::Type::StringPointer';
