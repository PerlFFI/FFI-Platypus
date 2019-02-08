package Alien::FFI::PkgConfigPP;

use strict;
use warnings;

our $VERBOSE = !!$ENV{V};

my $pkg;

sub _pkg
{
  $pkg ||= eval {
    require PkgConfig;
    my $pkg = PkgConfig->find('libffi');
    die $pkg->errmsg if $pkg->errmsg;
    $pkg;
  };
  die "libffi not found" unless $pkg;
  $pkg;
}

sub exists
{
  !!eval { _pkg };
}

sub version {
  _pkg->pkg_version;
}

sub config
{
  my($class, $key) = @_;
  die "unimplemented for $key" unless $key eq 'version';
  $class->version;
}

sub cflags
{
  _pkg->get_cflags;
}

sub libs
{
  _pkg->get_ldflags;
}

sub install_type { return 'system' }

sub runtime_prop { return {} }

1;

