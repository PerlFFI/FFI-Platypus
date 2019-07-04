package FFI::Platypus::TypeParser;

use strict;
use warnings;

# ABSTRACT: FFI Type Parser
# VERSION

=head1 DESCRIPTION

This class is private to FFI::Platypus.  See L<FFI::Platypus> for
the public interface to Platypus types.

=cut

sub new
{
  my($class) = @_;
  my $self = bless {}, $class;
  $self->build;
  $self;
}

sub build {}

1;
