use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::Platypus::Internal;
use FFI::Platypus::TypeParser::Version0;

my $ffi = FFI::Platypus->new;
my $type;
my $pointer_size = $ffi->sizeof('opaque');

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

done_testing;
