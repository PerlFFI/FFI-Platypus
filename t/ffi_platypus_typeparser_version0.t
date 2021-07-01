use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use FFI::Platypus::TypeParser;
use FFI::Platypus::Internal;
use FFI::Platypus::TypeParser::Version0;

my $ffi = FFI::Platypus->new;
my $type;
my $pointer_size = $ffi->sizeof('opaque');

subtest basic => sub {

  is(
    $type = FFI::Platypus::TypeParser::Version0->new->parse('uint64')->meta,
    {
      element_size  => 8,
      element_type  => 'int',
      ffi_type      => 'uint64',
      sign          => 0,
      size          => 8,
      type          => 'scalar',
      type_code     => FFI_PL_TYPE_UINT64,
    },
    'basic basic',
  ) or diag explain $type;

  subtest 'longdouble' => sub {

    skip_all 'test requires support for long double'
      unless FFI::Platypus::TypeParser->have_type('longdouble');

    is(
      $type = FFI::Platypus::TypeParser::Version0->new->parse('longdouble')->meta,
      {
        element_size  => 16,
        element_type  => 'float',
        ffi_type      => 'longdouble',
        size          => 16,
        type          => 'scalar',
        type_code     => FFI_PL_TYPE_LONG_DOUBLE,
      },
      'longdouble',
    ) or diag explain $type;

  };

  subtest 'complex' => sub {

    skip_all 'test requires support for complex'
      unless FFI::Platypus::TypeParser->have_type('complex_float');

    skip_all 'test requires support for complex'
      unless FFI::Platypus::TypeParser->have_type('complex_double');

    is(
      $type = FFI::Platypus::TypeParser::Version0->new->parse('complex_float')->meta,
      {
        element_size  => 8,
        element_type  => 'float',
        ffi_type      => 'complex_float',
        size          => 8,
        type          => 'scalar',
        type_code     => FFI_PL_TYPE_COMPLEX_FLOAT,
      },
      'complex float',
    ) or diag explain $type;

    is(
      $type = FFI::Platypus::TypeParser::Version0->new->parse('complex_double')->meta,
      {
        element_size  => 16,
        element_type  => 'float',
        ffi_type      => 'complex_double',
        size          => 16,
        type          => 'scalar',
        type_code     => FFI_PL_TYPE_COMPLEX_DOUBLE,
      },
      'complex double',
    ) or diag explain $type;

  };

};

subtest record => sub {

  is(
    $type = FFI::Platypus::TypeParser::Version0->new->parse('string(42)')->meta,
    {
      ffi_type  => 'pointer',
      ref       => 0,
      size      => 42,
      type      => 'record',
      type_code => FFI_PL_TYPE_RECORD,
    },
    'fixed string',
  ) or diag explain $type;

  is(
    $type = FFI::Platypus::TypeParser::Version0->new->parse('record(42)')->meta,
    {
      ffi_type  => 'pointer',
      ref       => 0,
      size      => 42,
      type      => 'record',
      type_code => FFI_PL_TYPE_RECORD,
    },
    'unclassed record',
  ) or diag explain $type;

  { package
      Foo::Bar::Baz;
    use FFI::Platypus::Record;
    record_layout (qw(
      sint64 foo
    ));
  }

  is(
    $type =FFI::Platypus::TypeParser::Version0->new->parse('record(Foo::Bar::Baz)')->meta,
    {
      ffi_type  => 'pointer',
      ref       => 1,
      size      => 8,
      type      => 'record',
      type_code => FFI_PL_TYPE_RECORD,
      class     => 'Foo::Bar::Baz',
    },
    'classed record',
  ) or diag explain $type;

};

subtest string => sub {

  is(
    $type = FFI::Platypus::TypeParser::Version0->new->parse('string')->meta,
    {
      access => 'ro',
      element_size => $pointer_size,
      ffi_type => 'pointer',
      size => $pointer_size,
      type => 'string',
      type_code => FFI_PL_TYPE_STRING,
    },
    'default string',
  ) or diag explain $type;

  is(
    $type = FFI::Platypus::TypeParser::Version0->new->parse('string ro')->meta,
    {
      access => 'ro',
      element_size => $pointer_size,
      ffi_type => 'pointer',
      size => $pointer_size,
      type => 'string',
      type_code => FFI_PL_TYPE_STRING,
    },
    'explicit ro string',
  ) or diag explain $type;

  is(
    $type = FFI::Platypus::TypeParser::Version0->new->parse('string_ro')->meta,
    {
      access => 'ro',
      element_size => $pointer_size,
      ffi_type => 'pointer',
      size => $pointer_size,
      type => 'string',
      type_code => FFI_PL_TYPE_STRING,
    },
    'explicit ro string with underscore',
  ) or diag explain $type;

  is(
    $type = FFI::Platypus::TypeParser::Version0->new->parse('string rw')->meta,
    {
      access => 'rw',
      element_size => $pointer_size,
      ffi_type => 'pointer',
      size => $pointer_size,
      type => 'string',
      type_code => FFI_PL_TYPE_STRING,
    },
    'explicit rw string',
  ) or diag explain $type;

  is(
    $type = FFI::Platypus::TypeParser::Version0->new->parse('string_rw')->meta,
    {
      access => 'rw',
      element_size => $pointer_size,
      ffi_type => 'pointer',
      size => $pointer_size,
      type => 'string',
      type_code => FFI_PL_TYPE_STRING,
    },
    'explicit rw string with underscore',
  ) or diag explain $type;

};

