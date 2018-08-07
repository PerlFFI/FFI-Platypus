package FFI::Build::MM;

use strict;
use warnings;
use 5.008001;
use Carp ();
use FFI::Build;
use JSON::PP ();
use File::Glob ();
use File::Basename ();

# ABSTRACT: FFI::Build installer code for ExtUtils::MakeMaker
# VERSION

sub new
{
  my($class) = @_;
  
  my $self = bless {}, $class;
  $self->load_prop;
  
  $self;
}

sub mm_args
{
  my($self, %args) = @_;
  
  if($args{DISTNAME})
  {
    my $self->{prop}->{distname} = $args{DISTNAME};
    $self->save_prop;
  }
  else
  {
    Carp::croak "DISTNAME is required";
  }

  my $build = $self->build;
  if($build)
  {
    foreach my $alien (@{ $build->alien })
    {
      next if ref $alien;
      $args{BUILD_REQUIRES}->{$alien} ||= 0;
    }
  }
  
  my $test = $self->test;
  if($test)
  {
    foreach my $alien (@{ $build->alien })
    {
      next if ref $alien;
      $args{TEST_REQUIRES}->{$alien} ||= 0;
    }
  }
  
  %args;
}

sub distname { shift->{prop}->{distname} }

sub load_builder
{
  my($self, $dir, $name, $install) = @_;
  return unless -d $dir;
  my($fbx) = File::Glob::bsd_glob("$dir/*.fbx");
  
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
  $options->{dir}      ||= $install;
  FFI::Build->new($name, %$options);
}

sub build
{
  my($self) = @_;
  $self->{build} ||= $self->load_builder('ffi', undef, "blib/lib/auto/share/dist/@{[ $self->distname ]}/lib");
}

sub test
{
  my($self) = @_;
  $self->{test} ||= $self->load_builder('t/ffi', 'test');
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
  return unless -f 'fbx.json';
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

sub mm_postamble
{
  my($self) = @_;
  
  my $postamble = '';
  
  $postamble;
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
        FFI::Build::MM->new;
      };

      no warnings 'once';
      
      *ffi_build = sub {
        my $build = $mm->()->build;
        if($build)
        {
          $build->build;
          if(-d 'ffi/include')
          {
            # TODO: copy include files into the share directory too
          }
        }
      };
      
      *ffi_build_test = sub {
        my $build = $mm->()->test;
        $build->build if $build;
      };
      
      *ffi_build_clean = sub {
        $mm->()->clean;
      };
    }
  }
}

1;
