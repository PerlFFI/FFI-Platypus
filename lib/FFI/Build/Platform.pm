package FFI::Build::Platform;

use strict;
use warnings;
use 5.008004;
use Carp ();
use Text::ParseWords ();
use FFI::Temp;
use Capture::Tiny ();
use File::Spec;
use FFI::Platypus::ShareConfig;

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
  $config ||= do {
    require Config;
    \%Config::Config;
  };
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
  _self(shift)->{config}->{osname};
}

=head2 object_suffix

 my $suffix = $platform->object_suffix;

The object suffix for the platform.  On UNIX this is usually C<.o>.  On Windows this
is usually C<.obj>.

=cut

sub object_suffix
{
  _self(shift)->{config}->{obj_ext};
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
  my @suffix;
  if($osname eq 'darwin')
  {
    push @suffix, '.dylib', '.bundle';
  }
  elsif($osname =~ /^(MSWin32|msys|cygwin)$/)
  {
    push @suffix, '.dll';
  }
  else
  {
    push @suffix, '.' . $self->{config}->{dlext};
  }
  wantarray ? @suffix : $suffix[0];  ## no critic (Community::Wantarray)
}

=head2 library_prefix

 my $prefix = $platform->library_prefix;

The library prefix for the platform.  On Unix this is usually C<lib>, as in C<libfoo>.

=cut

sub library_prefix
{
  my $self = _self(shift);

  # this almost certainly requires refinement.
  if($self->osname eq 'cygwin')
  {
    return 'cyg';
  }
  elsif($self->osname eq 'msys')
  {
    return 'msys-';
  }
  elsif($self->osname eq 'MSWin32')
  {
    return '';
  }
  else
  {
    return 'lib';
  }
}

=head2 cc

 my @cc = @{ $platform->cc };

The C compiler

=cut

sub cc
{
  my $self = _self(shift);
  my $cc = $self->{config}->{cc};
  [$self->shellwords($cc)];
}

=head2 cpp

 my @cpp = @{ $platform->cpp };

The C pre-processor

=cut

sub cpp
{
  my $self = _self(shift);
  my $cpp = $self->{config}->{cpprun};
  [$self->shellwords($cpp)];
}

=head2 cxx

 my @cxx = @{ $platform->cxx };

The C++ compiler that naturally goes with the C compiler.

=cut

sub cxx
{
  my $self = _self(shift);

  my @cc = @{ $self->cc };

  if($self->{config}->{ccname} eq 'gcc')
  {
    if($cc[0] =~ /gcc$/)
    {
      my @maybe = @cc;
      $maybe[0] =~ s/gcc$/g++/;
      return \@maybe if $self->which($maybe[0]);
    }
    if($cc[0] =~ /clang/)
    {
      my @maybe = @cc;
      $maybe[0] =~ s/clang/clang++/;
      return \@maybe if $self->which($maybe[0]);
    }

    # TODO: there are probably situations, eg solaris
    # where we don't want to try c++ in the case of
    # a ccname = gcc ?
    my @maybe = qw( c++ g++ clang++ );

    foreach my $maybe (@maybe)
    {
      return [$maybe] if $self->which($maybe);
    }
  }
  elsif($self->osname eq 'MSWin32' && $self->{config}->{ccname} eq 'cl')
  {
    # TODO: see https://github.com/PerlFFI/FFI-Platypus/issues/203
    #return \@cc;
  }

  Carp::croak("unable to detect corresponding C++ compiler");
}

=head2 for

 my @for = @{ $platform->for };

The Fortran compiler that naturally goes with the C compiler.

=cut

