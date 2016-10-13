package FFI::Platypus::Memory;

use strict;
use warnings;
use FFI::Platypus;
use base qw( Exporter );

# ABSTRACT: Memory functions for FFI
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus::Memory;
 
 # allocate 64 bytes of memory using the
 # libc malloc function.
 my $pointer = malloc 64;
 
 # use that memory wisely
 ...

 # free the memory when you are done.
 free $pointer;

=head1 DESCRIPTION

This module provides an interface to common memory functions provided by 
the standard C library.  They may be useful when constructing interfaces 
to C libraries with FFI.

=head1 FUNCTIONS

=head2 calloc

 my $pointer = calloc $count, $size;

The C<calloc> function contiguously allocates enough space for I<$count> 
objects that are I<$size> bytes of memory each.

=head2 free

 free $pointer;

The C<free> function frees the memory allocated by C<malloc>, C<calloc>, 
C<realloc> or C<strdup>.  It is important to only free memory that you 
yourself have allocated.  A good way to crash your program is to try and 
free a pointer that some C library has returned to you.

=head2 malloc

 my $pointer = malloc $size;

The C<malloc> function allocates I<$size> bytes of memory.

=head2 memcpy

 memcpy $dst_pointer, $src_pointer, $size;

The C<memcpy> function copies I<$size> bytes from I<$src_pointer> to 
I<$dst_pointer>.  It also returns I<$dst_pointer>.

=head2 memset

 memset $buffer, $value, $length;

The C<memset> function writes I<$length> bytes of I<$value> to the address
specified by I<$buffer>.

=head2 realloc

 my $new_pointer = realloc $old_pointer, $size;

The C<realloc> function reallocates enough memory to fit I<$size> bytes. 
It copies the existing data and frees I<$old_pointer>.

If you pass C<undef> in as I<$old_pointer>, then it behaves exactly like 
C<malloc>:

 my $pointer = realloc undef, 64; # same as malloc 64

=head2 strdup

 my $pointer = strdup $string;

The C<strdup> function allocates enough memory to contain I<$string> and 
then copies it to that newly allocated memory.  This version of 
C<strdup> returns an opaque pointer type, not a string type.  This may 
seem a little strange, but returning a string type would not be very 
useful in Perl.

Platforms that do not support C<strdup> will be provided with an 
equivalent using C<malloc> and C<memcpy> written in Perl.  This version 
is slower.

=cut

our @EXPORT = qw( malloc free calloc realloc memcpy memset strdup );

my $ffi = FFI::Platypus->new;
$ffi->lib(undef);
$ffi->type($_) foreach qw( opaque size_t void int );

$ffi->attach(malloc  => ['size_t']                     => 'opaque' => '$');
$ffi->attach(free    => ['opaque']                     => 'void'   => '$');
$ffi->attach(calloc  => ['size_t', 'size_t']           => 'opaque' => '$$');
$ffi->attach(realloc => ['opaque', 'size_t']           => 'opaque' => '$$');
$ffi->attach(memcpy  => ['opaque', 'opaque', 'size_t'] => 'opaque' => '$$$');
$ffi->attach(memset  => ['opaque', 'int', 'size_t']    => 'opaque' => '$$$');

# This global may be removed at any time, do not use it
# externally.  It is used by t/ffi_platypus_memory__strdup.t
# for a diagnostic.
our $_strdup_impl = 'not-loaded';

eval {
  die "do not use c impl" if ($ENV{FFI_PLATYPUS_MEMORY_STRDUP_IMPL}//'c') eq 'perl';
  $ffi->attach(strdup  => ['string'] => 'opaque' => '$');
};
if($@)
{
  $_strdup_impl = 'perl';
  *strdup = sub ($) {
    my($string) = @_;
    my $ptr = malloc(length($string)+1);
    memcpy($ptr, $ffi->cast('string' => 'opaque', $string), length($string)+1);
  };
}
else
{
  $_strdup_impl = 'c';
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

Main Platypus documentation.

=back

=cut
