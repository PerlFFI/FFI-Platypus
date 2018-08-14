use strict;
use warnings;
use Test::More;

use_ok 'FFI::Platypus';
use_ok 'FFI::Platypus::DL';
use_ok 'FFI::Platypus::Declare';
use_ok 'FFI::Platypus::Memory';
use_ok 'FFI::Platypus::Buffer';
use_ok 'FFI::Platypus::API';
use_ok 'FFI::Platypus::Type::PointerSizeBuffer';
use_ok 'FFI::Platypus::Type::StringPointer';
use_ok 'FFI::Platypus::Lang::ASM';
use_ok 'FFI::Platypus::Lang::C';
use_ok 'FFI::Platypus::Lang::Win32';
use_ok 'FFI::Platypus::Record';
use_ok 'FFI::Platypus::Record::TieArray';
use_ok 'FFI::Platypus::ShareConfig';

done_testing;
