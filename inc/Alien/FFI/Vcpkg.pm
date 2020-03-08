package Alien::FFI::Vcpkg;

use strict;
use warnings;

my $pkg;

sub vcpkg
{
  $DB::single = 1;
  $pkg ||= do {
    require Win32::Vcpkg::List;
    Win32::Vcpkg::List->new->search('libffi');
  };
}

sub exists
{
  !!vcpkg();
}

sub version
{
  vcpkg->version;
}

sub config
{
  my($class, $key) = @_;
  die "unimplemented for $key" unless $key eq 'version';
  $class->version;
}

sub cflags
{
  scalar vcpkg->cflags;
}

sub libs
{
  scalar vcpkg->libs;
}

sub install_type { return 'system' }

sub runtime_prop { return {} }

1;

