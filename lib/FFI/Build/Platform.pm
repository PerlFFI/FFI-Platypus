package FFI::Build::Platform;

use strict;
use warnings;
use 5.008001;
use Config ();
use Carp ();
use Text::ParseWords ();

# ABSTRACT: Platform specific configuration.
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new

=cut

sub new
{
  my($class, $config) = @_;
  $config ||= \%Config::Config;
  my $self = bless {
    config => $config,
  }, $class;
  $self;
}

=head2 default

=cut

my $default;
sub default
{
  $default ||= FFI::Build::Platform->new;
}

sub _context
{
  if(defined wantarray)
  {
    if(wantarray)
    {
      return @_;
    }
    else
    {
      return $_[0];
    }
  }
  else
  {
    Carp::croak("method does not work in void context");
  }
}

sub _self
{
  my($self) = @_;
  ref $self ? $self : $self->default;
}

=head1 METHODS

=head2 osname

The "os name" as understood by Perl.  This is the same as C<$^O>.

=cut

sub osname
{
  _context _self(shift)->{config}->{osname};
}

=head2 object_suffix

The object suffix for the platform.  On UNIX this is usually C<.o>.  On Windows this
is usually C<.obj>.

=cut

sub object_suffix
{
  _context _self(shift)->{config}->{obj_ext};
}

=head2 library_suffix

The library suffix for the platform.  On Linux and some other UNIX this is often C<.so>.
On OS X, this is C<.dylib> and C<.bundle>.  On Windows this is C<.dll>.

=cut

sub library_suffix
{
  my $self = _self(shift);
  my $osname = $self->osname;
  if($osname eq 'darwin')
  {
    return _context '.dylib', '.bundle';
  }
  elsif($osname =~ /^(MSWin32|msys|cygwin)$/)
  {
    return _context '.dll';
  }
  else
  {
    return _context '.' . $self->{config}->{dlext}
  }
}

=head2 cflags

The compiler flags needed to compile object files that can be linked into a dynamic library.
On Linux, for example, this is usually -fPIC.

=cut

sub _shellwords
{
  Text::ParseWords::shellwords(@_);
}

sub cflags
{
  my $self = _self(shift);
  
  unless($self->{cflags})
  {
    my @cflags;
    push @cflags, grep /^-fPIC$/i, _shellwords($self->{config}->{cccdlflags});
    $self->{cflags} = \@cflags;
  }
  
  wantarray ? @{ $self->{cflags} } : join ' ', @{ $self->{cflags} };
}

=head2 diag

Diagnostic for the platform as a string.  This is for human consumption only, and the format
may and will change over time so do not attempt to use is programmatically.

=cut

sub diag
{
  my $self = _self(shift);
  my @diag;
  
  push @diag, "osname            : ". join(", ", $self->osname);
  push @diag, "object suffix     : ". join(", ", $self->object_suffix);
  push @diag, "library suffix    : ". join(", ", $self->library_suffix);
  push @diag, "cflags            : ". $self->cflags;

  join "\n", @diag;
}

1;
