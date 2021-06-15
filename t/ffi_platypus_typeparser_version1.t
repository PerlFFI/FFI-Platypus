use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use FFI::Platypus::Internal;
use FFI::Platypus::TypeParser::Version1;
use Data::Dumper qw( Dumper );

my $tp = FFI::Platypus::TypeParser::Version1->new;
my $pointer_size = FFI::Platypus->new->sizeof('opaque');

subtest 'bad types' => sub {

  eval { $tp->parse("bogus") };
  like "$@", qr/^unknown type: bogus/;

  eval { $tp->parse("*(^^%*%I(*&&^") };
  like "$@", qr/^bad type name:/;

};

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

    is($tp->parse('string')->is_ro, 1);

    is(
      $tp->parse('string rw')->type_code,
      FFI_PL_TYPE_STRING,
    );

    is(
      $tp->parse('string ro')->type_code,
      FFI_PL_TYPE_STRING,
    );

    is($tp->parse('string ro')->is_ro, 1);
    is($tp->parse('string rw')->is_ro, 0);

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
      10 * $pointer_size,
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
      eval { $tp->parse($good) };
      like "$@", qr{^fixed string / classless record not allowed as value type};
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
      like "$@", qr/^Foo::Bar[34] has no ffi_record_size or _ffi_record_size method/;
    }

  };

  {
    package Foo::Bar5;
    use FFI::Platypus::Record;
    record_layout(qw(
      string(67) foo
    ));
  }

  subtest 'pass-by-value' => sub {

    my @bad = qw(
      record(Foo::Bar5)
    );

    foreach my $bad (@bad)
    {
      my $type = $tp->parse($bad);
      isa_ok $type, 'FFI::Platypus::Type';
    }

  };

  subtest 'alias' => sub {

    local $@ = '';
    my $check = eval { $tp->check_alias('foo_bar5_t') };
    is "$@", "";
    is $check, 1;

    eval { $tp->set_alias('foo_bar5_t', $tp->parse('record(Foo::Bar5)') ) };
    is "$@", "";

    is $tp->parse('foo_bar5_t')->type_code, FFI_PL_TYPE_RECORD_VALUE;

    is $tp->parse('foo_bar5_t*')->type_code, FFI_PL_TYPE_RECORD;
    is $tp->parse('foo_bar5_t*')->sizeof, 67;

  };


};

subtest 'check alias' => sub {

  is(
    $tp->check_alias('foo_bar_baz_1239_XOR'),
    1,
  );

  eval { $tp->check_alias('foo bar') };
  like "$@", qr/^spaces not allowed in alias/;

  eval { $tp->check_alias('!$#!$#') };
  like "$@", qr/^allowed characters for alias: \[A-Za-z0-9_\]/;

  eval { $tp->check_alias('void') };
  like "$@", qr/^alias "void" conflicts with existing type/;

  eval { $tp->check_alias('struct') };
  like "$@", qr/^reserved world "struct" cannot be used as an alias/;

  eval { $tp->check_alias('enum') };
  like "$@", qr/^reserved world "enum" cannot be used as an alias/;

  my $tp = FFI::Platypus::TypeParser::Version1->new;

  $tp->type_map({
    'foo_t' => 'sint16',
  });

  eval { $tp->check_alias('foo_t') };
  like "$@", qr/^alias "foo_t" conflicts with existing type/;

  $tp->set_alias('bar_t' => $tp->parse('sint32'));
  eval { $tp->check_alias('bar_t') };
  like "$@", qr/^alias "bar_t" conflicts with existing type/;

};

subtest 'use alias' => sub {

  my $tp = FFI::Platypus::TypeParser::Version1->new;

  $tp->set_alias('foo_t' => $tp->parse('sint8'));
  $tp->set_alias('bar_t' => $tp->parse('sint8*'));

  is(
    $tp->parse('foo_t')->type_code,
    FFI_PL_TYPE_SINT8,
  );

  is(
    $tp->parse('foo_t*')->type_code,
    FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_POINTER,
  );

  is(
    $tp->parse('foo_t[]')->type_code,
    FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_ARRAY,
  );

  is(
    $tp->parse('foo_t[]')->meta->{size},
    0,
  );

  is(
    $tp->parse('foo_t[99]')->type_code,
    FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_ARRAY,
  );

  is(
    $tp->parse('foo_t[99]')->meta->{size},
    99,
  );

  is(
    $tp->parse('bar_t')->type_code,
    FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_POINTER,
  );

  eval { $tp->parse('bar_t*') };
  like "$@", qr/^cannot make a pointer to bar_t/;

  eval { $tp->parse('bar_t[]') };
  like "$@", qr/^cannot make an array of bar_t/;

  eval { $tp->parse('bar_t[200]') };
  like "$@", qr/^cannot make an array of bar_t/;

};

subtest 'object' => sub {

  { package Roger; }

  is(
    $tp->parse('object(Roger)')->type_code,
    FFI_PL_SHAPE_OBJECT | FFI_PL_TYPE_OPAQUE,
  );

  is(
    $tp->parse('object(Roger,sint32)')->type_code,
    FFI_PL_SHAPE_OBJECT | FFI_PL_TYPE_SINT32,
  );

  local $@ = '';
  eval { $tp->parse('object(Roger,float)') };
  like "$@", qr/^cannot make an object of float/;

};

done_testing;
