use strict;
use warnings;
use Test::More tests => 1;
use Alien::FFI;
use FFI::Platypus;
use FFI::Platypus::ConfigData;
use Module::Build::FFI;

diag '';
diag '';
diag '';

diag "Alien::FFI version       = ", $Alien::FFI::VERSION;
diag "Alien::FFI->install_type = ", Alien::FFI->install_type;
diag "Alien::FFI->cflags       = ", Alien::FFI->cflags;
diag "Alien::FFI->libs         = ", Alien::FFI->libs;
diag "Alien::FFI->dist_dir     = ", eval { Alien::FFI->dist_dir } || 'undef';

diag '';
diag '';

diag "dlext[]=$_" for Module::Build::FFI->ffi_dlext;

my %type_map = %{ FFI::Platypus::ConfigData->config('type_map') };

my $diag = FFI::Platypus::ConfigData->config('diag');
foreach my $key (sort keys %{ $diag->{args} })
{
  diag "mb.args.$key=", $diag->{args}->{$key};
}
foreach my $key (sort keys %{ $diag->{config} })
{
  diag "config.$key=", $diag->{config}->{$key};
}

my %r;

while(my($k,$v) = each %type_map)
{
  push @{ $r{$v} }, $k;
}

diag '';
diag '';

foreach my $type (sort keys %r)
{
  diag sprintf("%-8s : %s", $type, join(', ', sort @{ $r{$type} }));
}

diag '';
diag '';

my $abi = FFI::Platypus->abis;
foreach my $key (sort keys %$abi)
{
  diag sprintf("%-20s %s", $key, $abi->{$key});
}

diag '';

pass 'good';
