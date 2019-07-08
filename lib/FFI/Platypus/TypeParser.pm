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

{
  my %store;
  our %basic_type;

  foreach my $name (keys %basic_type)
  {
    my $type_code = $basic_type{$name};
    $store{basic}->{$name} = __PACKAGE__->create_type_basic($type_code);
    $store{ptr}->{$name}   = __PACKAGE__->create_type_pointer($type_code);
  }

  $store{$_}->{pointer} = $store{$_}->{opaque} for qw( basic ptr );

  sub store
  {
    \%store;
  }
}

1;
