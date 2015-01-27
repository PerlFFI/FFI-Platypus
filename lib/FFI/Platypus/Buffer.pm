package FFI::Platypus::Buffer;

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT = qw( scalar_to_buffer buffer_to_scalar );

# ABSTRACT: Convert scalars to C buffers
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus::Buffer;
 my($pointer, $size) = scalar_to_buffer $scalar;
 my $scalar2 = buffer_to_scallar $pointer, $size;

=head1 DESCRIPTION

A common pattern in C is to pass a "buffer" or region of memory into a 
function with a pair of arguments, an opaque pointer and the size of the 
memory region.  In Perl the equivalent structure is a scalar containing 
a string of bytes.  This module provides portable functions for 
converting a Perl string or scalar into a buffer and back.

These functions are implemented using L<pack and unpack|perlpacktut> and 
so they should be relatively fast.

Both functions are exported by default, but you can explicitly export 
one or neither if you so choose.

A better way to do this might be with custom types see 
L<FFI::Platypus::API> and L<FFI::Platypus::Type>.  These functions were 
taken from the now obsolete L<FFI::Util> module, as they may be useful 
in some cases.

=head1 FUNCTIONS

=cut

use constant _incantation => 
  $^O eq 'MSWin32' && $Config::Config{archname} =~ /MSWin32-x64/
  ? 'Q'
  : 'L!';

=head2 scalar_to_buffer

 my($pointer, $size) = scalar_to_buffer $scalar;

Convert a string scalar into a buffer.  Returned in order are a pointer 
to the start of the string scalar's memory region and the size of the 
region.

=cut

sub scalar_to_buffer ($)
{
  (unpack(_incantation, pack 'P', $_[0]), do { use bytes; length $_[0] });
}

=head2 buffer_to_scalar

 my $scalar = buffer_to_scalar $pointer, $size;

Convert the buffer region defined by the pointer and size into a string 
scalar.

=cut
      
sub buffer_to_scalar ($$)
{
  unpack 'P'.$_[1], pack _incantation, defined $_[0] ? $_[0] : 0;
}
  
1;

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

Main Platypus documentation.

=item L<FFI::Platypus::Declare>

Declarative interface to Platypus.

=back

=cut
