use strict;
use warnings;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;
$ffi->lib('./libexample.so');

$ffi->attach( [ _ZN7Example11print_helloEJvv => 'print_hello' ] => [] => 'void' );
$ffi->attach( [ _ZN7Example3addEJiii => 'add' ] => ['int', 'int'] => 'int' );

$ffi->function( gcj_start => [] => 'void' )->call;

print_hello();
print add(1,2), "\n";

$ffi->function( gcj_end => [] => 'void' )->call;
