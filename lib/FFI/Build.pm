package FFI::Build;

use strict;
use warnings;
use 5.008001;
use FFI::Build::File::Library;
use Carp ();
use File::Glob ();
use File::Basename ();
use List::Util 1.45 ();
use Capture::Tiny ();
use File::Path ();

# ABSTRACT: Build shared libraries for use with FFI
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus;
 use FFI::Build;
 
 my $build = FFI::Build->new(
   'frooble',
   source => 'ffi/*.c',
 );
 
 # $lib is an instance of FFI::Build::File::Library
 my $lib = $build->build;
 
 my $ffi = FFI::Platypus->new( api => 1 );
 # The filename will be platform dependant, but something like libfrooble.so or frooble.dll
 $ffi->lib($lib->path);
 
 ... # use $ffi to attach functions in ffi/*.c

=head1 DESCRIPTION

B<WARNING>: Alpha quality software, expect a somewhat unstable API until it stabilizes.  Documentation
may be missing or inaccurate.

Using libffi based L<FFI::Platypus> is a great alternative to XS for writing library bindings for Perl.
Sometimes, however, you need to bundle a little C code with your FFI module, but this has never been
that easy to use.  L<Module::Build::FFI> was an early attempt to address this use case, but it uses
the now out of fashion L<Module::Build>.

This module itself doesn't directly integrate with CPAN installers like L<ExtUtils::MakeMaker> or
L<Module::Build>, but there is a light weight layer L<FFI::Build::MM> that will allow you to easily
use this module with L<ExtUtils::MakeMaker>.  If you are using L<Dist::Zilla> as your dist builder,
then there is also L<Dist::Zilla::Plugin::FFI::Build>, which will help with the connections.

There is some functional overlap with L<ExtUtils::CBuilder>, which was in fact used by L<Module::Build::FFI>.
For this iteration I have decided not to use that module because although it will generate dynamic libraries
that can sometimes be used by L<FFI::Platypus>, it is really designed for building XS modules, and trying
to coerce it into a more general solution has proved difficult in the past.

Supported languages out of the box are C, C++ and Fortran.  In the future I plan on also supporting
other languages like Rust, and maybe Go, but the machinery for that will eventually live in
L<FFI::Build::Foreign>.

The hope is that this module will be merged into L<FFI::Platypus>, if and when this module becomes appropriately
stable.

=head1 CONSTRUCTOR

=head2 new

 my $build = FFI::Build->new($name, %options);

Create an instance of this class.  The C<$name> argument is used when computing the file name for
the library.  The actual name will be something like C<lib$name.so> or C<$name.dll>.  The following
options are supported:

=over 4

=item alien

List of Aliens to compile/link against.  L<FFI::Build> will work with any L<Alien::Base> based
alien, or modules that provide a compatible API.

=item buildname

Directory name that will be used for building intermediate files, such as object files.  This is
C<_build> by default.

=item cflags

Extra compiler flags to use.  Things like C<-I/foo/include> or C<-DFOO=1>.

=item dir

The directory where the library will be written.  This is C<.> by default.

=item file

An instance of L<FFI::Build::File::Library> to which the library will be written.  Normally not needed.

=item libs

Extra library flags to use.  Things like C<-L/foo/lib -lfoo>.

=item platform

An instance of L<FFI::Build::Platform>.  Usually you want to omit this and use the default instance.

=item source

List of source files.  You can use wildcards supported by C<bsd_glob> from L<File::Glob>.

=item verbose

By default this class does not print out the actual compiler and linker commands used in building
the library unless there is a failure.  You can alter this behavior with this option.  Set to
one of these values:

=over 4

=item zero (0)

Default, quiet unless there is a failure.

=item one (1)

Output the operation (compile, link, etc) and the file, but nothing else

=item two (2)

Output the complete commands run verbatim.

=back

=back

=cut

sub _native_name
{
  my($self, $name) = @_;
  join '', $self->platform->library_prefix, $name, scalar $self->platform->library_suffix;
}

