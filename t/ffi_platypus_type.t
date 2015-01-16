use strict;
use warnings;
use Test::More tests => 6;
use FFI::Platypus;
use JSON::PP qw( encode_json );
BEGIN { eval q{ use YAML () } };

sub xdump ($)
{
  my($object) = @_;
  YAML->can('Dump') ? YAML::Dump($object) : encode_json($object);
}

subtest 'simple type' => sub {
  plan tests => 2;

  my $ffi = FFI::Platypus->new;
  eval { $ffi->type('sint8') };
  is $@, '', 'ffi.type(sint8)';

  isa_ok $ffi->{types}->{sint8}, 'FFI::Platypus::Type';
};

subtest 'aliased type' => sub {
  plan tests => 4;

  my $ffi = FFI::Platypus->new;
  eval { $ffi->type('sint8', 'my_integer_8') };
  is $@, '', 'ffi.type(sint8 => my_integer_8)';

  isa_ok $ffi->{types}->{my_integer_8}, 'FFI::Platypus::Type';
  isa_ok $ffi->{types}->{sint8}, 'FFI::Platypus::Type';
  
  ok scalar(grep { $_ eq 'my_integer_8' } $ffi->types), 'ffi.types returns my_integer_8';
};

my @list = qw( sint8 uint8 sint16 uint16 sint32 uint32 sint64 uint64 float double opaque string );

subtest 'ffi basic types' => sub {
  plan tests => scalar @list;

  foreach my $name (@list)
  {
    subtest $name => sub {
      plan tests => 3;
      my $ffi = FFI::Platypus->new;
      eval { $ffi->type($name) };
      is $@, '', "ffi.type($name)";
      isa_ok $ffi->{types}->{$name}, 'FFI::Platypus::Type';
      my $meta = $ffi->type_meta($name);
      note xdump( $meta);
      cmp_ok $meta->{size}, '>', 0, "size = " . $meta->{size};
    };
  }

};

subtest 'ffi pointer types' => sub {
  plan tests => scalar @list;

  foreach my $name (map { "$_ *" } qw( sint8 uint8 sint16 uint16 sint32 uint32 sint64 uint64 float double opaque string ))
  {
    subtest $name => sub {
      plan skip_all => 'ME GRIMLOCK SAY STRING CAN NO BE POINTER' if $name eq 'string *';
      plan tests => 3;
      my $ffi = FFI::Platypus->new;
      eval { $ffi->type($name) };
      is $@, '', "ffi.type($name)";
      isa_ok $ffi->{types}->{$name}, 'FFI::Platypus::Type';
      my $meta = $ffi->type_meta($name);
      note xdump( $meta);
      cmp_ok $meta->{size}, '>', 0, "size = " . $meta->{size};
    }
  }

};

subtest 'ffi array types' => sub {
  plan tests => scalar @list;

  my $size = 5;

  foreach my $basic (qw( sint8 uint8 sint16 uint16 sint32 uint32 sint64 uint64 float double opaque string ))
  {
    my $name = "$basic [$size]";
  
    subtest $name => sub {
      plan skip_all => 'ME GRIMLOCK SAY STRING CAN NO BE ARRAY' if $name =~ /^string \[[0-9]+\]$/; # TODO: actually this should be doable
      plan tests => 4;
      my $ffi = FFI::Platypus->new;
      eval { $ffi->type($name) };
      is $@, '', "ffi.type($name)";
      isa_ok $ffi->{types}->{$name}, 'FFI::Platypus::Type';
      my $meta = $ffi->type_meta($name);
      note xdump( $meta);
      cmp_ok $meta->{size}, '>', 0, "size = " . $meta->{size};
      is $meta->{element_count}, $size, "size = $size";
    };
    
    $size += 2;

  }

};

subtest 'closure types' => sub {
  plan tests => 6;

  my $ffi = FFI::Platypus->new;
  
  $ffi->type('int[22]' => 'my_int_array');
  $ffi->type('int'     => 'myint');
  
  $ffi->type('(int)->int' => 'foo');
  
  is $ffi->type_meta('foo')->{type}, 'closure', '(int)->int is a legal closure type';
  note xdump($ffi->type_meta('foo'));
  
  SKIP: {
    skip "arrays not currently supported as closure argument types", 1;
    $ffi->type('(my_int_array)->myint' => 'bar');
    is $ffi->type_meta('bar')->{type}, 'closure', '(int)->int is a legal closure type';
    note xdump($ffi->type_meta('bar'));
  }
  
  eval { $ffi->type('((int)->int)->int') };
  isnt $@, '', 'inline closure illegal';
  
  eval { $ffi->type('(foo)->int') };
  isnt $@, '', 'argument type closure illegal';

  eval { $ffi->type('(int)->foo') };
  isnt $@, '', 'return type closure illegal';
  
  $ffi->type('(int,int,int,char,string,opaque)->void' => 'baz');
  is $ffi->type_meta('baz')->{type}, 'closure', 'a more complicated closure';
  note xdump($ffi->type_meta('baz'));
  
};
