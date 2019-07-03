use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::Platypus::Internal;
use FFI::Platypus::TypeParser::Version0;

my $ffi = FFI::Platypus->new;
my $type;
my $pointer_size = $ffi->sizeof('opaque');

subtest basic => sub {

  is_deeply(
    $type = FFI::Platypus::TypeParser::Version0->parse('uint64', $ffi)->meta,
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

    plan skip_all => 'test requires support for long double'
      unless FFI::Platypus::_have_type('longdouble');

    FFI::Platypus::_have_math_longdouble(-1),

    is_deeply(
      $type = FFI::Platypus::TypeParser::Version0->parse('longdouble', $ffi)->meta,
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

    isnt(
      FFI::Platypus::_have_math_longdouble(),
      -1,
    );

  };

  subtest 'complex' => sub {

    plan skip_all => 'test requires support for complex'
      unless FFI::Platypus::_have_type('complex_float');

    plan skip_all => 'test requires support for complex'
      unless FFI::Platypus::_have_type('complex_double');

    FFI::Platypus::_have_math_complex(-1),

    is_deeply(
      $type = FFI::Platypus::TypeParser::Version0->parse('complex_float', $ffi)->meta,
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

    isnt(
      FFI::Platypus::_have_math_complex(),
      -1,
    );

    FFI::Platypus::_have_math_complex(-1),

    is_deeply(
      $type = FFI::Platypus::TypeParser::Version0->parse('complex_double', $ffi)->meta,
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

    isnt(
      FFI::Platypus::_have_math_complex(),
      -1,
    );

  };

};

subtest record => sub {

  is_deeply(
    $type = FFI::Platypus::TypeParser::Version0->parse('string(42)', $ffi)->meta,
    {
      ffi_type  => 'pointer',
      ref       => 0,
      size      => 42,
      type      => 'record',
      type_code => FFI_PL_TYPE_RECORD,
    },
    'fixed string',
  ) or diag explain $type;

  is_deeply(
    $type = FFI::Platypus::TypeParser::Version0->parse('record(42)', $ffi)->meta,
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

  is_deeply(
    $type =FFI::Platypus::TypeParser::Version0->parse('record(Foo::Bar::Baz)', $ffi)->meta,
    {
      ffi_type  => 'pointer',
      ref       => 1,
      size      => 8,
      type      => 'record',
      type_code => FFI_PL_TYPE_RECORD,
    },
    'classed record',
  ) or diag explain $type;

};

subtest string => sub {

  is_deeply(
    $type = FFI::Platypus::TypeParser::Version0->parse('string', $ffi)->meta,
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

  is_deeply(
    $type = FFI::Platypus::TypeParser::Version0->parse('string ro', $ffi)->meta,
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

  is_deeply(
    $type = FFI::Platypus::TypeParser::Version0->parse('string_ro', $ffi)->meta,
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

  is_deeply(
    $type = FFI::Platypus::TypeParser::Version0->parse('string rw', $ffi)->meta,
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

  is_deeply(
    $type = FFI::Platypus::TypeParser::Version0->parse('string_rw', $ffi)->meta,
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

  is_deeply(
    $type = FFI::Platypus::TypeParser::Version0->parse('uint64 [4]', $ffi)->meta,
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

  is_deeply(
    $type = FFI::Platypus::TypeParser::Version0->parse('uint64 []', $ffi)->meta,
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

    plan skip_all => 'test requires support for long double'
      unless FFI::Platypus::_have_type('longdouble');

    FFI::Platypus::_have_math_longdouble(-1),

    is_deeply(
      $type = FFI::Platypus::TypeParser::Version0->parse('longdouble []', $ffi)->meta,
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

    isnt(
      FFI::Platypus::_have_math_longdouble(),
      -1,
    );

  };

  subtest 'complex' => sub {

    plan skip_all => 'test requires support for complex'
      unless FFI::Platypus::_have_type('complex_float');

    plan skip_all => 'test requires support for complex'
      unless FFI::Platypus::_have_type('complex_double');

    FFI::Platypus::_have_math_complex(-1),

    is_deeply(
      $type = FFI::Platypus::TypeParser::Version0->parse('complex_float []', $ffi)->meta,
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

    isnt(
      FFI::Platypus::_have_math_complex(),
      -1,
    );

    FFI::Platypus::_have_math_complex(-1),

    is_deeply(
      $type = FFI::Platypus::TypeParser::Version0->parse('complex_double []', $ffi)->meta,
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

    isnt(
      FFI::Platypus::_have_math_complex(),
      -1,
    );

  };

};

subtest pointer => sub {

  is_deeply(
    $type = FFI::Platypus::TypeParser::Version0->parse('uint64 *', $ffi)->meta,
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

    plan skip_all => 'test requires support for long double'
      unless FFI::Platypus::_have_type('longdouble');

    FFI::Platypus::_have_math_longdouble(-1),

    is_deeply(
      $type = FFI::Platypus::TypeParser::Version0->parse('longdouble *', $ffi)->meta,
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

    isnt(
      FFI::Platypus::_have_math_longdouble(),
      -1,
    );

  };

  subtest 'complex' => sub {

    plan skip_all => 'test requires support for complex'
      unless FFI::Platypus::_have_type('complex_float');

    plan skip_all => 'test requires support for complex'
      unless FFI::Platypus::_have_type('complex_double');

    FFI::Platypus::_have_math_complex(-1),

    is_deeply(
      $type = FFI::Platypus::TypeParser::Version0->parse('complex_float *', $ffi)->meta,
      {
        element_size  => 8,
        element_type  => 'float',
        ffi_type      => 'complex_float',
        size          => 8,
        type          => 'pointer',
        type_code     => FFI_PL_TYPE_COMPLEX_FLOAT | FFI_PL_SHAPE_POINTER,
      },
      'complex float pointer',
    ) or diag explain $type;

    isnt(
      FFI::Platypus::_have_math_complex(),
      -1,
    );

    FFI::Platypus::_have_math_complex(-1),

    is_deeply(
      $type = FFI::Platypus::TypeParser::Version0->parse('complex_double *', $ffi)->meta,
      {
        element_size  => 16,
        element_type  => 'float',
        ffi_type      => 'complex_double',
        size          => 8,
        type          => 'pointer',
        type_code     => FFI_PL_TYPE_COMPLEX_DOUBLE | FFI_PL_SHAPE_POINTER,
      },
      'complex double pointer',
    ) or diag explain $type;

    isnt(
      FFI::Platypus::_have_math_complex(),
      -1,
    );

  };

};

done_testing;
