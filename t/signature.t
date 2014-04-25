use strict;
use warnings;
use Test::More tests => 2;
use FFI::Platypus qw( ffi_type ffi_signature );

subtest 'void return type' => sub {
  plan tests => 8;

  my $sig = ffi_signature
    ffi_type none => 'void',
    ffi_type none => 'sint32',
  ;

  isa_ok $sig, 'FFI::Platypus::Signature';
  isa_ok $sig->return_type, 'FFI::Platypus::Type';
  is $sig->return_type->language, 'none', 'return type language = none';
  is $sig->return_type->name,     'void', 'return type name = void';  
  
  is $sig->argument_count, 1, 'argument count = 1';
  
  isa_ok $sig->argument_type(0), 'FFI::Platypus::Type';
  is $sig->argument_type(0)->language, 'none', 'argument 1 type language = none';
  is $sig->argument_type(0)->name, 'sint32', 'argument 1 type name = sint32';
};

subtest 'void argument type' => sub {

  plan tests => 1;

  eval { ffi_signature ffi_type none => 'void', ffi_type none => 'void' };
  
  like $@, qr{void is an illegal argument type}, "void argument is illegal: $@";

};
