use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus;
use FFI::Platypus::ConfigData;
use Module::Build::FFI;

diag '';
diag '';
diag '';

diag "dlext[]=$_" for Module::Build::FFI->ffi_dlext;

my %type_map = %{ FFI::Platypus::ConfigData->config('type_map') };

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

pass 'good';
