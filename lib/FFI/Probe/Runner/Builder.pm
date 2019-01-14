package FFI::Probe::Runner::Builder;

use strict;
use warnings;
use Config;
use Capture::Tiny qw( capture_merged );
use Text::ParseWords ();

# ABSTRACT: Probe runner builder for FFI
# VERSION

=head1 SYNOPSIS

 use FFI::Probe::Runner::Builder;
 my $builder = FFI::Probe::Runner::Builder->new
   dir => "/foo/bar",
 );
 my $exe = $builder->build;

=head1 DESCRIPTION

This is a builder class for the FFI probe runner.  It is mostly only of
interest if you are hacking on L<FFI::Platypus> itself.

The interface may and will change over time without notice.  Use in
external dependencies at your own peril.

=head1 CONSTRUCTORS

=head2 new

 my $builder = FFI::Probe::Runner::Builder->new(%args);

Create a new instance.

=over 4

=item dir

The root directory for where to place the probe runner files.
Will be created if it doesn't already exist.  The default 
makes sense for when L<FFI::Platypus> is being built.

=back

=cut

sub new
{
  my($class, %args) = @_;

  $args{dir} ||= 'blib/lib/auto/share/dist/FFI-Platypus/probe';

  my $self = bless {
    dir => $args{dir},
  }, $class;
  $self;
}

=head1 METHODS

=head2 dir

 my $dir = $builder->dir(@subdirs);

Returns a subdirectory from the builder root.  Directory
will be created if it doesn't already exist.

=cut

sub dir
{
  my($self, @subdirs) = @_;
  my $dir = $self->{dir};

  if(@subdirs)
  {
    require File::Spec;
    $dir = File::Spec->catdir($dir, @subdirs);
  }

  unless(-d $dir)
  {
    require File::Path;
    File::Path::mkpath($dir, 0, 0755);
  }
  $dir;
}

=head2 file

 my $file = $builder->file(@subdirs, $filename);

Returns a file in a subdirectory from the builder root.
Directory will be created if it doesn't already exist.
File will not be created.

=cut

sub file
{
  my($self, @sub) = @_;
  @sub >= 1 or die 'usage: $builder->file([@subdirs], $filename)';
  my $filename  = pop @sub;
  require File::Spec;
  File::Spec->catfile($self->dir(@sub), $filename);
}

my $source;

=head2 source

 my $source = $builder->source;

The C source for the probe runner.

=cut

sub source
{
  unless($source)
  {
    local $/;
    $source = <DATA>;
  }

  $source;
}

=head2 extract

 $builder->extract;

Extract the source for the probe runner.

=cut

sub extract
{
  my($self) = @_;

  # the source src/dlrun.c
  {
    print "x src/dlrun.c\n";
    my $fh;
    my $fn = $self->file('src', 'dlrun.c');
    my $source = $self->source;
    open $fh, '>', $fn or die "unable to write $fn $!";
    print $fh $source;
    close $fh;
  }

  # the bin directory bin
  {
    print "x bin/\n";
    $self->dir('bin');
  }
  
}

our $VERBOSE;

=head2 run

 $builder->run(@command);

Runs the given command.

=cut

sub run
{
  my($self, $type, @cmd) = @_;
  my($out, $ret) = capture_merged {
    print "+ @cmd\n";
    print "cmd=$_\n" for @cmd;
    system @cmd;
    $?;
  };
  if($ret)
  {
    print STDERR $out;
    die "$type failed";
  }
  print $out if $VERBOSE;
  $out;
}

=head2 build

 my $exe = $builder->build;

Builds the probe runner.  Returns the path to the executable.

=cut

sub _shellwords
{
  my($string) = @_;
  $string =~ s/^\s+//;
  grep { defined $_ } Text::ParseWords::shellwords($string);
}

sub build
{
  my($self) = @_;
  $self->extract;

  my $cfn = $self->file('src', 'dlrun.c');
  my $ofn = $self->file('src', "dlrun$Config{obj_ext}");
  my $xfn = $self->file('bin', "dlrun$Config{exe_ext}");

  # compile
  print "c src/dlrun.c\n";
  $self->run(compile => _shellwords($Config{cc}), _shellwords($Config{ccflags}), '-c', '-o' => $ofn, $cfn);

  # link
  print "l src/dlrun$Config{obj_ext}\n";
  $self->run(link => _shellwords($Config{ld}), _shellwords($Config{ldflags}), '-o' => $xfn, $ofn, _shellwords($Config{perllibs}));

  # verify
  print "v bin/dlrun$Config{exe_ext}\n";
  my $out = $self->run(verify => $xfn, 'verify', 'self');
  if($out !~ /dlrun verify self ok/)
  {
    print $out;
    die "verify failed string match";
  }

  # remove object
  print "u src/dlrun$Config{obj_ext}\n";
  unlink $ofn;

  $xfn;
}

1;

__DATA__

#if defined __CYGWIN__
#include <dlfcn.h>
#elif defined _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#if defined __CYGWIN__
typedef void * dlib;
#elif defined _WIN32

#define RTLD_LAZY 0
typedef HMODULE dlib;

dlib
dlopen(const char *filename, int flags)
{
  (void)flags;
  return LoadLibrary(filename);
}

void *
dlsym(dlib handle, const char *symbol_name)
{
  return GetProcAddress(handle, symbol_name);
}

int
dlclose(dlib handle)
{
  FreeLibrary(handle);
  return 0;
}

const char *
dlerror()
{
  return "an error";
}

#else
typedef void * dlib;
#endif

int
main(int argc, char **argv)
{
  char *filename;
  int flags;
  int (*dlmain)(int, char **);
  char **dlargv;
  dlib handle;
  int n;
  int ret;
  
  if(argc < 3)
  {
    fprintf(stderr, "usage: %s dlfilename dlflags [ ... ]\n", argv[0]);
    return 1;
  }

  if(!strcmp(argv[1], "verify") && !strcmp(argv[2], "self"))
  {
    printf("dlrun verify self ok\n");
    return 0;
  }

  dlargv = malloc(sizeof(char*)*(argc-2));
  dlargv[0] = argv[0];
  filename = argv[1];
  flags = !strcmp(argv[2], "-") ? RTLD_LAZY : atoi(argv[2]);
  for(n=3; n<argc; n++)
    dlargv[n-2] = argv[n];

  handle = dlopen(filename, flags);

  if(handle == NULL)
  {
    fprintf(stderr, "error loading %s (%d|%s): %s", filename, flags, argv[2], dlerror());
    return 1;
  }

  dlmain = dlsym(handle, "dlmain");

  if(dlmain == NULL)
  {
    printf(stderr, "no dlmain symbol");
    return 1;
  }

  ret = dlmain(argc-2, dlargv);

  dlclose(handle);

  return ret;
}
