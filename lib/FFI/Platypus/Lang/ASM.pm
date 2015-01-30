package FFI::Platypus::Lang::ASM;

use strict;
use warnings;

# ABSTRACT: Documentation and tools for using Platypus with the Assembly
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus;
 my $ffi = FFI::Platypus->new;
 $ffi->lang('ASM');

=head1 DESCRIPTION

Setting your lang to C<ASM> removes all non ffi types.  

This document will one day include information on bundling Assembly
with your Perl / FFI / Platypus distribution.  Pull requests welcome!

=head1 METHODS

=head2 native_type_map

 my $hashref = FFI::Platypus::Lang::C->native_type_map;

This returns a hash reference containing the native aliases for the
C programming languages.  That is the keys are native C types and the
values are libffi native types.

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
