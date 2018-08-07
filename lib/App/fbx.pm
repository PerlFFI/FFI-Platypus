package App::fbx;

use strict;
use warnings;
use 5.008001;
use FFI::Build::MM;
use Cwd qw( getcwd );
use File::Basename qw( basename dirname );

# ABSTRACT: Command line interface to FFI::Build
# VERSION

sub main
{
  my(undef, @ARGV) = @_;

  unless(-f 'pbx.json')
  {
    my $mm = FFI::Build::MM->new;
    $mm->mm_args( DISTNAME => basename getcwd() );
    $mm->sharedir('share');
    $mm->archdir(0);
  }

  my $mm = FFI::Build::MM->new;

  my $command = shift @ARGV;

  if(defined $command)
  {
    if($command eq 'build')
    {
      my $build = $mm->build;
      $build->build if $build;
    }
    elsif($command eq 'test')
    {
      my $build = $mm->test;
      $build->build if $build;
    }
    elsif($command eq 'clean')
    {
      $mm->clean;
    }
    else
    {
      die "unknown command: $command";
    }
  }

  0;
}

1;
