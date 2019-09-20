package FFI::Platypus::Type::PointerSizeBuffer;

use strict;
use warnings;
use FFI::Platypus;
use FFI::Platypus::API qw(
  arguments_set_pointer
  arguments_set_uint32
  arguments_set_uint64
);
use FFI::Platypus::Buffer qw( scalar_to_buffer );
use FFI::Platypus::Buffer qw( buffer_to_scalar );

# ABSTRACT: Convert string scalar to a buffer as a pointer / size_t combination
# VERSION

=head1 SYNOPSIS

In your C code:

 void
 function_with_buffer(void *pointer, size_t size)
 {
   ...
 }

In your Platypus::FFI code:

 use FFI::Platypus;
 
 my $ffi = FFI::Platypus->new( api => 1 );
 $ffi->load_custom_type('::PointerSizeBuffer' => 'buffer');
 
 $ffi->attach(function_with_buffer => ['buffer'] => 'void');
 my $string = "content of buffer";
 function_with_buffer($string);

=head1 DESCRIPTION

A common pattern in C code is to pass in a region of memory as a buffer,
consisting of a pointer and a size of the memory region.  In Perl,
string scalars also point to a contiguous series of bytes that has a
size, so when interfacing with C libraries it is handy to be able to
pass in a string scalar as a pointer / size buffer pair.

=cut

my @stack;

*arguments_set_size_t
  = FFI::Platypus->new( api => 1, experimental => 1 )->sizeof('size_t') == 4
  ? \&arguments_set_uint32
  : \&arguments_set_uint64;

sub perl_to_native
{
  my($pointer, $size) = scalar_to_buffer($_[0]);
  push @stack, [ $pointer, $size ];
  arguments_set_pointer $_[1], $pointer;
  arguments_set_size_t($_[1]+1, $size);
}

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

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

Main Platypus documentation.

=item L<FFI::Platypus::Type>

Platypus types documentation.

=back

=cut
