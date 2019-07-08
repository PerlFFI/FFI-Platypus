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

sub parse
{
  my($self, $name, $ffi) = @_;

  # the platypus object is only needed for closures, so
  # that it can lookup existing types.

  if($name =~ m/^ \( (.*) \) \s* -\> \s* (.*) \s* $/x)
  {
    croak "passing closure into a closure not supported" if $1 =~ /(\(|\)|-\>)/;
    my @argument_types = map { $ffi->_type_lookup($_) } map { s/^\s+//; s/\s+$//; $_ } split /,/, $1;
    my $return_type = $ffi->_type_lookup($2);
    return $self->create_type_closure($return_type, @argument_types);
  }

  if($name =~ /^ string \s* \( ([0-9]+) \) $/x)
  {
    return $self->create_type_record(
      $1,    # size
      undef, # record_class
      0,     # pass by value
    );
  }

  if($name =~ /^ string ( _rw | _ro | \s+ro | \s+rw | ) $/x)
  {
    return $self->create_type_string(
      defined $1 && $1 =~ /rw/ ? 1 : 0,   # rw
   );
  }

  if($name =~ /^ record \s* \( ([0-9]+) \) $/x)
  {
    return $self->create_type_record(
      $1,             # size
      undef,          # record_class
      0,              # pass by value
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
    return $self->create_type_record(
      $size,          # size
      $classname,     # record_class
      0,              # pass by value
    );
  }

  if($name =~ s/\s+ \[ ([0-9]*) \] $//x)
  {
    return $self->create_type_array(
      $name,       # name
      $1 ? $1 : 0, # size
    );
  }

  my $type;

  if($name =~ s/\s+\*$//) {
    $type = $self->store->{ptr}->{$name} || croak("unknown ffi/platypus type $name *");
  } else {
    $type = $self->store->{basic}->{$name} || croak("unknown ffi/platypus type $name");
  }

  $type->first_use;

  $type;
}

1;
