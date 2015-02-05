use strict;
use warnings;
use Test::More tests => 2;

my $ffi = FFI::Platypus->new;

do {
  package
    Foo1;
  
  use FFI::Platypus::Record;
  
  record_layout(
    uint8 => 'first',
    uint32 => 'second',
  );

};

subtest 'integer accessor' => sub {

  my $foo = Foo1->new( first => 1, second => 2 );
  isa_ok $foo, 'Foo1';
  
  my $size = $foo->_ffi_record_size;
  like $size, qr{^[0-9]+$}, "foo._record_size = $size";

  is $foo->first,  1, 'foo.first   = 1';
  is $foo->second, 2, 'foo.second  = 2';

  $foo->first(22);
  is $foo->first, 22, 'foo.first   = 22';
  
  $foo->second(42);
  is $foo->second, 42, 'foo.second = 42';

};

do {
  package
    Color;
  
  use FFI::Platypus;
  use FFI::Platypus::Record;
  
  my $ffi = FFI::Platypus->new;
  $ffi->find_lib(lib => 'test', symbol => 'f0', libpath => 'libtest');
  
  record_layout($ffi, qw(
    uint8 red
    uint8 green
    uint8 blue
  ));
  
  $ffi->type('record(Color)' => 'Color');
  $ffi->attach( [ color_get_red   => 'get_red'   ] => [ 'Color' ] => 'int' );
  $ffi->attach( [ color_get_green => 'get_green' ] => [ 'Color' ] => 'int' );
  $ffi->attach( [ color_get_blue  => 'get_blue'  ] => [ 'Color' ] => 'int' );
};

subtest 'values match in C' => sub {

  my $color = Color->new(
    red   => 50,
    green => 100,
    blue  => 150,
  );
  
  isa_ok $color, 'Color';
  
  is $color->get_red,    50, "color.get_red   =  50";
  is $color->get_green, 100, "color.get_green = 100";
  is $color->get_blue,  150, "color.get_blue  = 150";
  
};
