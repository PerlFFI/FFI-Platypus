use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::Platypus::Internal;
use FFI::Platypus::TypeParser::Version0;

my $ffi = FFI::Platypus->new;

subtest record => sub {

  is_deeply(
    FFI::Platypus::TypeParser::Version0->parse('string(42)', $ffi)->meta,
    {
      ffi_type  => 'pointer',
      ref       => 0,
      size      => 42,
      type      => 'record',
      type_code => FFI_PL_TYPE_RECORD,
    },
    'fixed string',
  );

  is_deeply(
    FFI::Platypus::TypeParser::Version0->parse('record(42)', $ffi)->meta,
    {
      ffi_type  => 'pointer',
      ref       => 0,
      size      => 42,
      type      => 'record',
      type_code => FFI_PL_TYPE_RECORD,
    },
    'unclassed record',
  );

  { package
      Foo::Bar::Baz;
    use FFI::Platypus::Record;
    record_layout (qw(
      sint64 foo
    ));
  }

  is_deeply(
    FFI::Platypus::TypeParser::Version0->parse('record(Foo::Bar::Baz)', $ffi)->meta,
    {
      ffi_type  => 'pointer',
      ref       => 1,
      size      => 8,
      type      => 'record',
      type_code => FFI_PL_TYPE_RECORD,
    },
    'classed record',
  );

};

done_testing;
