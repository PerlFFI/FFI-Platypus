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
    $self->{prop}->{distname} ||= $args{DISTNAME};
    $self->{prop}->{share}    ||= "blib/lib/auto/share/dist/@{[ $self->distname ]}";
    $self->{prop}->{arch}     ||= "blib/arch/auto/@{[ join '/', split /-/, $self->distname ]}";
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

sub load_builder
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
  $self->{build} ||= $self->load_builder('ffi', undef, $self->sharedir . "/lib");
}

sub test
{
  my($self) = @_;
  $self->{test} ||= $self->load_builder('t/ffi', 'test', sub {
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
      
      *fbx_build = sub {
        my $mm = $mm->();
        my $build = $mm->build;
        if($build)
        {
          $build->build;
          if(-d 'ffi/include')
          {
            File::Path::mkpath($mm->sharedir . "/include", 0, 0755);
            foreach my $h (File::Glob::bsd_glob('ffi/include/*.h'))
            {
              File::Copy::cp($h, $build->sharedir . "/include");
            }
          }
          if($mm->archdir)
          {
            File::Path::mkpath($mm->archdir, 0, 0755);
            my $archfile = File::Spec->catfile($mm->archdir, File::Basename::basename($mm->archdir) . ".txt");
            open my $fh, '>', $archfile;
            print $fh "FFI::Build\@@{[ $mm->distname ]}\n";
            close $fh;
          }
        }
        ();
      };
      
      *fbx_test = sub {
        my $build = $mm->()->test;
        $build->build if $build;
        ();
      };
      
      *fbx_clean = sub {
        $mm->()->clean;
        ();
      };
    }
  }
}

1;
