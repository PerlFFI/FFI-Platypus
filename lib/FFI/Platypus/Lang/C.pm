package FFI::Platypus::Lang::C;

use strict;
use warnings;

# ABSTRACT: Documentation and tools for using Platypus with the C programming language
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus;
 my $ffi = FFI::Platypus->new( api => 1 );
 $ffi->lang('C'); # the default

=head1 DESCRIPTION

This module provides some hooks for Platypus to interact with the C
programming language.  It is generally used by default if you do not
specify another foreign programming language with the
L<FFI::Platypus#lang> attribute.

=head1 METHODS

=head2 native_type_map

 my $hashref = FFI::Platypus::Lang::C->native_type_map;

This returns a hash reference containing the native aliases for the
C programming languages.  That is the keys are native C types and the
values are libffi native types.

=cut

sub native_type_map
{
  require FFI::Platypus::ShareConfig;
  FFI::Platypus::ShareConfig->get('type_map');
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=back

=cut