subtest array => sub {

  is(
    $type = FFI::Platypus::TypeParser::Version0->new->parse('uint64 [4]')->meta,
    {
      element_count => 4,
      element_size  => 8,
      element_type  => 'int',
      ffi_type      => 'uint64',
      sign          => 0,
      size          => 32,
      type          => 'array',
      type_code     => FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_ARRAY,
    },
    'fixed array',
  ) or diag explain $type;

  is(
    $type = FFI::Platypus::TypeParser::Version0->new->parse('uint64 []')->meta,
    {
      element_count => 0,
      element_size  => 8,
      element_type  => 'int',
      ffi_type      => 'uint64',
      sign          => 0,
      size          => 0,
      type          => 'array',
      type_code     => FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_ARRAY,
    },
    'variable array',
  ) or diag explain $type;

  subtest 'longdouble' => sub {

    skip_all 'test requires support for long double'
      unless FFI::Platypus::TypeParser->have_type('longdouble');

    is(
      $type = FFI::Platypus::TypeParser::Version0->new->parse('longdouble []')->meta,
      {
        element_count => 0,
        element_size  => 16,
        element_type  => 'float',
        ffi_type      => 'longdouble',
        size          => 0,
        type          => 'array',
        type_code     => FFI_PL_TYPE_LONG_DOUBLE | FFI_PL_SHAPE_ARRAY,
      },
      'variable array',
    ) or diag explain $type;

  };

  subtest 'complex' => sub {

    skip_all 'test requires support for complex'
      unless FFI::Platypus::TypeParser->have_type('complex_float');

    skip_all 'test requires support for complex'
      unless FFI::Platypus::TypeParser->have_type('complex_double');

    is(
      $type = FFI::Platypus::TypeParser::Version0->new->parse('complex_float []')->meta,
      {
        element_count => 0,
        element_size  => 8,
        element_type  => 'float',
        ffi_type      => 'complex_float',
        size          => 0,
        type          => 'array',
        type_code     => FFI_PL_TYPE_COMPLEX_FLOAT | FFI_PL_SHAPE_ARRAY,
      },
      'variable array',
    ) or diag explain $type;

    is(
      $type = FFI::Platypus::TypeParser::Version0->new->parse('complex_double []')->meta,
      {
        element_count => 0,
        element_size  => 16,
        element_type  => 'float',
        ffi_type      => 'complex_double',
        size          => 0,
        type          => 'array',
        type_code     => FFI_PL_TYPE_COMPLEX_DOUBLE | FFI_PL_SHAPE_ARRAY,
      },
      'variable array',
    ) or diag explain $type;

  };

};

subtest pointer => sub {

  is(
    $type = FFI::Platypus::TypeParser::Version0->new->parse('uint64 *')->meta,
    {
      element_size  => 8,
      element_type  => 'int',
      ffi_type      => 'uint64',
      sign          => 0,
      size          => $pointer_size,
      type          => 'pointer',
      type_code     => FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_POINTER,
    },
    'pointer',
  ) or diag explain $type;

  subtest 'longdouble' => sub {

    skip_all 'test requires support for long double'
      unless FFI::Platypus::TypeParser->have_type('longdouble');

    is(
      $type = FFI::Platypus::TypeParser::Version0->new->parse('longdouble *')->meta,
      {
        element_size  => 16,
        element_type  => 'float',
        ffi_type      => 'longdouble',
        size          => $pointer_size,
        type          => 'pointer',
        type_code     => FFI_PL_TYPE_LONG_DOUBLE | FFI_PL_SHAPE_POINTER,
      },
      'longdouble pointer',
    ) or diag explain $type;

  };

  subtest 'complex' => sub {

    skip_all 'test requires support for complex'
      unless FFI::Platypus::TypeParser->have_type('complex_float');

    skip_all 'test requires support for complex'
      unless FFI::Platypus::TypeParser->have_type('complex_double');

    is(
      $type = FFI::Platypus::TypeParser::Version0->new->parse('complex_float *')->meta,
      {
        element_size  => 8,
        element_type  => 'float',
        ffi_type      => 'complex_float',
        size          => $pointer_size,
        type          => 'pointer',
        type_code     => FFI_PL_TYPE_COMPLEX_FLOAT | FFI_PL_SHAPE_POINTER,
      },
      'complex float pointer',
    ) or diag explain $type;

    is(
      $type = FFI::Platypus::TypeParser::Version0->new->parse('complex_double *')->meta,
      {
        element_size  => 16,
        element_type  => 'float',
        ffi_type      => 'complex_double',
        size          => $pointer_size,
        type          => 'pointer',
        type_code     => FFI_PL_TYPE_COMPLEX_DOUBLE | FFI_PL_SHAPE_POINTER,
      },
      'complex double pointer',
    ) or diag explain $type;

  };

};

done_testing;
