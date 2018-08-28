package FFI::Build::Platform;

use strict;
use warnings;
use 5.008001;
use Config ();
use Carp ();
use Text::ParseWords ();
use List::Util 1.45 ();
use File::Temp ();
use Capture::Tiny ();

# ABSTRACT: Platform specific configuration.
# VERSION

=head1 SYNOPSIS

 use FFI::Build::Platform;

=head1 DESCRIPTION

This class is used to abstract out the platform specific parts of the L<FFI::Build> system.
You shouldn't need to use it directly in most cases, unless you are working on L<FFI::Build>
itself.

=head1 CONSTRUCTOR

=head2 new

 my $platform = FFI::Build::Platform->new;

Create a new instance of L<FFI::Build::Platform>.

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

 my $platform = FFI::Build::Platform->default;

Returns the default instance of L<FFI::Build::Platform>.

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

All of these methods may be called either as instance or classes
methods.  If called as a class method, the default instance will
be used.

=head2 osname

 my $osname = $platform->osname;

The "os name" as understood by Perl.  This is the same as C<$^O>.

=cut

sub osname
{
  _context _self(shift)->{config}->{osname};
}

=head2 object_suffix

 my $suffix = $platform->object_suffix;

The object suffix for the platform.  On UNIX this is usually C<.o>.  On Windows this
is usually C<.obj>.

=cut

sub object_suffix
{
  _context _self(shift)->{config}->{obj_ext};
}

=head2 library_suffix

 my(@suffix) = $platform->library_suffix;
 my $suffix  = $platform->library_suffix;

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
    return _context '.' . $self->{config}->{dlext};
  }
}

=head2 library_prefix

 my $prefix = $platform->library_prefix;

The library prefix for the platform.  On Unix this is usually C<lib>, as in C<libfoo>.

=cut

sub library_prefix
{
  my $self = _self(shift);
  
  # this almost certainly requires refinement.
  if($self->osname =~ /^(MSWin32|msys|cygwin)$/)
  {
    return '';
  }
  else
  {
    return 'lib';
  }
}

=head2 cc

 my $cc = $platform->cc;

The C compiler

=cut

sub cc
{
  # TODO: cc could include flags "cc --some-flag" so we should really parse
  # the first element of cc to be our cc, and push the rest into cflags.
  my $cc = shift->{config}->{cc};
  $cc =~ s/^\s+//;
  $cc =~ s/\s+$//;
  $cc;
}

=head2 cxx

 my $cxx = $platform->cxx;

The C++ compiler that naturally goes with the C compiler.

=cut

sub cxx
{
  my $self = _self(shift);
  if($self->{config}->{ccname} eq 'gcc')
  {
    if($self->cc =~ /gcc$/)
    {
      my $maybe = $self->cc;
      $maybe =~ s/gcc$/g++/;
      return $maybe if $self->which($maybe);
    }
    if($self->cc =~ /clang/)
    {
      return 'clang++';
    }
    else
    {
      return 'g++';
    }
  }
  elsif($self->osname eq 'MSWin32' && $self->{config}->{ccname} eq 'cl')
  {
    return 'cl';
  }
  else
  {
    Carp::croak("unable to detect corresponding C++ compiler");
  }
}

=head2 for

 my $for = $platform->for;

The Fortran compiler that naturally goes with the C compiler.

=cut

sub for
{
  my $self = _self(shift);
  if($self->{config}->{ccname} eq 'gcc')
  {
    if($self->cc =~ /gcc$/)
    {
      my $maybe = $self->cc;
      $maybe =~ s/gcc$/gfortran/;
      return $maybe if $self->which($maybe);
    }
    return 'gfortran';
  }
  else
  {
    Carp::croak("unable to detect correspnding Fortran Compiler");
  }
}

=head2 ld

 my $ld = $platform->ld;

The C linker

=cut

sub ld
{
  my $ld = shift->{config}->{ld};
  $ld =~ s/^\s+//;
  $ld =~ s/\s+$//;
  $ld;
}

sub _uniq
{
  List::Util::uniq(@_);
}

=head2 shellwords

 my @words = $platform->shellwords(@strings);

This is a wrapper around L<Text::ParseWords>'s C<shellwords> with some platform  workarounds
applied.

=cut

sub shellwords
{
  my $self = _self(shift);
  if($self->osname eq 'MSWin32')
  {
    # Borrowed from Alien/Base.pm, see the caveat there.
    Text::ParseWords::shellwords(map { my $x = $_; $x =~ s,\\,\\\\,g; $x } @_);
  }
  else
  {
    Text::ParseWords::shellwords(@_);
  }
}

sub _context_args
{
  wantarray ? @_ : join ' ', @_;
}

=head2 cflags

 my $cflags = $platform->cflags;

The compiler flags needed to compile object files that can be linked into a dynamic library.
On Linux, for example, this is usually -fPIC.

=cut

sub cflags
{
  my $self = _self(shift);
  my @cflags;
  push @cflags, _uniq grep /^-fPIC$/i, $self->shellwords($self->{config}->{cccdlflags});
  _context_args @cflags;
}

=head2 ldflags

 my $ldflags = $platform->ldflags;