sub new
{
  my($class, $name, %args) = @_;

  Carp::croak "name is required" unless defined $name;

  my $self = bless {
    source   => [],
    cflags_I => [],
    cflags   => [],
    libs_L   => [],
    libs     => [],
    alien    => [],
  }, $class;

  my $platform  = $self->{platform}  = $args{platform}  || FFI::Build::Platform->default;
  my $file      = $self->{file}      = $args{file}      || FFI::Build::File::Library->new([$args{dir} || '.', $self->_native_name($name)], platform => $self->platform);
  my $buildname = $self->{buildname} = $args{buildname} || '_build';
  my $verbose   = $self->{verbose}   = $args{verbose}   || 0;

  if(defined $args{cflags})
  {
    my @flags = ref $args{cflags} ? @{ $args{cflags} } : $self->platform->shellwords($args{cflags});
    push @{ $self->{cflags}   }, grep !/^-I/, @flags;
    push @{ $self->{cflags_I} }, grep  /^-I/, @flags;
  }

  if(defined $args{libs})
  {
    my @flags = ref $args{libs} ? @{ $args{libs} } : $self->platform->shellwords($args{libs});
    push @{ $self->{libs} },   grep !/^-L/, @flags;
    push @{ $self->{libs_L} }, grep  /^-L/, @flags;
  }

  if(defined $args{alien})
  {
    my @aliens = ref $args{alien} ? @{ $args{alien} } : ($args{alien});
    foreach my $alien (@aliens)
    {
      unless(eval { $alien->can('cflags') && $alien->can('libs') })
      {
        my $pm = "$alien.pm";
        $pm =~ s/::/\//g;
        require $pm;
      }
      push @{ $self->{alien} }, $alien;
      push @{ $self->{cflags}   }, grep !/^-I/, $self->platform->shellwords($alien->cflags);
      push @{ $self->{cflags_I} }, grep  /^-I/, $self->platform->shellwords($alien->cflags);
      push @{ $self->{libs}     }, grep !/^-L/, $self->platform->shellwords($alien->libs);
      push @{ $self->{libs_L}   }, grep  /^-L/, $self->platform->shellwords($alien->libs);
    }
  }

  $self->source(ref $args{source} ? @{ $args{source} } : ($args{source})) if $args{source};

  $self;
}

=head1 METHODS

=head2 dir

 my $dir = $build->dir;

Returns the directory where the library will be written.

=head2 buildname

 my $builddir = $build->builddir;

Returns the build name.  This is used in computing a directory to save intermediate files like objects.  For example,
if you specify a file like C<ffi/foo.c>, then the object file will be stored in C<ffi/_build/foo.o> by default.
C<_build> in this example (the default) is the build name.

=head2 file

 my $file = $build->file;

Returns an instance of L<FFI::Build::File::Library> corresponding to the library being built.  This is
also returned by the C<build> method below.

=head2 platform

 my $platform = $build->platform;

An instance of L<FFI::Build::Platform>, which contains information about the platform on which you are building.
The default is usually reasonable.

=head2 verbose

 my $verbose = $build->verbose;

Returns the verbose flag.

=head2 cflags

 my @cflags = @{ $build->cflags };

Returns the compiler flags.

=head2 cflags_I

 my @cflags_I = @{ $build->cflags_I };

Returns the C<-I> cflags.

=head2 libs

 my @libs = @{ $build->libs };

Returns the library flags.

=head2 libs_L

 my @libs = @{ $build->libs };

Returns the C<-L> library flags.

=head2 alien

 my @aliens = @{ $build->alien };

Returns a the list of aliens being used.

=cut

sub buildname { shift->{buildname} }
sub file      { shift->{file}      }
sub platform  { shift->{platform}  }
sub verbose   { shift->{verbose}   }
sub cflags    { shift->{cflags}    }
sub cflags_I  { shift->{cflags_I}  }
sub libs      { shift->{libs}      }
sub libs_L    { shift->{libs_L}    }
sub alien     { shift->{alien}     }

