package App::fbx;

use strict;
use warnings;
use 5.008001;
use FFI::Build::MM;
use Cwd qw( getcwd );
use File::Basename qw( basename dirname );

# ABSTRACT: Command line interface to FFI::Build
# VERSION

=head1 SYNOPSIS

Create a script named C<fbx>:

 #!/usr/bin/env perl
 use App::fbx;
 exit App::fbx->main(@ARGV);

=head1 DESCRIPTION

This module provides a command line interface to L<FFI::Build::MM>,
which allows you to build libraries for a distribution in a development
environment without invoking L<ExtUtils::MakeMaker> or L<Dist::Zilla>.

At the moment a script invoking this module is not provided, but it may
be added if/when this module is spun off from the rest of L<FFI::Build>.

=head1 COMMANDS

=head2 fbx all

 ./fbx all

Build the library in C<./ffi> and C<./t/ffi>.

=head2 fbx build

 ./fbx build

Builds the library in C<./ffi>.

=head2 fbx test

 ./fbx test

Builds the library in C<./t/ffi>.

=head2 fbx clean

 ./fbx clean

Remove the libraries and intermediate files from C<./ffi> and C<./t/ffi>.

=cut

sub main
{
  my(undef, @ARGV) = @_;

  unless(-f 'fbx.json')
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
    elsif($command eq 'all')
    {
      my $build = $mm->build;
      $build->build if $build;
      undef $mm;
      $mm = FFI::Build::MM->new;
      $build = $mm->test;
      $build->build if $build;
    }
    else
    {
      die "unknown command: $command";
    }
  }

  0;
}

1;
