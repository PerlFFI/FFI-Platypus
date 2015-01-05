use strict;
use warnings;
use Test::More tests => 2;
use FFI::Platypus;
use FFI::CheckLib;

subtest 'built in type' => sub {
  plan tests => 4;
  my $ffi = FFI::Platypus->new;  
  $ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 'libtest');
  my $function = eval { $ffi->function('f0', [ 'uint8' ] => 'uint8') };
  is $@, '', 'ffi.function(f0, [uint8] => uint8)';
  isa_ok $function, 'FFI::Platypus::Function';
  is $function->call(22), 22, 'function.call(22) = 22';
  is $function->(22), 22, 'function.(22) = 22';
};

subtest 'custom type' => sub {
  plan tests => 4;
  my $ffi = FFI::Platypus->new;
  $ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 'libtest');
  $ffi->type('uint8' => 'my_int_8');
  my $function = eval { $ffi->function('f0', [ 'my_int_8' ] => 'my_int_8') };
  is $@, '', 'ffi.function(f0, [my_int_8] => my_int_8)';
  isa_ok $function, 'FFI::Platypus::Function';
  is $function->call(22), 22, 'function.call(22) = 22';
  is $function->(22), 22, 'function.(22) = 22';
}
