use strict;
use warnings;
use Test::More;
use FFI::Platypus::Internal;
use FFI::Platypus::Type;
use Data::Dumper qw( Dumper );

my $pointer_size = FFI::Platypus->new->sizeof('opaque');

subtest 'basic type' => sub {

  my $type = FFI::Platypus::TypeParser->create_type_basic(
    FFI_PL_TYPE_SINT8,
  );

  isa_ok $type, 'FFI::Platypus::Type';
  is $type->type_code, FFI_PL_TYPE_SINT8;
  is $type->sizeof, 1;
  note Dumper($type->meta);

};

subtest 'fixed string / record (pass by reference)' => sub {

  my $type = FFI::Platypus::TypeParser->create_type_record(
    22,
    undef,
    0,
  );

  isa_ok $type, 'FFI::Platypus::Type';
  is $type->type_code, FFI_PL_TYPE_RECORD;
  is $type->sizeof, 22;
  note Dumper($type->meta);
};

subtest 'record class (pass by reference)' => sub {

  {
    package Foo::Bar;
    use FFI::Platypus::Record;
    record_layout(qw(
      int foo
    ));
  }

  my $type = FFI::Platypus::TypeParser->create_type_record(
    Foo::Bar->_ffi_record_size,
    'Foo::Bar',
    0,
  );

  isa_ok $type, 'FFI::Platypus::Type';
  is $type->type_code, FFI_PL_TYPE_RECORD;
  is $type->meta->{ref}, 1;
  is $type->sizeof, 4;
  note Dumper($type->meta);

};

subtest 'string rw' => sub {

  my $type = FFI::Platypus::TypeParser->create_type_string(
    1,
  );

  isa_ok $type, 'FFI::Platypus::Type';
  is $type->type_code, FFI_PL_TYPE_STRING;
  is $type->meta->{access}, 'rw';
  is $type->sizeof, $pointer_size;
  note Dumper($type->meta);

};

subtest 'string ro' => sub {

  my $type = FFI::Platypus::TypeParser->create_type_string(
    0,
  );

  isa_ok $type, 'FFI::Platypus::Type';
  is $type->type_code, FFI_PL_TYPE_STRING;
  is $type->meta->{access}, 'ro';
  is $type->sizeof, $pointer_size;
  note Dumper($type->meta);

};

subtest 'fixed array' => sub {

  my $type = FFI::Platypus::TypeParser->create_type_array(
    FFI_PL_TYPE_SINT8,
    10,
  );

  isa_ok $type, 'FFI::Platypus::Type';
  is $type->type_code, FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_ARRAY;
  is $type->meta->{size}, 10;
  is $type->sizeof, 10;
  note Dumper($type->meta);

};

subtest 'var array' => sub {

  my $type = FFI::Platypus::TypeParser->create_type_array(
    FFI_PL_TYPE_SINT8,
    0,
  );

  isa_ok $type, 'FFI::Platypus::Type';
  is $type->type_code, FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_ARRAY;
  is $type->meta->{size}, 0;
  note Dumper($type->meta);

};

subtest 'pointer' => sub {

  my $type = FFI::Platypus::TypeParser->create_type_pointer(
    FFI_PL_TYPE_SINT8,
  );

  isa_ok $type, 'FFI::Platypus::Type';
  is $type->type_code, FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_POINTER;
  is $type->sizeof, $pointer_size;
  note Dumper($type->meta);

};

#_create_type_custom(self, type_code, perl_to_native, native_to_perl, perl_to_native_post, argument_count)

subtest 'custom type' => sub {

  my $type = FFI::Platypus::TypeParser->_create_type_custom(
    FFI_PL_TYPE_SINT8,
    sub {},
    sub {},
    sub {},
    1,
  );

  isa_ok $type, 'FFI::Platypus::Type';
  is $type->type_code, FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_CUSTOM_PERL;
  is $type->sizeof, 1;
  note Dumper($type->meta);

};

done_testing;
