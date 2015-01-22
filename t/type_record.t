use strict;
use warnings;
use Test::More tests => 2;
use FFI::Platypus;
use FFI::CheckLib qw( find_lib );

my $lib = find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';
my $record_size = My::FooRecord->ffi_record_size;
note "record size = $record_size";

subtest 'not a reference' => sub {
  plan tests => 2;

  my $ffi = FFI::Platypus->new;
  $ffi->lib($lib);

  $ffi->type("record($record_size)" => 'foo_record_t');
  my $get_name  = $ffi->function( foo_get_name    => [ 'foo_record_t' ] => 'string' );
  my $get_value = $ffi->function( foo_get_value   => [ 'foo_record_t' ] => 'sint32' );
  my $is_null   = $ffi->function( pointer_is_null => [ 'foo_record_t' ] => 'int' );
  my $create    = $ffi->function( foo_create      => [ 'string', 'sint32' ] => 'foo_record_t' );
  my $null      = $ffi->function( pointer_null    => [] => 'foo_record_t' );
  
  subtest in => sub {
    plan tests => 3;
    my $packed = pack('A16l', "hi there\0", 42);
    note "packed size = ", length $packed;
  
    is $get_value->($packed), 42, "get_value(\$packed) = 42";
    is $get_name->($packed),  "hi there", "get_name(\$packed) = hi there";
    is $is_null->(undef), 1, "is_null(undef)";
  };
  
  subtest out => sub {
    plan tests => 3;  
    my $packed = $create->("platypus", 47);
    note "packed size = ", length $packed;
    
    is $get_value->($packed), 47, "get_value(\$packed) = 47";
    is $get_name->($packed), 'platypus', "get_value(\$packed) = platypus";
    is $null->(), undef, 'null() = undef';
  };
  
};


subtest 'is a reference' => sub {
  plan tests => 2;

  my $ffi = FFI::Platypus->new;
  $ffi->lib($lib);

  $ffi->type("record(My::FooRecord)" => 'foo_record_t');
  my $get_name  = $ffi->function( foo_get_name    => [ 'foo_record_t' ] => 'string' );
  my $get_value = $ffi->function( foo_get_value   => [ 'foo_record_t' ] => 'sint32' );
  my $is_null   = $ffi->function( pointer_is_null => [ 'foo_record_t' ] => 'int' );
  my $create    = $ffi->function( foo_create      => [ 'string', 'sint32' ] => 'foo_record_t' );
  my $null      = $ffi->function( pointer_null    => [] => 'foo_record_t' );
  
  subtest in => sub {
    plan tests => 3;
    my $packed = pack('A16l', "hi there\0", 42);
    note "packed size = ", length $packed;
  
    is $get_value->(\$packed), 42, "get_value(\\\$packed) = 42";
    is $get_name->(\$packed),  "hi there", "get_name(\\\$packed) = hi there";
    is $is_null->(\undef), 1, "is_null(\\undef)";
  };

  subtest out => sub {
    plan tests => 5;
    my $packed = $create->("platypus", 47);
    note "packed size = ", length $packed;

    isa_ok $packed, 'My::FooRecord';
    is $packed->my_method, "starscream", "packed.my_method = starscream";
    is $get_value->($packed), 47, "get_value(\$packed) = 47";
    is $get_name->($packed), 'platypus', "get_value(\$packed) = platypus";
    is $null->(), undef, 'null() = \undef';
  };

};


package
  My::FooRecord;

use constant ffi_record_size => do {
  my $ffi = FFI::Platypus->new;
  $ffi->sizeof('char[16]') + $ffi->sizeof('sint32');
};

sub my_method { "starscream" }
