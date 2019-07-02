package FFI::Platypus::TypeParser::Version0;

use strict;
use warnings;
use Carp qw( croak );
use base qw( FFI::Platypus::TypeParser );

# ABSTRACT: FFI Type Parser Version Zero
# VERSION

=head1 DESCRIPTION

This class is private to FFI::Platypus.  See L<FFI::Platypus> for
the public interface to Platypus types.

=cut

sub parse
{
  my($class, $type, $ffi) = @_;

  # the platypus object is only needed for closures, so
  # that it can lookup existing types.

  if($type =~ m/^ \( (.*) \) \s* -\> \s* (.*) \s* $/x)
  {
    croak "passing closure into a closure not supported" if $1 =~ /(\(|\)|-\>)/;
    my @argument_types = map { $ffi->_type_lookup($_) } map { s/^\s+//; s/\s+$//; $_ } split /,/, $1;
    my $return_type = $ffi->_type_lookup($2);
    return $class->create_closure($return_type, @argument_types);
  }

  my $ffi_type;
  my $fuzzy_type;
  my $size = 0;
  my $classname;
  my $rw = 0;

  if($type =~ /^ string \s* \( ([0-9]+) \) $/x)
  {
    return $class->create_type_record(
      $1,    # size
      undef, # record_class
      0,     # pass by value
    );
  }
  elsif($type =~ /^ string ( _rw | _ro | \s+ro | \s+rw | ) $/x)
  {
    my $extra = $1;
    $ffi_type = 'pointer';
    $rw = 1 if $extra =~ /rw$/;
    $fuzzy_type = 'string';
  }
  elsif($type =~ /^ record \s* \( ([0-9:A-Za-z_]+) \) $/x)
  {
    if($1 =~ /^([0-9]+)$/)
    {
      $size = $1;
    }
    else
    {
      $classname = $1;
      unless($classname->can('ffi_record_size') || $classname->can('_ffi_record_size'))
      {
        eval qq{ use $classname };
        warn "error requiring $classname: $@" if $@;
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
    }
    return $class->create_type_record(
      $size,          # size
      $classname,     # record_class
      0,              # pass by value
    );
  }
  elsif($type =~ s/\s+\*$//) {
    $ffi_type = $type;
    $fuzzy_type = 'pointer';
  }
  elsif($type =~ s/\s+\[([0-9]*)\]$//)
  {
    $ffi_type = $type;
    $fuzzy_type = 'array';
    $size = $1 ? $1 : 0;
  }
  else
  {
    $ffi_type = $type;
    $fuzzy_type = 'ffi';
  }

  $class->create_old($ffi_type, $fuzzy_type, $size, $classname, $rw);
}

1;
