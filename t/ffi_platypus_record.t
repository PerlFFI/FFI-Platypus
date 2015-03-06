use strict;
use warnings;
use FFI::Platypus::Memory qw( malloc free );
use Test::More tests => 8;

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
  plan tests => 8;

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

  $foo = Foo1->new( { first => 3, second => 4 } );
  
  is $foo->first,  3, 'foo.first   = 3';
  is $foo->second, 4, 'foo.second  = 4';

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
  plan tests => 4;

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

do {
  package
    Foo2;

  use FFI::Platypus::Record;
  
  record_layout(qw(
    char     :
    uint64_t uint64
    char     :
    uint32_t uint32
    char     :
    uint16_t uint16
    char     :
    uint8_t  uint8

    char     :
    int64_t  sint64
    char     :
    int32_t  sint32
    char     :
    int16_t  sint16
    char     :
    int8_t   sint8

    char     :
    float    float
    char     :
    double   double 

    char     :
    opaque   opaque
  ));
  
  my $ffi = FFI::Platypus->new;
  $ffi->find_lib(lib => 'test', symbol => 'f0', libpath => 'libtest');
  
  $ffi->attach(["align_get_$_" => "get_$_"] => [ 'record(Foo2)' ] => $_)
    for qw( uint8 sint8 uint16 sint16 uint32 sint32 uint64 sint64 float double opaque );
};

subtest 'complex alignment' => sub {
  plan tests => 15;
  
  my $foo = Foo2->new;
  isa_ok $foo, 'Foo2';

  $foo->uint64(512);
  is $foo->get_uint64, 512, "uint64 = 512";
  
  $foo->sint64(-512);
  is $foo->get_sint64, -512, "sint64 = -512";

  $foo->uint32(1024);
  is $foo->get_uint32, 1024, "uint32 = 1024";
  
  $foo->sint32(-1024);
  is $foo->get_sint32, -1024, "sint32 = -1024";

  $foo->uint16(2048);
  is $foo->get_uint16, 2048, "uint16 = 2048";
  
  $foo->sint16(-2048);
  is $foo->get_sint16, -2048, "sint16 = -2048";

  $foo->uint8(48);
  is $foo->get_uint8, 48, "uint8 = 48";
  
  $foo->sint8(-48);
  is $foo->get_sint8, -48, "sint8 = -48";

  $foo->float(1.5);
  is $foo->get_float, 1.5, "float = 1.5";

  $foo->double(-1.5);
  is $foo->get_double, -1.5, "double = -1.5";

  my $ptr = malloc 32;
  
  $foo->opaque($ptr);
  is $foo->get_opaque, $ptr, "get_opaque = $ptr";
  is $foo->opaque, $ptr, "opaque = $ptr";

  $foo->opaque(undef);
  is $foo->get_opaque, undef,  "get_opaque = undef";
  is $foo->opaque, undef,  "opaque = undef";
  
  free $ptr;
};

subtest 'same name' => sub {
  plan tests => 1;

  eval {
    package
      Foo3;
      
    use FFI::Platypus::Record;
    
    record_layout
      int => 'foo',
      int => 'foo',
    ;
  };
  
  isnt $@, '', 'two members of the same name not allowed';
  note $@ if $@;
};

do {
  package
    Foo4;

  use FFI::Platypus::Record;
  
  record_layout(qw(
    char        :
    uint64_t[3] uint64
    char        :
    uint32_t[3] uint32
    char        :
    uint16_t[3] uint16
    char        :
    uint8_t[3]  uint8

    char        :
    int64_t[3]  sint64
    char        :
    int32_t[3]  sint32
    char        :
    int16_t[3]  sint16
    char        :
    int8_t[3]   sint8

    char        :
    float[3]    float
    char        :
    double[3]   double 

    char        :
    opaque[3]   opaque
  ));
  
  my $ffi = FFI::Platypus->new;
  $ffi->find_lib(lib => 'test', symbol => 'f0', libpath => 'libtest');
  
  $ffi->attach(["align_array_get_$_" => "get_$_"] => [ 'record(Foo4)' ] => "${_}[3]" )
    for qw( uint8 sint8 uint16 sint16 uint32 sint32 uint64 sint64 float double opaque );
};

