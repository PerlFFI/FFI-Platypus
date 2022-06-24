use strict;
use warnings;
use FFI::TinyCC;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new( api => 2 );
my $tcc = FFI::TinyCC->new;

$tcc->compile_string(q{
  int
  add(int a, int b)
  {
    return a+b;
  }
});

my $address = $tcc->get_symbol('add');

$ffi->attach( [ $address => 'add' ] => ['int','int'] => 'int' );

print add(1,2), "\n";


