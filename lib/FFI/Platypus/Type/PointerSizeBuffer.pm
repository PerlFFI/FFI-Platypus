package FFI::Platypus::Type::PointerSizeBuffer;

use strict;
use warnings;
use FFI::Platypus;
use FFI::Platypus::API qw( argv );
use FFI::Platypus::Buffer qw( scalar_to_buffer );
use FFI::Platypus::Buffer qw( buffer_to_scalar );

# ABSTRACT: Convert string scalar to a buffer as a pointer / size_t combination
# VERSION

my @stack;

sub perl_to_native32
{
  my($pointer, $size) = scalar_to_buffer($_[0]);
  push @stack, [ $pointer, $size ];
  argv->set_pointer($_[1], $pointer);
  argv->set_uint32($_[1]+1, $size);
}

sub perl_to_native64
{
  my($pointer, $size) = scalar_to_buffer($_[0]);
  push @stack, [ $pointer, $size ];
  argv->set_pointer($_[1], $pointer);
  argv->set_uint64($_[1]+1, $size);
}

*perl_to_native = FFI::Platypus->new->sizeof('size_t') == 4 ? \&perl_to_native32 : \&perl_to_native64;

sub perl_to_native_post
{
  my($pointer, $size) = @{ pop @stack };
  $_[0] = buffer_to_scalar($pointer, $size);
}

sub ffi_custom_type_api_1
{
  {
    native_type         => 'opaque',
    perl_to_native      => \&perl_to_native,
    perl_to_native_post => \&perl_to_native_post,
    argument_count      => 2,
  }
}

1;
