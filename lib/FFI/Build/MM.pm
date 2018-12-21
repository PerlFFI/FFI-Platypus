package FFI::Build::MM;

use strict;
use warnings;
use 5.008001;
use Carp ();
use FFI::Build;
use JSON::PP ();
use File::Glob ();
use File::Basename ();
use File::Path ();
use File::Copy ();

# ABSTRACT: FFI::Build installer code for ExtUtils::MakeMaker
# VERSION

=head1 SYNOPSIS

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use FFI::Build::MM;
 
 my $fbmm = Alien::Build::MM->new;
 
 WriteMakefile($fbmm->mm_args(
   ABSTRACT     => 'My FFI extension',
   DISTNAME     => 'Foo-Bar-Baz-FFI',
   NAME         => 'Foo::Bar::Baz::FFI',
   VERSION_FROM => 'lib/Foo/Bar/Baz/FFI.pm',
   ...
 ));
 
 sub MY::postamble {
   $fbmm->mm_postamble;
 }

Then put the C, C++ or Fortran files in C<./ffi> for your runtime library
and C<./t/ffi> for your test time library.

=head1 DESCRIPTION

This module provides a thin layer between L<FFI::Build> and L<ExtUtils::MakeMaker>.
Its interface is influenced by the design of L<Alien::Build::MM>.  The idea is that
for your distribution you throw some C, C++ or Fortran source files into a directory
called C<ffi> and these files will be compiled and linked into a library that can
be used by your module.  There is a control file C<ffi/*.fbx> which can be used to
control the compiler and linker options.  (options passed directly into L<FFI::Build>).
The interface for this file is still under development.

=head1 CONSTRUCTOR

=head2 new

 my $fbmm = FFI::Build::MM->new;

Create a new instance of L<FFI::Build::MM>.

=cut

sub new
{
  my($class) = @_;
  
  my $self = bless {}, $class;
  $self->load_prop;
  
  $self;
}

=head1 METHODS

=head2 mm_args

 my %new_args = $fbmm->mm_args(%old_args);

This method does two things:

=over 4

=item reads the arguments to determine sensible defaults (library name, install location, etc).

=item adjusts the arguments as necessary and returns an updated set of arguments.

=back

=cut

sub mm_args
{
  my($self, %args) = @_;
  
  if($args{DISTNAME})
  {
    $self->{prop}->{distname} ||= $args{DISTNAME};
    $self->{prop}->{share}    ||= "blib/lib/auto/share/dist/@{[ $self->distname ]}";
    $self->{prop}->{arch}     ||= "blib/arch/auto/@{[ join '/', split /-/, $self->distname ]}";
    $self->save_prop;
  }
  else
  {
    Carp::croak "DISTNAME is required";
  }

  # TODO: set configure requires of ExtUtils::MakeMaker to 7.24

  if(my $build = $self->build)
  {
    foreach my $alien (@{ $build->alien })
    {
      next if ref $alien;
      $args{BUILD_REQUIRES}->{$alien} ||= 0;
    }
  }
  
  if(my $test = $self->test)
  {
    foreach my $alien (@{ $test->alien })
    {
      next if ref $alien;
      $args{TEST_REQUIRES}->{$alien} ||= 0;
    }
  }
  
  %args;
}

sub distname { shift->{prop}->{distname} }

sub sharedir
{
  my($self, $new) = @_;
  
  if(defined $new)
  {
    $self->{prop}->{share} = $new;
    $self->save_prop;
  }
  
  $self->{prop}->{share};
}

sub archdir
{
  my($self, $new) = @_;
  
  if(defined $new)
  {
    $self->{prop}->{arch} = $new;
    $self->save_prop;
  }
  
  $self->{prop}->{arch};
}

sub load_build
{
  my($self, $dir, $name, $install) = @_;
  return unless -d $dir;
  my($fbx) = File::Glob::bsd_glob("./$dir/*.fbx");
  
  my $options;
  my $platform = FFI::Build::Platform->default;
  
  if($fbx)
  {
    $name = File::Basename::basename($fbx);
    $name =~ s/\.fbx$//;
    $options = do {
      package FFI::Build::MM::FBX;
      our $DIR      = $dir;
      our $PLATFORM = $platform;
      do $fbx;
    };
  }
  else
  {
    $name ||= $self->distname;
    $options = {
      source => ["$dir/*.c", "$dir/*.cxx", "$dir/*.cpp"],
    };
  }
  
  $options->{platform} ||= $platform;
  $options->{dir}      ||= ref $install ? $install->($options) : $install;
  $options->{verbose}  = 1 unless defined $options->{verbose};
  FFI::Build->new($name, %$options);
}

sub build
{
  my($self) = @_;
  $self->{build} ||= $self->load_build('ffi', undef, $self->sharedir . "/lib");
}

sub test
{
  my($self) = @_;
  $self->{test} ||= $self->load_build('t/ffi', 'test', sub {
    my($opt) = @_;
    my $buildname = $opt->{buildname} || '_build';
    "t/ffi/$buildname";
  });
}

sub save_prop
{
  my($self) = @_;
  open my $fh, '>', 'fbx.json';
  print $fh JSON::PP::encode_json($self->{prop});
  close $fh;
}

sub load_prop
{
  my($self) = @_;
  unless(-f 'fbx.json')
  {
    $self->{prop} = {};
    return;
  }
  open my $fh, '<', 'fbx.json';
  $self->{prop} = JSON::PP::decode_json(do { local $/; <$fh> });
  close $fh;
}

sub clean
{
  my($self) = @_;
  foreach my $stage (qw( build test ))
  {
    my $build = $self->$stage;
    $build->clean if $build;
  }
  unlink 'fbx.json' if -f 'fbx.json';
}

=head2 mm_postamble

 my $postamble = $fbmm->mm_postamble;

This returns the Makefile postamble used by L<ExtUtils::MakeMaker>.  The synopsis above for
how to invoke it properly.  It adds the following Make targets:

=over 4

=item fbx_build

build the main runtime library in C<./ffi>.

=item fbx_test

Build the test library in C<./t/ffi>.

=item fbx_clean

Clean any runtime or test libraries already built.

=back

Normally you do not need to build these targets manually, they will be built automatically
at the appropriate stage.

=cut

sub mm_postamble
{
  my($self) = @_;
  
  my $postamble = '';

  # make fbx_realclean ; make clean
  $postamble .= "realclean :: fbx_clean\n" .
                "\n" .
                "fbx_clean:\n" .
                "\t\$(FULLPERL) -MFFI::Build::MM=cmd -e fbx_clean\n\n";
  
  # make fbx_build; make
  $postamble .= "pure_all :: fbx_build\n" .
                "\n" .
                "fbx_build:\n" .
                "\t\$(FULLPERL) -MFFI::Build::MM=cmd -e fbx_build\n\n";

  # make fbx_test; make test
  $postamble .= "subdirs-test_dynamic subdirs-test_static subdirs-test :: fbx_test\n" .
                "\n" .
                "fbx_test:\n" .
                "\t\$(FULLPERL) -MFFI::Build::MM=cmd -e fbx_test\n\n";
  
  $postamble;
}

sub action_build
{
  my($self) = @_;
  my $build = $self->build;
  if($build)
  {
    my $lib = $build->build;
    if($self->archdir)
    {
      File::Path::mkpath($self->archdir, 0, 0755);
      my $archfile = File::Spec->catfile($self->archdir, File::Basename::basename($self->archdir) . ".txt");
      open my $fh, '>', $archfile;
      my $lib_path = $lib->path;
      $lib_path =~ s/^blib\/lib\///;
      print $fh "FFI::Build\@$lib_path\n";
      close $fh;
    }
  }
  return;
}

sub action_test
{
  my($self) = @_;
  my $build = $self->test;
  $build->build if $build;
}

sub action_clean
{
  my($self) = @_;
  my $build = $self->clean;
  ();
}

sub import
{
  my(undef, @args) = @_;
  foreach my $arg (@args)
  {
    if($arg eq 'cmd')
    {
      package main;
      
      my $mm = sub {
        my($action) = @_;
        my $build = FFI::Build::MM->new;
        $build->$action;
      };

      no warnings 'once';
      
      *fbx_build = sub {
        $mm->('action_build');
      };
      
      *fbx_test = sub {
        $mm->('action_test');
      };
      
      *fbx_clean = sub {
        $mm->('action_clean');
      };
    }
  }
}

1;
