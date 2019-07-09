package FFI::Platypus::TypeParser;

use strict;
use warnings;
use Carp qw( croak );

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

our %basic_type;

sub have_type
{
  my(undef, $name) = @_;
  !!$basic_type{$name};
}

sub create_type_custom
{
  my($self, $name, @rest) = @_;
  my $basic = $self->store->{basic}->{$name} || croak "unknown type $name";
  $self->_create_type_custom($basic->type_code, @rest);
}

sub type_map
{
  my($self, $new) = @_;

  if(defined $new)
  {
    $self->{type_map} = $new;
  }

  $self->{type_map};
}

{
  my %store;

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
