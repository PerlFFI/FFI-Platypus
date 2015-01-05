use strict;
use warnings;
use Test::More tests => 3;
use FFI::Platypus;
use FFI::CheckLib qw( find_lib );

my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 'libtest');

my $address = $ffi->find_symbol('f0');
my $uint8   = FFI::Platypus::Type->new('uint8');

my $function = eval { FFI::Platypus::Function->new($ffi, $address, $uint8, $uint8) };
is $@, '', 'FFI::Platypus::Function->new';
isa_ok $function, 'FFI::Platypus::Function';

is $function->call(22), 22, 'function.call(22) = 22';