sub for
{
  my $self = _self(shift);

  my @cc = @{ $self->cc };

  if($self->{config}->{ccname} eq 'gcc')
  {
    if($cc[0] =~ /gcc$/)
    {
      my @maybe = @cc;
      $maybe[0] =~ s/gcc$/gfortran/;
      return \@maybe if $self->which($maybe[0]);
    }

    foreach my $maybe (qw( gfortran ))
    {
      return [$maybe] if $self->which($maybe);
    }
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
  my($self) = @_;
  my $ld = $self->{config}->{ld};
  [$self->shellwords($ld)];
}

=head2 shellwords

 my @words = $platform->shellwords(@strings);

This is a wrapper around L<Text::ParseWords>'s C<shellwords> with some platform  workarounds
applied.

=cut

sub shellwords
{
  my $self = _self(shift);

  my $win = !!($self->osname eq 'MSWin32');

  grep { defined $_ } map {
    ref $_
      # if we have an array ref then it has already been shellworded
      ? @$_
      : do {
        # remove leading whitespace, confuses some older versions of shellwords
        my $str = /^\s*(.*)$/ && $1;
        # escape things on windows
        $str =~ s,\\,\\\\,g if $win;
        Text::ParseWords::shellwords($str);
      }
  } @_;

}

=head2 ccflags

 my @ccflags = @{ $platform->cflags};

The compiler flags, including those needed to compile object files that can be linked into a dynamic library.
On Linux, for example, this is usually includes C<-fPIC>.

=cut

sub ccflags
{
  my $self = _self(shift);
  my @ccflags;
  push @ccflags, $self->shellwords($self->{config}->{cccdlflags});
  push @ccflags, $self->shellwords($self->{config}->{ccflags});
  push @ccflags, $self->shellwords($self->{config}->{optimize});
  my $dist_include = eval { File::Spec->catdir(FFI::Platypus::ShareConfig::dist_dir('FFI-Platypus'), 'include') };
  push @ccflags, "-I$dist_include" unless $@;
  \@ccflags;
}

=head2 ldflags

 my @ldflags = @{ $platform->ldflags };

The linker flags needed to link object files into a dynamic library.  This is NOT the C<libs> style library
flags that specify the location and name of a library to link against, this is instead the flags that tell
the linker to generate a dynamic library.  On Linux, for example, this is usually C<-shared>.

=cut

sub ldflags
{
  my $self = _self(shift);
  my @ldflags = $self->shellwords($self->{config}->{lddlflags});
  if($self->osname eq 'cygwin')
  {
    no warnings 'qw';
    # doesn't appear to be necessary, Perl has this in lddlflags already on cygwin
    #push @ldflags, qw( -Wl,--enable-auto-import -Wl,--export-all-symbols -Wl,--enable-auto-image-base );
  }
  elsif($self->osname eq 'MSWin32' && $self->{config}->{ccname} eq 'cl')
  {
    push @ldflags, qw( -dll );
    @ldflags = grep !/^-nodefaultlib$/, @ldflags;
  }
  elsif($self->osname eq 'MSWin32')
  {
    no warnings 'qw';
    push @ldflags, qw( -Wl,--enable-auto-import -Wl,--export-all-symbols -Wl,--enable-auto-image-base );
  }
  elsif($self->osname eq 'darwin')
  {
    # we want to build a .dylib instead of a .bundle
    @ldflags = map { $_ eq '-bundle' ? '-shared' : $_ } @ldflags;
  }
  \@ldflags;
}

=head2 cc_mm_works

 my $bool = $platform->cc_mm_works;

Returns the flags that can be passed into the C compiler to compute dependencies.

=cut

sub cc_mm_works
{
  my $self = _self(shift);
  my $verbose = shift;
  $verbose ||= 0;

  unless(defined $self->{cc_mm_works})
  {
    require FFI::Build::File::C;
    my $c = FFI::Build::File::C->new(\"#include \"foo.h\"\n");
    my $dir = FFI::Temp->newdir;
    {
      open my $fh, '>', "$dir/foo.h";
      print $fh "\n";
      close $fh;
    }

    my @cmd = (
      $self->cc,
      $self->ccflags,
      "-I$dir",
      '-MM',
      $c->path,
    );

    my($out, $exit) = Capture::Tiny::capture_merged(sub {
      $self->run(@cmd);
    });

    if($verbose >= 2)
    {
      print $out;
    }
    elsif($verbose >= 1)
    {
      print "CC (checkfor -MM)\n";
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

 my @flags = $platform->flag_object_output($object_filename);

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

 my @flags = $platform->flag_library_output($library_filename);

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
  elsif($self->osname eq 'darwin')
  {
    return ('-install_name' => "\@rpath/$file", -o => $file);
  }
  else
  {
    return ('-o' => $file);
  }
}

=head2 flag_exe_output

 my @flags = $platform->flag_exe_output($library_filename);

Returns the flags that the compiler recognizes as being used to write out to a specific exe filename.

=cut

sub flag_exe_output
{
  my $self = _self(shift);
  my $file = shift;
  if($self->osname eq 'MSWin32' && $self->{config}->{ccname} eq 'cl')
  {
    my $file = File::Spec->rel2abs($file);
    return ("/Fe:$file");
  }
  else
  {
    return ('-o' => $file);
  }
}

=head2 flag_export

 my @flags = $platform->flag_export(@symbols);

Returns the flags that the linker recognizes for exporting functions.

=cut

sub flag_export
{
  my $self = _self(shift);
  return () unless $self->osname eq 'MSWin32' && $self->{config}->{ccname} eq 'cl';
  return map { "/EXPORT:$_" } @_;
}

=head2 which

 my $path = $platform->which($command);

Returns the full path of the given command, if it is available, otherwise C<undef> is returned.

=cut

sub which
{
  my(undef, $command) = @_;
  require IPC::Cmd;
  my @command = ref $command ? @$command : ($command);
  IPC::Cmd::can_run($command[0]);
}

=head2 run

 $platform->run(@command);

=cut

sub run
{
  my $self = shift;
  my @command  = map { ref $_ ? @$_ : $_ } grep { defined $_ } @_;
  print "+@command\n";
  system @command;
  $?;
}

=head2 diag

Diagnostic for the platform as a string.  This is for human consumption only, and the format
may and will change over time so do not attempt to use is programmatically.

=cut

sub _c { join ',', @_ }
sub _l { join ' ', map { ref $_ ? @$_ : $_ } @_ }

sub diag
{
  my $self = _self(shift);
  my @diag;

  push @diag, "osname            : ". _c($self->osname);
  push @diag, "cc                : ". _l($self->cc);
  push @diag, "cxx               : ". (eval { _l($self->cxx) } || '---' );
  push @diag, "for               : ". (eval { _l($self->for) } || '---' );
  push @diag, "ld                : ". _l($self->ld);
  push @diag, "ccflags           : ". _l($self->ccflags);
  push @diag, "ldflags           : ". _l($self->ldflags);
  push @diag, "object suffix     : ". _c($self->object_suffix);
  push @diag, "library prefix    : ". _c($self->library_prefix);
  push @diag, "library suffix    : ". _c($self->library_suffix);
  push @diag, "cc mm works       : ". $self->cc_mm_works;

  join "\n", @diag;
}

1;
