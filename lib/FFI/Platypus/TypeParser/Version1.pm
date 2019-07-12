package FFI::Platypus::TypeParser::Version1;

use strict;
use warnings;
use Carp qw( croak );
use base qw( FFI::Platypus::TypeParser );

# ABSTRACT: FFI Type Parser Version One
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus;
 my $ffi = FFI::Platypus->new( api => 1 );
 $ffi->type('record(Foo::Bar)' => 'foo_bar_t');
 $ffi->type('record(Foo::Bar)*' => 'foo_bar_ptr');
 $ffi->type('opaque' => 'baz_t');
 $ffi->type('bar_t*' => 'baz_ptr');

=head1 DESCRIPTION

This documents the second (version 1) type parser for L<FFI::Platypus>.
This type parser was included with L<FFI::Platypus> starting with version
C<0.91> in an experimental capability, and C<1.00> as a stable interface.
Starting with version C<1.00> the main L<FFI::Platypus> documentation
describes the version 1 API and you can refer to
L<FFI::Platypus::TypeParser::Version0> for details on the version0 API.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The core L<FFI::Platypus> documentation.

=item L<FFI::Platypus::TypeParser::Version0>

The API C<0.02> type parser.

=back

=cut

our @CARP_NOT = qw( FFI::Platypus FFI::Platypus::TypeParser );

my %reserved = map { $_ => 1 } qw(
  struct
  enum
);

# The type parser is responsible for deciding if something is a legal
# alias name.  Since this needs to be checked before the type is parsed
# it is separate from set_alias below.
sub check_alias
{
  my($self, $alias) = @_;
  croak "spaces not allowed in alias" if $alias =~ /\s/;
  croak "allowed characters for alias: [A-Za-z0-9_]" if $alias !~ /^[A-Za-z0-9_]+$/;
  croak "reserved world \"$alias\" cannot be used as an alias"
    if $reserved{$alias};
  croak "alias \"$alias\" conflicts with existing type"
    if defined $self->type_map->{$alias}
    || $self->types->{$alias}
    || $self->global_types->{basic}->{$alias};
  return 1;
}

sub set_alias
{
  my($self, $alias, $type) = @_;
  $self->types->{$alias} = $type;
}

use constant type_regex =>

  qr/^                                                                                                                                                            #
                                                                                                                                                                  #
    \s*                                                                                                                                                           # prefix white space
                                                                                                                                                                  #
    (?:                                                                                                                                                           #
                                                                                                                                                                  #
      \( ([^)]+) \) -> (.*)                                                                                                                                       # closure  $1 argument types, $2 return type
      |                                                                                                                                                           #
      (?: string | record ) \s* \( \s* ([0-9]+) \s* \)                                                              (?: \s* (\*) | )                              # fixed record, fixed string $3, ponter $4
      |                                                                                                                                                           #
      record                \s* \( (  \s* (?: [A-Za-z_] [A-Za-z_0-9]* :: )* [A-Za-z_] [A-Za-z_0-9]* ) \s* \)        (?: \s* (\*) | )                              # record class $5, pointer $6
      |                                                                                                                                                           #
      ( (?: [A-Za-z_] [A-Za-z_0-9]* \s+ )* [A-Za-z_] [A-Za-z_0-9]* )         \s*                                                                                  # unit type name $7
                                                                                                                                                                  #
              (?:  (\*)  |   \[ ([0-9]*) \]  |  )                                                                                                                 # pointer $8,       array $9
                                                                                                                                                                  #
    )                                                                                                                                                             #
                                                                                                                                                                  #
    \s*                                                                                                                                                           # trailing white space
                                                                                                                                                                  #
  $/x;                                                                                                                                                            #

sub parse
{
  my($self, $name) = @_;

  return $self->types->{$name} if $self->types->{$name};

  $name =~ type_regex or croak "bad type name: $name";

  if(defined (my $size = $3))  # fixed record / fixed string
  {
    croak "fixed record / fixed string size must be larger than 0"
      unless $size > 0;

    if(my $pointer = $4)
    {
      return $self->types->{$name} = $self->create_type_record(
        $size,
        undef,
        0,
      );
    }
    else
    {
      croak "todo pass-by-value fixed record";
    }
  }

  if(defined (my $class = $5))  # class record
  {
    my $size_method = $class->can('ffi_record_size') || $class->can('_ffi_record_size') || croak "$class has no ffi_record_size or _ffi_record_size_ method";
    if(my $pointer = $6)
    {
      return $self->types->{$name} = $self->create_type_record(
        $class->$size_method,
        $class,
        0,
      );
    }
    else
    {
      croak "todo pass-by-value record";
    }
  }

  if(defined (my $unit_name = $7))  # basic type
  {
    if($self->global_types->{basic}->{$unit_name})
    {
      if(my $pointer = $8)
      {
        croak "void pointer not allowed" if $unit_name eq 'void';
        return $self->types->{$name} = $self->global_types->{ptr}->{$unit_name};
      }

      if(defined (my $size = $9))  # array
      {
        croak "void array not allowed" if $unit_name eq 'void';
        if($size ne '')
        {
          croak "array size must be larger than 0" if $size < 1;
          return $self->types->{$name} = $self->create_type_array(
            $self->global_types->{basic}->{$unit_name}->type_code,
            $size,
          );
        }
        else
        {
          return $self->global_types->{array}->{$unit_name} ||= $self->create_type_array(
            $self->global_types->{basic}->{$unit_name}->type_code,
            0,
          );
        }
      }

      # basic type with no decorations
      return $self->global_types->{basic}->{$unit_name};
    }

    if(my $map_name = $self->type_map->{$unit_name})
    {
      if(my $pointer = $8)
      {
        return $self->types->{$name} = $self->parse("$map_name *");
      }
      if(defined (my $size = $9))
      {
        if($size ne '')
        {
          croak "array size must be larger than 0" if $size < 1;
          return $self->types->{$name} = $self->parse("$map_name [$size]");
        }
        else
        {
          return $self->types->{$name} = $self->parse("$map_name []");
        }
      }

      return $self->types->{$name} = $self->parse("$map_name");
    }

    if(my $unit_type = $self->parse($unit_name))
    {

      if(my $pointer = $8)
      {
        my $basic_name = $self->global_types->{rev}->{$unit_type->type_code};
        if($basic_name)
        {
          return $self->types->{$name} = $self->parse("$basic_name *");
        }
        else
        {
          croak "cannot make a pointer to $unit_name";
        }
      }

      if(defined (my $size = $9))
      {
        my $basic_name = $self->global_types->{rev}->{$unit_type->type_code};
        if($basic_name)
        {
          if($size ne '')
          {
            croak "array size must be larger than 0" if $size < 1;
            return $self->types->{$name} = $self->parse("$basic_name [$size]");
          }
          else
          {
            return $self->types->{$name} = $self->parse("$basic_name []");
          }
        }
        else
        {
          croak "cannot make an array of $unit_name";
        }
      }

      return $self->types->{$name} = $unit_type;
    }

    croak "unknown type: $unit_name";
  }

  croak "internal error parsing: $name";
}

1;