The linker flags needed to link object files into a dynamic library.  This is NOT the C<libs> style library
flags that specify the location and name of a library to link against, this is instead the flags that tell
the linker to generate a dynamic library.  On Linux, for example, this is usually C<-shared>.

=cut

sub ldflags
{
  my $self = _self(shift);
  my @ldflags;
  if($self->osname eq 'cygwin')
  {
    no warnings 'qw';
    push @ldflags, qw( --shared -Wl,--enable-auto-import -Wl,--export-all-symbols -Wl,--enable-auto-image-base );
  }
  elsif($self->osname eq 'MSWin32' && $self->{config}->{ccname} eq 'cl')
  {
    push @ldflags, qw( -link -dll );
  }
  elsif($self->osname eq 'MSWin32')
  {
    # TODO: VCC support *sigh*
    no warnings 'qw';
    push @ldflags, qw( -mdll -Wl,--enable-auto-import -Wl,--export-all-symbols -Wl,--enable-auto-image-base );
  }
  elsif($self->osname eq 'darwin')
  {
    push @ldflags, '-shared';
  }
  else
  {
    push @ldflags, _uniq grep /^-shared$/i, $self->shellwords($self->{config}->{lddlflags});
  }
  _context_args @ldflags;
}

=head2 extra_system_inc

 my @dir = $platform->extra_syste_inc;

Extra include directory flags, such as C<-I/usr/local/include>, which were configured when Perl was built.

=cut

sub extra_system_inc
{
  my $self = _self(shift);
  my @dir;
  push @dir, _uniq grep /^-I(.*)$/, $self->shellwords(map { $self->{config}->{$_} } qw( ccflags ccflags_nolargefiles cppflags ));
  _context_args @dir;  
}

=head2 extra_system_lib

 my @dir = $platform->extra_syste_lib;

Extra library directory flags, such as C<-L/usr/local/lib>, which were configured when Perl was built.

=cut

sub extra_system_lib
{
  my $self = _self(shift);
  my @dir;
  push @dir, _uniq grep /^-L(.*)$/, $self->shellwords(map { $self->{config}->{$_} } qw( lddlflags ldflags ldflags_nolargefiles ));
  _context_args @dir;  
}

=head2 cc_mm_works

 my $flags = $platform->cc_mm_works;

Returns the flags that can be passed into the C compiler to compute dependencies.

=cut

sub cc_mm_works
{
  my $self = _self(shift);
  my $verbose = shift;
  
  unless(defined $self->{cc_mm_works})
  {
    require FFI::Build::File::C;
    my $c = FFI::Build::File::C->new(\"#include \"foo.h\"\n");
    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    {
      open my $fh, '>', "$dir/foo.h";
      print $fh "\n";
      close $fh;
    }

    my @cmd = (
      $self->cc,
      $self->cflags,
      $self->extra_system_inc,
      "-I$dir",
      '-MM',
      $c->path,
    );
    
    my($out, $exit) = Capture::Tiny::capture_merged(sub {
      print "+ @cmd\n";
      system @cmd;
    });
    
    if($verbose)
    {
      print $out;
    }
    
    
    if(!$exit && $out =~ /foo\.h/)
    {
      $self->{cc_mm_works} = '-MM';
    }
    else
    {
      $self->{cc_mm_works} = 0;
    }
  }
  
  $self->{cc_mm_works};
}

=head2 flag_object_output

 my $flag = $platform->flag_object_output($object_filename);

Returns the flags that the compiler recognizes as being used to write out to a specific object filename.

=cut

sub flag_object_output
{
  my $self = _self(shift);
  my $file = shift;
  if($self->osname eq 'MSWin32' && $self->{config}->{ccname} eq 'cl')
  {
    return ("-Fo$file");
  }
  else
  {
    return ('-o' => $file);
  }
}

=head2 flag_library_output

 my $flag = $platform->flag_library_output($library_filename);

Returns the flags that the compiler recognizes as being used to write out to a specific library filename.

=cut

sub flag_library_output
{
  my $self = _self(shift);
  my $file = shift;
  if($self->osname eq 'MSWin32' && $self->{config}->{ccname} eq 'cl')
  {
    return ("-OUT:$file");
  }
  else
  {
    return ('-o' => $file);
  }
}

=head2 which

 my $path = $platform->which($command);

Returns the full path of the given command, if it is available, otherwise C<undef> is returned.

=cut

sub which
{
  my(undef, $command) = @_;
  require IPC::Cmd;
  IPC::Cmd::can_run($command);
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
  push @diag, "cc                : ". $self->cc;
  push @diag, "cxx               : ". (eval { $self->cxx } || '???' );
  push @diag, "for               : ". (eval { $self->for } || '???' );
  push @diag, "ld                : ". $self->ld;
  push @diag, "cflags            : ". $self->cflags;
  push @diag, "ldflags           : ". $self->ldflags;
  push @diag, "extra system inc  : ". $self->extra_system_inc;
  push @diag, "extra system lib  : ". $self->extra_system_lib;
  push @diag, "object suffix     : ". join(", ", $self->object_suffix);
  push @diag, "library prefix    : ". join(", ", $self->library_prefix);
  push @diag, "library suffix    : ". join(", ", $self->library_suffix);
  push @diag, "cc mm works       : ". $self->cc_mm_works;

  join "\n", @diag;
}

1;
