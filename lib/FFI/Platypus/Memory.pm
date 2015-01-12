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
the standard C library.  They may be useful when constructing interfaces to
C libraries with FFI.

=head1 FUNCTIONS

=head2 calloc

 my $pointer = calloc $count, $size;

The C<calloc> function contiguously allocates enough space for I<$count>
objects that are I<$size> bytes of memory each.

=head2 cast

 my $converted_value = cast $original_type, $converted_type, $original_value;

The C<cast> function converts an existing I<$original_value> of type 
I<$original_type> into one of type I<$converted_type>.  Not all types are 
supported, so care must be taken.  For example, to get the address of a 
string, you can do this:

 my $address = cast 'string' => 'opaque', $string_value;

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

=head2 sizeof

 my $size = sizeof $type;

Returns the total size of the given type.  For example to get the size of
an integer:

 my $intsize = sizeof 'int'; # usually 4 or 8 depending on platform

You can also get the size of arrays

 my $intarraysize = sizeof 'int[64]'; # same as (sizeof 'int')*64

Keep in mind that "pointer" types will always be the pointer / word size 
for the platform that you are using.  This includes strings, opaque and 
pointers to other types.

This function is not very fast, so you might want to save this value as a 
constant, particularly if you need the size in a loop with many 
iterations.

=head2 strdup

 my $pointer = strdup $string;

The C<strdup> function allocates enough memory to contain I<$string> and 
then copies it to that newly allocated memory.  This version of C<strdup> 
returns an opaque pointer type, not a string type.  This may seem a little 
strange, but returning a string type would not be very useful in Perl.

Platforms that do not support C<strdup> will be provided with an equivalent 
using C<malloc> and C<memcpy> written in Perl.  This version is slower.

=cut

our @EXPORT = qw( malloc free calloc realloc memcpy memset sizeof cast strdup );

my $ffi = FFI::Platypus->new;
$ffi->lib(undef);
$ffi->type($_) foreach qw( opaque size_t void int );

$ffi->attach(malloc  => ['size_t']                     => 'opaque' => '$');
$ffi->attach(free    => ['opaque']                     => 'void'   => '$');
$ffi->attach(calloc  => ['size_t', 'size_t']           => 'opaque' => '$$');
$ffi->attach(realloc => ['opaque', 'size_t']           => 'opaque' => '$$');
$ffi->attach(memcpy  => ['opaque', 'opaque', 'size_t'] => 'opaque' => '$$$');
$ffi->attach(memset  => ['opaque', 'int', 'size_t']    => 'opaque' => '$$$');

eval { $ffi->attach(strdup  => ['string'] => 'opaque' => '$') };
if($@)
{
  *strdup = sub ($) {
    my($string) = @_;
    my $ptr = malloc(length($string)+1);
    memcpy($ptr, cast('string' => 'opaque', $string), length($string)+1);
  };
}

sub sizeof ($)
{
  $ffi->type($_[0]);
  $ffi->type_meta($_[0])->{size};
}

sub cast ($$$)
{
  my($type1, $type2, $value) = @_;
  $ffi->function(0 => [$type1] => $type2)->call($value);
}

1;
