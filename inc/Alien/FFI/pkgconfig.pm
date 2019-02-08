package Alien::FFI::pkgconfig;

use strict;
use warnings;
use Config;
use IPC::Cmd ();
use Capture::Tiny qw( capture );

our $VERBOSE = $^O eq 'MSWin32' ? 1 : !!$ENV{V};

sub pkg_config_exe
{
  foreach my $cmd ($ENV{PKG_CONFIG}, qw( pkgconf pkg-config ))
  {
    next unless defined $cmd;
    return $cmd if IPC::Cmd::can_run($cmd);
  }
  return;
}

sub _pkg_config
{
  my(@args) = @_;
  my $cmd = pkg_config_exe;
  if(defined $cmd)
  {
    my @cmd = ($cmd, @args);
    print "+@cmd\n" if $VERBOSE;
    my($out, $err, $ret) = capture {
      system @cmd;
      $?;
    };
    chomp $out; chomp $err;
    print "[out]\n$out\n" if $out ne '' && $VERBOSE;
    print "[err]\n$err\n" if $err ne '' && $VERBOSE;
    die "command failed" if $ret;
    my $value = $out;
    $value;
  }
  else
  {
    print "no pkg-config.\n" if $VERBOSE;
    return;
  }
}

my $version;
my $exists;
my $cflags;
my $libs;

sub exists
{
  return $exists if defined $exists;
  return $exists = '' unless pkg_config_exe;
  $exists = !!eval { _pkg_config('--exists', 'libffi'); 1 };
}

sub version
{
  unless(defined $version)
  {
    $version = _pkg_config('--modversion', 'libffi');
  }

  $version;
}

sub config
{
  my($class, $key) = @_;
  die "unimplemented for $key" unless $key eq 'version';
  $class->version;
}

sub cflags
{
  unless(defined $cflags)
  {
    $cflags = _pkg_config('--cflags', 'libffi');
  }

  $cflags;
}

sub libs
{
  unless(defined $libs)
  {
    $libs = _pkg_config('--libs', 'libffi');
  }

  $libs;
}

sub install_type {'system'}

sub runtime_prop { return {} }

1;

