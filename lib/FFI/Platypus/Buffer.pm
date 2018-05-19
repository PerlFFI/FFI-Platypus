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
 my $scalar2 = buffer_to_scalar $pointer, $size;

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

B<Caution>: This module provides great power in the way that you
interact with C code, but with that power comes great responsability.
Since you are dealing with blocks of memory you need to take care to
understand the underlying ownership model of these pointers.

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

You should NEVER try to free C<$pointer>.

When you pass this pointer and size into a C function, it has direct
access to the data stored in your scalar, so it is important that you
not resize or free the scalar while it is in use by the C code.  Typically
if you are passing a buffer into a C function which reads or writes to
the buffer, but does not keep the pointer for later use you are okay.
If the buffer is in use long term by the C code, then you should consider
copying the buffer instead.  For example:

 use FFI::Platypus::Buffer qw( scalar_to_buffer );
 use FFI::Platypus::Memory qw( malloc memcpy free )
 
 my($ptr, $size) = scalar_to_buffer $string;
 c_function_thaat_does_not_keep_ptr( $ptr, $size); # okay
 
 my($ptr, $size) = scalar_to_buffer $string;
 my $ptr_copy = malloc($size);
 memcpy($ptr_copy, $ptr, $size);
 c_function_that_DOES_keep_ptr( $ptr_copy, $size); # also okay
 
 ...
 
 # later when you know that the c code is no longer using the pointer
 # Since you allocated the copy, you are responsible for free'ing it.
 free($ptr_copy);

=cut

sub scalar_to_buffer ($)
{
  (unpack(_incantation, pack 'P', $_[0]), do { use bytes; length $_[0] });
}

=head2 buffer_to_scalar

 my $scalar = buffer_to_scalar $pointer, $size;

Convert the buffer region defined by the pointer and size into a string 
scalar.

Because of the way memory management works in Perl, the buffer is copied
from the buffer into the scalar.  If this pointer was returned from C
land, then you should only free it if you allocated it.

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

=back

=cut
