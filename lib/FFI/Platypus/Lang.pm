package FFI::Platypus::Lang;

use strict;
use warnings;
use 5.008004;

# ABSTRACT: Language specific customizations
# VERSION

=head1 SYNOPSIS

 perldoc FFI::Platypus::Lang;

=head1 DESCRIPTION

This namespace is reserved for language specific customizations of L<FFI::Platypus>.
This usually involves providing native type maps.  It can also involve computing
mangled names.  The default language is C, and is defined in L<FFI::Platypus::Lang::C>.

This package itself doesn't do anything, it serves only as documentation.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

=item L<FFI::Platypus::Lang::C>

=back

=cut


1;