my @file_classes;
sub _file_classes
{
  unless(@file_classes)
  {

    foreach my $inc (@INC)
    {
      push @file_classes,
        map { my $f = $_; $f =~ s/\.pm$//; "FFI::Build::File::$f" }
        grep !/^Base\.pm$/,
        map { File::Basename::basename($_) }
        File::Glob::bsd_glob(
          File::Spec->catfile($inc, 'FFI', 'Build', 'File', '*.pm')
        );
    }

    # also anything already loaded, that might not be in the
    # @INC path (for testing ususally)
    push @file_classes,
      map { my $f = $_; $f =~ s/::$//; "FFI::Build::File::$f" }
      grep !/Base::/,
      grep /::$/,
      keys %{FFI::Build::File::};

    @file_classes = List::Util::uniq(@file_classes);
    foreach my $class (@file_classes)
    {
      next if(eval { $class->can('new') });
      my $pm = $class . ".pm";
      $pm =~ s/::/\//g;
      require $pm;
    }
  }
  @file_classes;
}

=head2 source

 $build->source(@files);

Add the C<@files> to the list of source files that will be used in building the library.
The format is the same as with the C<source> attribute above.

=cut

sub source
{
  my($self, @file_spec) = @_;

  foreach my $file_spec (@file_spec)
  {
    if(eval { $file_spec->isa('FFI::Build::File::Base') })
    {
      push @{ $self->{source} }, $file_spec;
      next;
    }
    if(ref $file_spec eq 'ARRAY')
    {
      my($type, $content, @args) = @$file_spec;
      my $class = "FFI::Build::File::$type";
      unless($class->can('new'))
      {
        my $pm = "FFI/Build/File/$type.pm";
        require $pm;
      }
      push @{ $self->{source} }, $class->new(
        $content,
        build    => $self,
        platform => $self->platform,
        @args
      );
      next;
    }
    my @paths = File::Glob::bsd_glob($file_spec);
path:
    foreach my $path (@paths)
    {
      foreach my $class (_file_classes)
      {
        foreach my $regex ($class->accept_suffix)
        {
          if($path =~ $regex)
          {
            push @{ $self->{source} }, $class->new($path, platform => $self->platform, build => $self);
            next path;
          }
        }
      }
      Carp::croak("Unknown file type: $path");
    }
  }

  @{ $self->{source} };
}

=head2 build

 my $lib = $build->build;

This compiles the source files and links the library.  Files that have already been compiled or linked
may be reused without recompiling/linking if the timestamps are newer than the source files.  An instance
of L<FFI::Build::File::Library> is returned which can be used to get the path to the library, which can
be feed into L<FFI::Platypus> or similar.

=cut

sub build
{
  my($self) = @_;

  my @objects;

  my $ld = $self->platform->ld;

  foreach my $source ($self->source)
  {
    $ld = $source->ld if $source->ld;
    my $output;
    while(my $next = $source->build_item)
    {
      $ld = $next->ld if $next->ld;
      $output = $source = $next;
    }
    push @objects, $output;
  }

  my $needs_rebuild = sub {
    my(@objects) = @_;
    return 1 unless -f $self->file->path;
    my $target_time = [stat $self->file->path]->[9];
    foreach my $object (@objects)
    {
      my $object_time = [stat "$object"]->[9];
      return 1 if $object_time > $target_time;
    }
    return 0;
  };

  return $self->file unless $needs_rebuild->(@objects);

  File::Path::mkpath($self->file->dirname, 0, oct(755));

  my @cmd = (
    $ld,
    $self->libs_L,
    $self->platform->ldflags,
    (map { "$_" } @objects),
    $self->libs,
    $self->platform->flag_library_output($self->file->path),
  );

  my($out, $exit) = Capture::Tiny::capture_merged(sub {
    $self->platform->run(@cmd);
  });

  if($exit || !-f $self->file->path)
  {
    print $out;
    die "error building @{[ $self->file->path ]} from @objects";
  }
  elsif($self->verbose >= 2)
  {
    print $out;
  }
  elsif($self->verbose >= 1)
  {
    print "LD @{[ $self->file->path ]}\n";
  }

  $self->file;
}

=head2 clean

 $build->clean;

Removes the library and intermediate files.

=cut

sub clean
{
  my($self) = @_;
  my $dll = $self->file->path;
  unlink $dll if -f $dll;
  foreach my $source ($self->source)
  {
    my $dir = File::Spec->catdir($source->dirname, $self->buildname);
    if(-d $dir)
    {
      unlink $_ for File::Glob::bsd_glob("$dir/*");
      rmdir $dir;
    }
  }
}

1;
