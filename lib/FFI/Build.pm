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

# ABSTRACT: Build shared libraries for use with FFI::Platypus
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new

=cut

sub _native_name
{
  my($self, $name) = @_;
  join '', $self->platform->library_prefix, $name, $self->platform->library_suffix;
}

sub new
{
  my($class, $name, %args) = @_;

  Carp::croak "name is required" unless defined $name;

  my $self = bless {
    source => [],
    cflags => [],
    libs   => [],
    alien  => [],
  }, $class;
  
  my $platform  = $self->{platform}  = $args{platform} || FFI::Build::Platform->default;
  my $file      = $self->{file}      = $args{file} || FFI::Build::File::Library->new([$args{dir} || '.', $self->_native_name($name)], platform => $self->platform);
  my $buildname = $self->{buildname} = $args{buildname} || '_build';
  my $verbose   = $self->{verbose}   = $args{verbose};

  if(defined $args{cflags})
  {
    push @{ $self->{cflags} }, ref $args{cflags} ? @{ $args{cflags} } : $self->platform->shellwords($args{cflags});
  }
  
  if(defined $args{libs})
  {
    push @{ $self->{libs} }, ref $args{libs} ? @{ $args{libs} } : $self->platform->shellwords($args{libs});
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
      push @{ $self->{cflags} }, $self->platform->shellwords($alien->cflags);
      push @{ $self->{libs} }, $self->platform->shellwords($alien->libs);
    }
  }
  
  $self->source(ref $args{source} ? @{ $args{source} } : ($args{source})) if $args{source};

  $self;
}

=head1 METHODS

=head2 dir

=head2 buildname

=head2 file

=head2 platform

=head2 verbose

=head2 cflags

=head2 libs

=head2 alien

=cut

sub buildname { shift->{buildname} }
sub file      { shift->{file}      }
sub platform  { shift->{platform}  }
sub verbose   { shift->{verbose}   }
sub cflags    { shift->{cflags}    }
sub libs      { shift->{libs}      }
sub alien     { shift->{alien}     }

=head2 source

=cut

my @file_classes;
sub _file_classes
{
  unless(@file_classes)
  {

    foreach my $inc (@INC)
    {
      push @file_classes,
        map { $_ =~ s/\.pm$//; "FFI::Build::File::$_" }
        grep !/^Base\.pm$/,
        map { File::Basename::basename($_) } 
        File::Glob::bsd_glob(
          File::Spec->catfile($inc, 'FFI', 'Build', 'File', '*.pm')
        );
    }

    # also anything already loaded, that might not be in the
    # @INC path (for testing ususally)
    push @file_classes,
      map { s/::$//; "FFI::Build::File::$_" }
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

=cut

sub source
{
  my($self, @file_spec) = @_;
  
  foreach my $file_spec (@file_spec)
  {
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
            push @{ $self->{source} }, $class->new($path, platform => $self->platform, builder => $self);
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
    while(my $next = $source->build)
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
  
  File::Path::mkpath($self->file->dirname, 0, 0755);
  
  my @cmd = (
    $ld,
    $self->platform->ldflags,
    (map { "$_" } @objects),
    $self->platform->flag_library_output($self->file->path),
    @{ $self->libs },
    $self->platform->extra_system_lib,
  );
  
  my($out, $exit) = Capture::Tiny::capture_merged(sub {
    print "+ @cmd\n";
    system @cmd;
  });
  
  if($exit || !-f $self->file->path)
  {
    print $out;
    die "error building @{[ $self->file->path ]} from @objects";
  }
  elsif($self->verbose)
  {
    print $out;
  }
  
  $self->file;
}

=head2 clean

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
