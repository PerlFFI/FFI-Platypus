use strict;
use warnings;
use Test::More tests => 2;
use FFI::Platypus;
use FFI::CheckLib qw( find_lib );

my $lib = find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';
my $record_size = My::FooRecord->ffi_record_size;
note "record size = $record_size";

subtest 'not a reference' => sub {

  my $ffi = FFI::Platypus->new;
  $ffi->lib($lib);

  $ffi->type("record($record_size)" => 'foo_record_t');
  my $get_name  = $ffi->function( foo_get_name    => [ 'foo_record_t' ] => 'string' );
  my $get_value = $ffi->function( foo_get_value   => [ 'foo_record_t' ] => 'int' );
  my $is_null   = $ffi->function( pointer_is_null => [ 'foo_record_t' ] => 'int' );
  
  my $packed = pack('A16q', "hi there\0", 42);
  note "packed size = ", length $packed;
  
  is $get_value->($packed), 42, "get_value(\$packed) = 42";
  is $get_name->($packed),  "hi there", "get_name(\$packed) = hi there";
  is $is_null->(undef), 1, "is_null(undef)";
};


subtest 'is a reference' => sub {

  my $ffi = FFI::Platypus->new;
  $ffi->lib($lib);

  $ffi->type("record(My::FooRecord)" => 'foo_record_t');
  my $get_name  = $ffi->function( foo_get_name  => [ 'foo_record_t' ] => 'string' );
  my $get_value = $ffi->function( foo_get_value => [ 'foo_record_t' ] => 'int' );
  my $is_null   = $ffi->function( pointer_is_null => [ 'foo_record_t' ] => 'int' );
  
  my $packed = pack('A16q', "hi there\0", 42);
  note "packed size = ", length $packed;
  
  is $get_value->(\$packed), 42, "get_value(\\\$packed) = 42";
  is $get_name->(\$packed),  "hi there", "get_name(\\\$packed) = hi there";
  is $is_null->(\undef), 1, "is_null(\\undef)";
};


package
  My::FooRecord;

use constant ffi_record_size => do {
  my $ffi = FFI::Platypus->new;
  $ffi->sizeof('char[16]') + $ffi->sizeof('sint64');
};
