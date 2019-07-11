use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::Platypus::Internal;
use FFI::Platypus::TypeParser::Version1;

my $tp = FFI::Platypus::TypeParser::Version1->new;

subtest 'basic types' => sub {

  subtest 'void' => sub {

    my $void = $tp->parse('void');
    isa_ok $void, 'FFI::Platypus::Type';
    is $void->type_code, FFI_PL_TYPE_VOID;

    eval { $tp->parse('void*') };
    like "$@", qr/^void pointer not allowed/;

    eval { $tp->parse('void[]') };
    like "$@", qr/^void array not allowed/;

  };

  subtest 'non-void' => sub {

    is(
      $tp->parse('sint8')->type_code,
      FFI_PL_TYPE_SINT8,
    );

    is(
      $tp->parse('sint8*')->type_code,
      FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_POINTER,
    );

    is(
      $tp->parse('sint8[]')->type_code,
      FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_ARRAY,
    );

    is(
      $tp->parse('sint8[]')->meta->{size},
      0,
    );

    is(
      $tp->parse('sint8[10]')->type_code,
      FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_ARRAY,
    );

    is(
      $tp->parse('sint8[10]')->meta->{size},
      10,
    );

  };

  subtest 'string' => sub {

    is(
      $tp->parse('string')->type_code,
      FFI_PL_TYPE_STRING,
    );

    is(
      $tp->parse('string*')->type_code,
      FFI_PL_TYPE_STRING | FFI_PL_SHAPE_POINTER,
    );

    is(
      $tp->parse('string[]')->type_code,
      FFI_PL_TYPE_STRING | FFI_PL_SHAPE_ARRAY,
    );

    is(
      $tp->parse('string[]')->meta->{size},
      0,
    );

    is(
      $tp->parse('string[10]')->type_code,
      FFI_PL_TYPE_STRING | FFI_PL_SHAPE_ARRAY,
    );

    is(
      $tp->parse('string[10]')->meta->{size},
      80,
    );

  };

  subtest 'bogus' => sub {

    eval { $tp->parse('sint8[0]') };
    like "$@", qr/^array size must be larger than 0/;
  
  };

};

subtest 'type map' => sub {

  my $tp = FFI::Platypus::TypeParser::Version1->new;

  $tp->type_map({
    'char'          => 'sint8',
    'int'           => 'sint32',
    'unsigned int'  => 'uint32',
    'intptr'        => 'sint32*',
  });


  is(
    $tp->parse('char')->type_code,
    FFI_PL_TYPE_SINT8,
  );

  is(
    $tp->parse('int')->type_code,
    FFI_PL_TYPE_SINT32,
  );

  is(
    $tp->parse('unsigned int')->type_code,
    FFI_PL_TYPE_UINT32,
  );

  is(
    $tp->parse('char*')->type_code,
    FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_POINTER,
  );

  is(
    $tp->parse('int*')->type_code,
    FFI_PL_TYPE_SINT32 | FFI_PL_SHAPE_POINTER,
  );

  is(
    $tp->parse('unsigned int *')->type_code,
    FFI_PL_TYPE_UINT32 | FFI_PL_SHAPE_POINTER,
  );

  is(
    $tp->parse('char[]')->type_code,
    FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_ARRAY,
  );

  is(
    $tp->parse('int[]')->type_code,
    FFI_PL_TYPE_SINT32 | FFI_PL_SHAPE_ARRAY,
  );

  is(
    $tp->parse('unsigned int []')->type_code,
    FFI_PL_TYPE_UINT32 | FFI_PL_SHAPE_ARRAY,
  );

  is(
    $tp->parse('char[]')->meta->{size},
    0,
  );

  is(
    $tp->parse('int[]')->meta->{size},
    0,
  );

  is(
    $tp->parse('unsigned int []')->meta->{size},
    0,
  );

  is(
    $tp->parse('char[22]')->type_code,
    FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_ARRAY,
  );

  is(
    $tp->parse('int[22]')->type_code,
    FFI_PL_TYPE_SINT32 | FFI_PL_SHAPE_ARRAY,
  );

  is(
    $tp->parse('unsigned int [22]')->type_code,
    FFI_PL_TYPE_UINT32 | FFI_PL_SHAPE_ARRAY,
  );

  is(
    $tp->parse('char[22]')->meta->{size},
    22,
  );

  is(
    $tp->parse('int[22]')->meta->{size},
    88,
  );

  is(
    $tp->parse('unsigned int [22]')->meta->{size},
    88,
  );

  eval { $tp->parse('int[0]') };
  like "$@", qr/^array size must be larger than 0/;

  is(
    $tp->parse('intptr')->type_code,
    FFI_PL_TYPE_SINT32 | FFI_PL_SHAPE_POINTER,
  );

  eval { $tp->parse('intptr*') };
  like "$@", qr/^bad type name: sint32\* \*/;

  eval { $tp->parse('intptr[]') };
  like "$@", qr/^bad type name: sint32\* \[\]/;

  eval { $tp->parse('intptr[10]') };
  like "$@", qr/^bad type name: sint32\* \[10\]/;

};

subtest 'fixed record / fixed string' => sub {

  subtest 'zero bad' => sub {

    my @bad = (
      'string(0)',
      'record(0)',
      '  string(0)',
      'string(0)  ',
      'string  (0)',
      '  string   (0) ',
    );

    foreach my $bad (@bad)
    {
      eval { $tp->parse( $bad ) };
      like "$@", qr{^fixed record / fixed string size must be larger than 0};
    }

  };

  subtest 'ten good' => sub {

    my @good = (
      'string(10)*',
      'record(10)*',
      '  string(10)*',
      'string(10)  *',
      'string  (10)*',
      '  string   (10)* ',
    );

    foreach my $good (@good)
    {
      my $type = $tp->parse($good);
      isa_ok $type, 'FFI::Platypus::Type';
      is $type->type_code, FFI_PL_TYPE_RECORD;
      is $type->meta->{size}, 10;
      is $type->meta->{ref}, 0;
    }

  };

  subtest 'ten pass-by-value' => sub {

    my @good = (
      'string(10)',
      'record(10)',
      '  string(10)',
      'string(10)  ',
      'string  (10)',
      '  string   (10) ',
    );

    foreach my $good (@good)
    {
      # TODO
      eval { $tp->parse($good) };
      like "$@", qr{todo pass-by-value};
    }

  };

};

subtest 'record class' => sub {

  {
    package Foo::Bar1;
    sub ffi_record_size { 220 };
  }

  {
    package Foo::Bar2;
    sub _ffi_record_size { 220 };
  }

  {
    package Foo::Bar3;
  }

  subtest 'good with size' => sub {

    my @good = qw(
      record(Foo::Bar1)*
      record(Foo::Bar2)*
    );

    foreach my $good (@good)
    {
      my $type = $tp->parse($good);
      isa_ok $type, 'FFI::Platypus::Type';
    }

  };

  subtest 'bad without size' => sub {

    my @bad = qw(
      record(Foo::Bar3)*
      record(Foo::Bar4)*
    );

    foreach my $bad (@bad)
    {
      eval { $tp->parse($bad) };
      like "$@", qr/^Foo::Bar[34] has no ffi_record_size or _ffi_record_size_ method/;
    }

  };

  subtest 'pass-by-value' => sub {

    my @bad = qw(
      record(Foo::Bar1)
      record(Foo::Bar2)
    );

    foreach my $bad (@bad)
    {
      eval { $tp->parse($bad) };
      like "$@", qr/^todo pass-by-value record/;
    }

  };

};

done_testing;
