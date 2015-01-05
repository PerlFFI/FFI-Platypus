use strict;
use warnings;
use Test::More tests => 3;
use FFI::Platypus;

subtest 'simple type' => sub {
  plan tests => 2;

  my $ffi = FFI::Platypus->new;
  eval { $ffi->type('sint8') };
  is $@, '', 'ffi.type(sint8)';

  isa_ok $ffi->{types}->{sint8}, 'FFI::Platypus::Type';
};

subtest 'aliased type' => sub {
  plan tests => 4;

  my $ffi = FFI::Platypus->new;
  eval { $ffi->type('sint8', 'my_integer_8') };
  is $@, '', 'ffi.type(sint8 => my_integer_8)';

  isa_ok $ffi->{types}->{my_integer_8}, 'FFI::Platypus::Type';
  isa_ok $ffi->{types}->{sint8}, 'FFI::Platypus::Type';
  
  ok scalar(grep { $_ eq 'my_integer_8' } $ffi->types), 'ffi.types returns my_integer_8';
};

subtest 'ffi basic types' => sub {

  foreach my $name (qw( sint8 uint8 sint16 uint16 sint32 uint32 sint64 uint64 float double pointer string ))
  {
    subtest $name => sub {
    
      my $ffi = FFI::Platypus->new;
      eval { $ffi->type($name) };
      is $@, '', "ffi.type($name)";
      isa_ok $ffi->{types}->{$name}, 'FFI::Platypus::Type';
    
    };
  }

};
