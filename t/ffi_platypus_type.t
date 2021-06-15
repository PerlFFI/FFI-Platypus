use Test2::V0 -no_srand => 1;
use FFI::Platypus::Internal;
use FFI::Platypus::Type;
use Data::Dumper qw( Dumper );

local $Data::Dumper::Sortkeys = 1;

my $pointer_size = FFI::Platypus->new->sizeof('opaque');

subtest 'basic type' => sub {

  my $type = FFI::Platypus::TypeParser->create_type_basic(
    FFI_PL_TYPE_SINT8,
  );

  isa_ok $type, 'FFI::Platypus::Type';
  is $type->type_code, FFI_PL_TYPE_SINT8;
  is $type->sizeof, 1;
  is $type->is_record, 0;
  is $type->is_record_value, 0;
  is $type->kindof, "scalar";
  is $type->countof, 1;
  is $type->unitof, undef;
  note Dumper($type->meta);

};

subtest 'fixed string / record (pass by reference)' => sub {

  my $type = FFI::Platypus::TypeParser->create_type_record(
    0,
    22,
  );

  isa_ok $type, 'FFI::Platypus::Type';
  is $type->type_code, FFI_PL_TYPE_RECORD;
  is $type->sizeof, 22;
  is $type->is_record, 1;
  is $type->is_record_value, 0;
  is $type->kindof, "record";
  is $type->countof, 1;
  is $type->unitof, undef;
  note Dumper($type->meta);

  my $custom = FFI::Platypus::TypeParser->_create_type_custom(
    $type,
    sub {},
    sub {},
    sub {},
    1,
  );

  isa_ok $custom, 'FFI::Platypus::Type';
  is $custom->type_code, FFI_PL_TYPE_RECORD | FFI_PL_SHAPE_CUSTOM_PERL;
  is $custom->sizeof, 22;
  is $custom->is_record, 1;
  is $custom->is_record_value, 0;
  is $custom->kindof, "record";
  is $custom->countof, 1;
  is $type->unitof, undef;
  note Dumper($custom->meta);

};

subtest 'record' => sub {

  {
    package Foo::Bar;
    use FFI::Platypus::Record;
    record_layout(qw(
      int foo
    ));
  }

  subtest 'record class value (pass by value)' => sub {

    my $type = FFI::Platypus::TypeParser->create_type_record(
      1,
      Foo::Bar->_ffi_record_size,
      'Foo::Bar',
      Foo::Bar->_ffi_meta->ffi_type,
    );

    isa_ok $type, 'FFI::Platypus::Type';
    is $type->type_code, FFI_PL_TYPE_RECORD_VALUE;
    is $type->meta->{ref}, 1;
    is $type->meta->{class}, 'Foo::Bar';
    is $type->sizeof, 4;
    is $type->is_record, 0;
    is $type->is_record_value, 1;
    is $type->kindof, "record-value";
    is $type->countof, 1;
  is $type->unitof, undef;
    note Dumper($type->meta);

    my $custom = FFI::Platypus::TypeParser->_create_type_custom(
      $type,
      sub {},
      sub {},
      sub {},
      1,
    );

    isa_ok $custom, 'FFI::Platypus::Type';
    is $custom->type_code, FFI_PL_TYPE_RECORD_VALUE | FFI_PL_SHAPE_CUSTOM_PERL;
    is $custom->sizeof, 4;
    is $custom->is_record, 0;
    is $custom->is_record_value, 1;
    is $custom->kindof, "record-value";
    is $custom->countof, 1;
    is $type->unitof, undef;
    note Dumper($custom->meta);


  };

  subtest 'record class (pass by reference)' => sub {

    my $type = FFI::Platypus::TypeParser->create_type_record(
      0,
      Foo::Bar->_ffi_record_size,
      'Foo::Bar',
    );

    isa_ok $type, 'FFI::Platypus::Type';
    is $type->type_code, FFI_PL_TYPE_RECORD;
    is $type->meta->{ref}, 1;
    is $type->sizeof, 4;
    is $type->is_record, 1;
    is $type->is_record_value, 0;
    is $type->kindof, "record";
    is $type->unitof, undef;
    is $type->countof, 1;
    note Dumper($type->meta);

    my $custom = FFI::Platypus::TypeParser->_create_type_custom(
      $type,
      sub {},
      sub {},
      sub {},
      1,
    );

    isa_ok $custom, 'FFI::Platypus::Type';
    is $custom->type_code, FFI_PL_TYPE_RECORD | FFI_PL_SHAPE_CUSTOM_PERL;
    is $custom->sizeof, 4;
    is $custom->is_record, 1;
    is $custom->is_record_value, 0;
    is $custom->kindof, "record";
    is $custom->countof, 1;
    is $type->unitof, undef;
    note Dumper($custom->meta);

  };
};

subtest 'string rw' => sub {

  my $type = FFI::Platypus::TypeParser->create_type_string(
    1,
  );

  isa_ok $type, 'FFI::Platypus::Type';
  is $type->type_code, FFI_PL_TYPE_STRING;
  is $type->meta->{access}, 'rw';
  is $type->sizeof, $pointer_size;
  is $type->is_record, 0;
  is $type->is_record_value, 0;
  is $type->kindof, "string";
  is $type->countof, 1;
  is $type->unitof, undef;
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
  is $type->is_record, 0;
  is $type->is_record_value,0;
  is $type->kindof, "string";
  is $type->countof, 1;
  is $type->unitof, undef;
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
  is $type->is_record, 0;
  is $type->is_record_value,0;
  is $type->kindof, "array";
  is $type->countof, 10;
  is $type->unitof, 'sint8';
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
  is $type->is_record, 0;
  is $type->is_record_value,0;
  is $type->kindof, "array";
  is $type->countof, 0;
  is $type->unitof, 'sint8';
  note Dumper($type->meta);

};

subtest 'pointer' => sub {

  my $type = FFI::Platypus::TypeParser->create_type_pointer(
    FFI_PL_TYPE_SINT8,
  );

  isa_ok $type, 'FFI::Platypus::Type';
  is $type->type_code, FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_POINTER;
  is $type->sizeof, $pointer_size;
  is $type->is_record, 0;
  is $type->is_record_value,0;
  is $type->kindof, "pointer";
  is $type->countof, 1;
  is $type->unitof, 'sint8';
  note Dumper($type->meta);

};

#_create_type_custom(self, type, perl_to_native, native_to_perl, perl_to_native_post, argument_count)

subtest 'custom type' => sub {

  my $basis = FFI::Platypus::TypeParser->create_type_basic(
    FFI_PL_TYPE_SINT8,
  );

  my $type = FFI::Platypus::TypeParser->_create_type_custom(
    $basis,
    sub {},
    sub {},
    sub {},
    1,
  );

  isa_ok $type, 'FFI::Platypus::Type';
  is $type->type_code, FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_CUSTOM_PERL;
  is $type->sizeof, 1;
  is $type->is_record, 0;
  is $type->is_record_value,0;
  is $type->kindof, "scalar";
  is $type->countof, 1;
  is $type->unitof, undef;
  note Dumper($type->meta);

};

done_testing;
