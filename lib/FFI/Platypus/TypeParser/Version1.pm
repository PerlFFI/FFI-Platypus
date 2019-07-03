package FFI::Platypus::TypeParser::Version1;

use strict;
use warnings;
use Carp qw( croak );
use base qw( Exporter );
use base qw( FFI::Platypus::TypeParser );
use FFI::Platypus::Internal;

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

our @EXPORT_OK = qw( parse );

my $regex = qr{

    (
      [A-Za-z_]  ( [A-Za-z_0-9 ]* [A-Za-z_0-9] )?                                          | #  $1,  ($2) the base type
      record \(  (  [A-Za-z_] [A-Za-z_0-9]* ( :: [A-Za-z_] [A-Za-z_0-9]* )* | [0-9]+ ) \)  | #  $3,  ($4) record name
      (string|string[ _]ro|string[ _]rw)  \(  ( [0-9]+ ) \)                                  # ($5),  $6 fixed string size
    )

    ( \* | \[ ([0-9]+) \] | )                       # $7 is the shape specifier
                                                    # $8 is the array count
  
  }x;

sub parse
{
  my($type, $base_aliases) = @_;

  my $code;
  my %type;

  if($type =~ $regex)
  {
    my $base     = $1;
    my $record   = $3;
    my $fixed    = $6;
    my $shape    = $7;
    my $count    = $8;

    if($shape eq '*')
    {
      $code |= FFI_PL_SHAPE_POINTER;
    }
    elsif($shape =~ /^\[/)
    {
      $code |= FFI_PL_SHAPE_ARRAY;
      $type{count} = $count;
    }
    elsif($shape eq '')
    {
      $code |= FFI_PL_SHAPE_SCALAR;
    }
    else
    {
      croak("unknown shape: $shape");
    }

    if($record)
    {
      if($shape eq '*' || $shape =~ /^\[/)
      {
        $code |= FFI_PL_BASE_RECORD;
        if($record =~ /^[0-9]+$/)
        {
          $type{record_size} = $record;
        }
        else
        {
          $type{record_class} = $record;
        }
      }
      else
      {
        croak("ony scalar and pointer records allowed");
      }
    }
    elsif($fixed)
    {
      if($shape eq '*' || $shape =~ /^\[/)
      {
        $code |= FFI_PL_BASE_RECORD;
        $type{record_size} = $fixed;
      }
      else
      {
        croak("only scalar and pointer fixed strings allowed");
      }
    }
    else
    {
      my $method = "FFI_PL_TYPE_" . uc($base);
      if($base =~ /^( [su]int(8|16|32|64) | float | double | longdouble | complex_float | complex_double )$/x  && __PACKAGE__->can($method))
      {
        $code |= __PACKAGE__->$method;
      }
      elsif($base_aliases->{$base})
      {
        $code |= $base_aliases->{$base};
      }
      else
      {
        croak("unknown base type: $base");
      }
    }
  }

  return ($code, \%type)
}

1;
