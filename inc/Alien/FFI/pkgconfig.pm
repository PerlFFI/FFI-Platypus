package Alien::FFI::pkgconfig;

use strict;
use warnings;
use Config;
use IPC::Cmd ();

sub _pkg_config_exe
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
  my $cmd = _pkg_config_exe;
  if(defined $cmd)
  {
    my @cmd = ($cmd, @args);
    print "+@cmd\n";
    my $value = `@cmd`;
    die "command failed" if $?;
    chomp $value;
    $value;
  }
  else
  {
    print "no pkg-config.\n";
    return;
  }
}

my $cflags;
my $libs;

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

1;

