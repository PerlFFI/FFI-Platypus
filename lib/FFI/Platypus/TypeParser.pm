package FFI::Platypus::TypeParser;

use strict;
use warnings;
use 5.008004;
use List::Util 1.45 qw( uniqstr );
use Carp qw( croak );

# ABSTRACT: FFI Type Parser
# VERSION

=head1 DESCRIPTION

This class is private to FFI::Platypus.  See L<FFI::Platypus> for
the public interface to Platypus types.

=cut

# The TypeParser and Type classes are used internally ONLY and
# are not to be exposed to the user.  External users should
# not under any circumstances rely on the implementation of
# these classes.

sub new
{
  my($class) = @_;
  my $self = bless { types => {}, type_map => {} }, $class;
  $self->build;
  $self;
}

sub build {}

our %basic_type;

# this just checks if the underlying libffi/platypus implementation
# has the basic type.  It is used mainly to verify that exotic types
# like longdouble and complex_float are available before the test
# suite tries to use them.
sub have_type
{
  my(undef, $name) = @_;
  !!$basic_type{$name};
}

sub create_type_custom
{
  my($self, $name, @rest) = @_;
  $name = 'opaque' unless defined $name;
  my $type = $self->parse($name);
  unless($type->is_customizable)
  {
    croak "$name is not a legal basis for a custom type"
  }
  $self->_create_type_custom($type, @rest);
}

# this is the type map provided by the language plugin, if any
# in addition to the basic types (which map to themselves).
sub type_map
{
  my($self, $new) = @_;

  if(defined $new)
  {
    $self->{type_map} = $new;
  }

  $self->{type_map};
}

# this stores the types that have been mentioned so far.  It also
# usually includes aliases.
sub types
{
  shift->{types};
}

{
  my %store;

  foreach my $name (keys %basic_type)
  {
    my $type_code = $basic_type{$name};
    $store{basic}->{$name} = __PACKAGE__->create_type_basic($type_code);
    $store{ptr}->{$name}   = __PACKAGE__->create_type_pointer($type_code);
    $store{rev}->{$type_code} = $name;
  }

  sub global_types
  {
    \%store;
  }
}

# list all the types that this type parser knows about, including
# those provided by the language plugin (if any), those defined
# by the user, and the basic types that everyone gets.
sub list_types
{
  my($self) = @_;
  uniqstr( ( keys %{ $self->type_map } ), ( keys %{ $self->types } ) );
}

our @CARP_NOT = qw( FFI::Platypus );

1;
