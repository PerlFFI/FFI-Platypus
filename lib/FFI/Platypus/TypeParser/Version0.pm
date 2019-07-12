package FFI::Platypus::TypeParser::Version0;

use strict;
use warnings;
use Carp qw( croak );
use base qw( FFI::Platypus::TypeParser );

# ABSTRACT: FFI Type Parser Version Zero
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus;
 my $ffi = FFI::Platypus->new( api => 0 );
 $ffi->type('record(Foo::Bar)' => 'foo_bar_t');
 $ffi->type('opaque' => 'baz_t');
 $ffi->type('opaque*' => 'baz_ptr');

=head1 DESCRIPTION

This documents the original L<FFI::Platypus> type parser.  It was the default and only
type parser used by L<FFI::Platypus> starting with version C<0.02>.  Starting with
version C<1.00> L<FFI::Platypus> comes with a new type parser with design fixes that
are not backward compatibility.

=head2 Interface differences

=over

=item Pass-by-value records are not allowed

Originally L<FFI::Platypus> only supported passing records as a pointer.  The type
C<record(Foo::Bar)> actually passes a pointer to the record.  In the version 1.00 parser
allows C<record(Foo::Bar)> which is pass-by-value (the contents of the record is copied
onto the stack) and C<record(Foo::Bar)*> which is pass-by-reference or pointer (a pointer
to the record is passed to the callee so that it can make modifications to the record).

TL;DR C<record(Foo::Bar)> in version 0 is equivalent to C<record(Foo::Bar)*> in the
version 1 API.  There is no equivalent to C<record(Foo::Bar)*> in the version 0 API.

=item decorate aliases of basic types

This is not allowed in the version 0 API:

 $ffi->type('opaque' => 'foo_t');    # ok!
 $ffi->type('foo_t*' => 'foo_ptr');  # not ok! in version 0, ok! in version 1

Instead you need to use the basic type in the second type definition:

 $ffi->type('opaque' => 'foo_t');    # ok!
 $ffi->type('opaque*' => 'foo_ptr'); # ok!

=back

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The core L<FFI::Platypus> documentation.

=item L<FFI::Platypus::TypeParser::Version1>

The API C<1.00> type parser.

=back

=cut

our @CARP_NOT = qw( FFI::Platypus FFI::Platypus::TypeParser );

# The type parser is responsible for deciding if something is a legal
# alias name.  Since this needs to be checked before the type is parsed
# it is separate from set_alias below.
sub check_alias
{
  my($self, $alias) = @_;
  croak "spaces not allowed in alias" if $alias =~ /\s/;
  croak "allowed characters for alias: [A-Za-z0-9_]" if $alias !~ /^[A-Za-z0-9_]+$/;
  croak "alias \"$alias\" conflicts with existing type"
    if defined $self->type_map->{$alias}
    || $self->types->{$alias};
  return 1;
}

sub set_alias
{
  my($self, $alias, $type) = @_;
  $self->types->{$alias} = $type;
}

# This method takes a string representation of the a type and
# returns the internal platypus type representation.
sub parse
{
  my($self, $name) = @_;

  return $self->types->{$name} if defined $self->types->{$name};

  # Darmock and Legacy Code at Tanagra
  unless($name =~ /-\>/ || $name =~ /^record\s*\([0-9A-Z:a-z_]+\)$/
  || $name =~ /^string(_rw|_ro|\s+rw|\s+ro|\s*\([0-9]+\))$/)
  {
    my $basic = $name;
    my $extra = '';
    if($basic =~ s/\s*((\*|\[|\<).*)$//)
    {
      $extra = " $1";
    }
    if(defined $self->type_map->{$basic})
    {
      my $new_name = $self->type_map->{$basic} . $extra;
      if($new_name ne $name)
      {
        # hopefully no recursion here.
        return $self->types->{$name} = $self->parse($new_name);
      }
    }
  }

  if($name =~ m/^ \( (.*) \) \s* -\> \s* (.*) \s* $/x)
  {
    my @argument_types = map { $self->parse($_) } map { s/^\s+//; s/\s+$//; $_ } split /,/, $1;
    my $return_type = $self->parse($2);
    return $self->types->{$name} = $self->create_type_closure($return_type, @argument_types);
  }

  if($name =~ /^ string \s* \( ([0-9]+) \) $/x)
  {
    return $self->types->{$name} = $self->create_type_record(
      $1,    # size
      undef, # record_class
    );
  }

  if($name =~ /^ string ( _rw | _ro | \s+ro | \s+rw | ) $/x)
  {
    return $self->types->{$name} = $self->create_type_string(
      defined $1 && $1 =~ /rw/ ? 1 : 0,   # rw
   );
  }

  if($name =~ /^ record \s* \( ([0-9]+) \) $/x)
  {
    return $self->types->{$name} = $self->create_type_record(
      $1,             # size
      undef,          # record_class
    );
  }

  if($name =~ /^ record \s* \( ([0-9:A-Za-z_]+) \) $/x)
  {
    my $size;
    my $classname = $1;
    unless($classname->can('ffi_record_size') || $classname->can('_ffi_record_size'))
    {
      my $pm = "$classname.pm";
      $pm =~ s/\//::/g;
      require $pm;
    }
    if($classname->can('ffi_record_size'))
    {
      $size = $classname->ffi_record_size;
    }
    elsif($classname->can('_ffi_record_size'))
    {
      $size = $classname->_ffi_record_size;
    }
    else
    {
      croak "$classname has not ffi_record_size or _ffi_record_size method";
    }
    return $self->global_types->{record}->{$classname} ||= $self->create_type_record(
      $size,          # size
      $classname,     # record_class
    );
  }

  # array types
  if($name =~ /^([\S]+)\s+ \[ ([0-9]*) \] $/x)
  {
    my $size = $2 || '';
    my $basic = $self->global_types->{basic}->{$1} || croak("unknown ffi/platypus type $name [$size]");
    if($size)
    {
      return $self->types->{$name} = $self->create_type_array(
        $basic->type_code,
        $size,
      );
    }
    else
    {
      return $self->global_types->{array}->{$name} ||= $self->create_type_array(
        $basic->type_code,
        0
      );
    }
  }

  # pointer types
  if($name =~ s/\s+\*$//)
  {
    return $self->global_types->{ptr}->{$name} || croak("unknown ffi/platypus type $name *");
  }

  # basic types
  return $self->global_types->{basic}->{$name} || croak("unknown ffi/platypus type $name");
}

1;
