use strict;
use warnings;
use Test::More;

BEGIN {
  plan skip_all => 'test requires FFI::TinyCC 0.11' unless eval q{ use FFI::TinyCC 0.11; 1 };
}

plan tests => 1;

my $c_code = <<EOF;
extern int foo(int arg);
int
bar()
{
  return foo(3)*2;
}
EOF

subtest 'FFI::Platypus' => sub {
  plan tests => 4;

  use FFI::Platypus;
  use FFI::Platypus::Declare;
  use FFI::Platypus::Memory qw( cast );

  my $tcc = FFI::TinyCC->new;
  my $ffi = FFI::Platypus->new;
  
  my $closure = $ffi->closure(sub { $_[0] + $_[0] });
  my $pointer = cast '(int)->int' => 'opaque', $closure;
  note sprintf("address = 0x%x", $pointer);
  
  eval { $tcc->add_symbol('foo' => $pointer) };
  is $@, '', 'tcc.add_symbol';
  
  eval { $tcc->compile_string($c_code)};
  is $@, '', 'tcc.compile_string';
  
  my $f = eval { $ffi->function($tcc->get_symbol('bar') => [] => 'int') };
  is $@, '', 'ffi.function';
 
  is $f->call, (3+3)*2, 'f.call';
};

