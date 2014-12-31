use strict;
use warnings;
use Test::More tests => 2;
use FFI::Platypus;
use FFI::CheckLib qw( find_lib );

my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 'libtest');

my $address = $ffi->find_symbol('f0');
my $uint8   = FFI::Platypus::type->new('uint8');

my $function = eval { FFI::Platypus::function->new($ffi, $address, $uint8, $uint8) };
is $@, '', 'FFI::Platypus::function->new';
isa_ok $function, 'FFI::Platypus::function';
