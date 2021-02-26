package FFI::Platypus::Type::WideString;

use strict;
use warnings;
use 5.008004;
use FFI::Platypus;
use FFI::Platypus::Memory ();
use Encode qw( decode encode );
use Carp ();

# ABSTRACT: Platypus custom type for Unicode "wide" strings
# VERSION

=head1 SYNOPSIS

# TODO

=head1 DESCRIPTION

# TODO

=cut

use constant _incantation =>
  $^O eq 'MSWin32' && do { require Config; $Config::Config{archname} =~ /MSWin32-x64/ }
    ? 'Q'
    : 'L!';

my @stack;  # To keep buffer alive.

sub _compute_wide_string_encoding
{
  foreach my $need (qw( wcslen wcsnlen ))
  {
    die "This type plugin needs $need from libc, and cannot find it"
      unless FFI::Platypus::Memory->can("_$need");
  }

  my $ffi = FFI::Platypus->new( api => 1, lib => [undef] );

  my $size = eval { $ffi->sizeof('wchar_t') };
  die 'no wchar_t' if $@;

  my %orders = (
    join('', 1..$size)         => 'BE',
    join('', reverse 1..$size) => 'LE',
  );

  my $byteorder = join '', @{ $ffi->cast( "wchar_t*", "uint8[$size]", \hex(join '', map { "0$_" } 1..$size) ) };

  my $encoding;

  if($size == 2)
  {
    $encoding = 'UTF-16';
  }
  elsif($size == 4)
  {
    $encoding = 'UTF-32';
  }
  else
  {
    die "not sure what encoding to use for size $size";
  }

  if(defined $orders{$byteorder})
  {
    $encoding .= $orders{$byteorder};
  }
  else
  {
    die "odd byteorder $byteorder not (yet) supported";
  }

  return ($encoding, $size);
}

sub ffi_custom_type_api_1
{
  my %args = @_;

  my($encoding, $width) = __PACKAGE__->_compute_wide_string_encoding();

  my $size   = $args{size} || 1024;
  my $access = $args{access} || 'read';

  my %ct = (
    native_type    => 'opaque',
  );

  $ct{native_to_perl} = sub {
    return undef unless defined $_[0];
    return decode($encoding, unpack('P'.(FFI::Platypus::Memory::_wcslen($_[0])*$width), pack(_incantation, $_[0])));
  };

  if($access eq 'read')
  {
    $ct{perl_to_native} = sub {
      if(defined $_[0])
      {
        my $buf = encode($encoding, $_[0]."\0");
        push @stack, \$buf;
        return unpack(_incantation, pack 'P', $buf);
      }
      else
      {
        push @stack, undef;
        return undef;
      }
    };

    $ct{perl_to_native_post} = sub {
      pop @stack;
      return;
    };

  }
  elsif($access eq 'write')
  {
    my @stack;

    $ct{perl_to_native} = sub {
      my $ref = shift;
      push @stack, $ref;
      if(ref($ref) eq 'SCALAR')
      {
        $$ref = "\0" x $size unless defined $$ref;
        return unpack(_incantation, pack 'P', $$ref);
      }
      else
      {
        return undef;
      }
    };

    $ct{perl_to_native_post} = sub {
      my $ref = pop @stack;
      return unless defined $ref;
      my $len = length $$ref;
      $len = FFI::Platypus::Memory::_wcsnlen($$ref, $len);
      $$ref = decode($encoding, substr($$ref, 0, $len*$width));
    };

  }
  else
  {
    Carp::croak("Unknown access type $access");
  }

  return \%ct;
}

1;