subtest 'array alignment' => sub {
  plan tests => 14;

  my $foo = Foo4->new;
  isa_ok $foo, 'Foo4';

  foreach my $bits (qw( 8 16 32 64 ))
  {
    subtest "unsigned $bits integer" => sub {
      plan tests => 4;
      my $acc1 = "uint$bits";
      my $acc2 = "get_uint$bits";
      $foo->$acc1([1,2,3]);
      is_deeply $foo->$acc1, [1,2,3], "$acc1 = 1,2,3";
      is_deeply $foo->$acc2, [1,2,3], "$acc2 = 1,2,3";
      is $foo->$acc1(1), 2, "$acc1(1) = 2";
      $foo->$acc1(1,20);
      is_deeply $foo->$acc1, [1,20,3], "$acc1 = 1,20,3";
    };
    
    subtest "signed $bits integer" => sub {
      plan tests => 4;
      my $acc1 = "sint$bits";
      my $acc2 = "get_sint$bits";
      $foo->$acc1([-1,2,-3]);
      is_deeply $foo->$acc1, [-1,2,-3], "$acc1 = -1,2,-3";
      is_deeply $foo->$acc2, [-1,2,-3], "$acc2 = -1,2,-3";
      is $foo->$acc1(2), -3, "$acc1(2) = -3";
      $foo->$acc1(1,-20);
      is_deeply $foo->$acc1, [-1,-20,-3], "$acc1 = -1,-20,-3";
    };
  }

  foreach my $type (qw( float double ))
  {
    subtest $type => sub {
      plan tests => 5;
      $foo->$type([1.5,undef,-1.5]);
      is_deeply $foo->$type, [1.5,0.0,-1.5], "$type = 1.5,0,-1.5";
      is $foo->$type(0), 1.5;
      is $foo->$type(1), 0.0;
      is $foo->$type(2), -1.5;
      $foo->$type(1,20.0);
      is_deeply $foo->$type, [1.5,20.0,-1.5], "$type = 1.5,20,-1.5";
    };
  }

  subtest 'opaque' => sub {
    plan tests => 6;
    my $ptr1 = malloc 32;
    my $ptr2 = malloc 64;

    $foo->opaque([$ptr1,undef,$ptr2]);
    is_deeply $foo->opaque, [$ptr1,undef,$ptr2], "opaque     = $ptr1,undef,$ptr2";
    
    $foo->opaque(1,$ptr1);
    is_deeply $foo->opaque, [$ptr1,$ptr1,$ptr2], "opaque     = $ptr1,$ptr1,$ptr2";

    $foo->opaque(0,undef);
    is_deeply $foo->opaque, [undef,$ptr1,$ptr2], "opaque     = undef,$ptr1,$ptr2";

    is $foo->opaque(0), undef;
    is $foo->opaque(1), $ptr1;
    is $foo->opaque(2), $ptr2;
  
    free $ptr1;
    free $ptr2;
  };

  my $align = $foo->_ffi_record_align;
  like $align, qr{^[0-9]+$}, "align = $align";
  ok $align > 0, "align is positive";
};

do {
  package
    Foo5;

  use FFI::Platypus::Record;

  record_layout(qw(
    char   :
    string value
  ));
  
  my $ffi = FFI::Platypus->new;
  $ffi->find_lib(lib => 'test', symbol => 'f0', libpath => 'libtest');
  
  $ffi->attach( 
    [align_string_get_value => 'get_value'] => ['record(Foo5)'] => 'string',
  );
  
  $ffi->attach(
    [align_string_set_value => 'set_value']  => ['record(Foo5)','string'] => 'void',
  );
};

subtest 'string ro' => sub {
  plan tests => 8;

  my $foo = Foo5->new;
  isa_ok $foo, 'Foo5';

  is $foo->value, undef, 'foo.value = undef';
  is $foo->get_value, undef, 'foo.get_value = undef';

  $foo->set_value("my value");
  
  is $foo->value, 'my value', 'foo.value = my value';
  is $foo->get_value, 'my value', 'foo.get_value = my value';

  eval { $foo->value("stuff") };
  isnt $@, '', 'value is ro';
  note $@ if $@;

  $foo->set_value(undef);

  is $foo->value, undef, 'foo.value = undef';
  is $foo->get_value, undef, 'foo.get_value = undef';
};

do {
  package
    Foo6;

  use FFI::Platypus::Record;

  record_layout(qw(
    char       :
    string(10) value
  ));

  my $ffi = FFI::Platypus->new;
  $ffi->find_lib(lib => 'test', symbol => 'f0', libpath => 'libtest');

  $ffi->attach([align_fixed_get_value=>'get_value'] => ['record(Foo6)'] => 'string');
};

subtest 'fixed string' => sub {
  plan tests => 6;

  my $foo = Foo6->new;
  isa_ok $foo, 'Foo6';

  is $foo->value, "\0\0\0\0\0\0\0\0\0\0", 'foo.value = "\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0"';
  is $foo->get_value, "", 'foo.get_value = ""';
  
  $foo->value("one two three four five six seven eight");

  is $foo->value, "one two th", 'foo.value = "one two th"';
  
  $foo->value("123456789\0");
  
  is $foo->value, "123456789\0", "foo.value = 123456789\\0";
  is $foo->get_value, "123456789", "foo.get_value = 123456789";
};

do {
  package
    Foo7;

  use FFI::Platypus::Record;

  record_layout(qw(
    char      :
    string_rw value
  ));

  my $ffi = FFI::Platypus->new;
  $ffi->find_lib(lib => 'test', symbol => 'f0', libpath => 'libtest');

  $ffi->attach(
    [align_string_get_value => 'get_value'] =>
    ['record(Foo7)'] => 'string'
  );
  
};

subtest 'string rw' => sub {
  plan tests => 7;

  my $foo = Foo7->new;
  isa_ok $foo, 'Foo7';

  $foo->value('hi there');
  is $foo->value, "hi there", "foo.value = hi there";
  is $foo->get_value, 'hi there', 'foo.get_value = hi there';
  
  $foo->value(undef);
  is $foo->value, undef, 'foo.value = undef';
  is $foo->get_value, undef, 'foo.get_value = undef';

  $foo->value('starscream!!!');
  is $foo->value, "starscream!!!", "foo.value = starscream!!!";
  is $foo->get_value, 'starscream!!!', 'foo.get_value = starscream!!!';
};
