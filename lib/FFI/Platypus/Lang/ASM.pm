package FFI::Platypus::Lang::ASM;

use strict;
use warnings;

# ABSTRACT: Documentation and tools for using Platypus with the Assembly
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus;
 my $ffi = FFI::Platypus->new( api => 1 );
 $ffi->lang('ASM');

=head1 DESCRIPTION

Setting your lang to C<ASM> includes no native type aliases, so types
like C<int> or C<unsigned long> will not work.  You need to specify
instead C<sint32> or C<sint64>.  Although intended for use with Assembly
it could also be used for other languages if you did not want to use
the normal C aliases for native types.

This document will one day include information on bundling Assembly
with your Perl / FFI / Platypus distribution.  Pull requests welcome!

=head1 METHODS

=head2 native_type_map

 my $hashref = FFI::Platypus::Lang::ASM->native_type_map;

This returns an empty hash reference.  For other languages it returns
a hash reference that defines the aliases for the types normally used
for that language.

=cut

sub native_type_map
{
  {}
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=back

=cut
