package FFI::Platypus::API;

use strict;
use warnings;
use FFI::Platypus;
use base qw( Exporter );

our @EXPORT = grep /^arguments_/, keys %FFI::Platypus::API::;

# ABSTRACT: Platypus arguments and return value API for custom types
# VERSION

=head1 SYNOPSIS

 package FFI::Platypus::Type::MyCustomType;
 
 use FFI::Platypus::API;
 
 sub ffi_custom_type_api_1
 {
   {
     native_type => 'uint32',
     perl_to_native => sub {
       my($value, $i) = @_;
       # Translates ($value) passed in from Perl
       # into ($value+1, $value+2)
       arguments_set_uint32($i, $value+1);
       arguments_set_uint32($i+1, $value+2);
     },
     argument_count => 2,
   }
 }

=head1 DESCRIPTION

The custom types API for L<FFI::Platypus> allows you to set multiple C arguments
from a single Perl argument as a common type.  This is sometimes useful for 
pointer / size pairs which are a common pattern in C, but are usually represented by
a single value (a string scalar) in Perl.

The custom type API is somewhat experimental, and you should expect
some changes as needs arise (I won't break compatibility lightly, however).

=head1 FUNCTIONS

These functions are only valid within a custom type callback.

=head2 arguments_count

 my $count = argument_count;

Returns the total number of native arguments.

=head2 arguments_get_sint8

 my $sint8 = arguments_get_sint8 $i;

Get the 8 bit signed integer argument from position I<$i>.

=head2 arguments_set_sint8

 arguments_set_sint8 $i, $sint8;

Set the 8 bit signed integer argument at position I<$i> to I<$sint8>.

=head2 arguments_get_uint8

 my $uint8 = arguments_get_uint8 $i;

Get the 8 bit unsigned integer argument from position I<$i>.

=head2 arguments_set_uint8

 arguments_set_uint8 $i, $uint8;

Set the 8 bit unsigned integer argument at position I<$i> to I<$uint8>.

=head2 arguments_get_sint16

 my $sint16 = arguments_get_sint16 $i;

Get the 16 bit signed integer argument from position I<$i>.

=head2 arguments_set_sint16

 arguments_set_sint16 $i, $sint16;

Set the 16 bit signed integer argument at position I<$i> to I<$sint16>.

=head2 arguments_get_uint16

 my $uint16 = arguments_get_uint16 $i;

Get the 16 bit unsigned integer argument from position I<$i>.

=head2 arguments_set_uint16

 arguments_set_uint16 $i, $uint16;

Set the 16 bit unsigned integer argument at position I<$i> to I<$uint16>.

=head2 arguments_get_sint32

 my $sint32 = arguments_get_sint32 $i;

Get the 32 bit signed integer argument from position I<$i>.

=head2 arguments_set_sint32

 arguments_set_sint32 $i, $sint32;

Set the 32 bit signed integer argument at position I<$i> to I<$sint32>.

=head2 arguments_get_uint32

 my $uint32 = arguments_get_uint32 $i;

Get the 32 bit unsigned integer argument from position I<$i>.

=head2 arguments_set_uint32

 arguments_set_uint32 $i, $uint32;

Set the 32 bit unsigned integer argument at position I<$i> to I<$uint32>.

=head2 arguments_get_sint64

 my $sint64 = arguments_get_sint64 $i;

Get the 64 bit signed integer argument from position I<$i>.

=head2 arguments_set_sint64

 arguments_set_sint64 $i, $sint64;

Set the 64 bit signed integer argument at position I<$i> to I<$sint64>.

=head2 arguments_get_uint64

 my $uint64 = arguments_get_uint64 $i;

Get the 64 bit unsigned integer argument from position I<$i>.

=head2 arguments_set_uint64

 arguments_set_uint64 $i, $uint64;

Set the 64 bit unsigned integer argument at position I<$i> to I<$uint64>.

=head2 arguments_get_float

 my $float = arguments_get_float $i;

Get the floating point argument from position I<$i>.

=head2 arguments_set_float

 arguments_set_float $i, $float;

Set the floating point argument at position I<$i> to I<$float>

=head2 arguments_get_double

 my $double = arguments_get_double $i;

Get the double precision floating point argument from position I<$i>.

=head2 arguments_set_double

 arguments_set_double $i, $double;

Set the double precision floating point argument at position I<$i> to I<$double>

=head2 arguments_get_pointer

 my $pointer = arguments_get_pointer $i;

Get the pointer argument from position I<$i>.

=head2 arguments_set_pointer

 arguments_set_pointer $i, $pointer;

Set the pointer argument at position I<$i> to I<$pointer>.

=head2 arguments_get_string

 my $string = arguments_get_string $i;

Get the string argument from position I<$i>.

=head2 arguments_set_string

 arguments_set_string $i, $string;

Set the string argument at position I<$i> to I<$string>.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

=back

Examples of use:

=over 4

=item L<FFI::Platypus::Type::PointerSizeBuffer>

=back

=cut

1;
