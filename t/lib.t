use strict;
use warnings;
use Test::More tests => 4;
use FindBin ();
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'testlib');
use FFI::TestLib;
use FFI::Platypus qw( ffi_lib );

my $config = FFI::TestLib->config;

my $clib = ffi_lib undef;
isa_ok $clib, 'FFI::Platypus::Lib';
is $clib->path_name, undef, 'clib.path_name = undef';

my $tlib = ffi_lib $config->{lib};
isa_ok $tlib, 'FFI::Platypus::Lib';
is $tlib->path_name, $config->{lib}, 'tlib.path_name = ' . $config->{lib};
