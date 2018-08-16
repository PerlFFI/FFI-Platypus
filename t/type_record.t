use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib qw( find_lib );

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';
my $record_size = My::FooRecord->ffi_record_size;
note "record size = $record_size";

subtest 'not a reference' => sub {
  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);

  $ffi->type("record($record_size)" => 'foo_record_t');
  my $get_name  = $ffi->function( foo_get_name    => [ 'foo_record_t' ] => 'string' );
  my $get_value = $ffi->function( foo_get_value   => [ 'foo_record_t' ] => 'sint32' );
  my $is_null   = $ffi->function( pointer_is_null => [ 'foo_record_t' ] => 'int' );
  my $create    = $ffi->function( foo_create      => [ 'string', 'sint32' ] => 'foo_record_t' );
  my $null      = $ffi->function( pointer_null    => [] => 'foo_record_t' );
  
  subtest in => sub {
    my $packed = pack('A16l', "hi there\0", 42);
    note "packed size = ", length $packed;
  
    is $get_value->($packed), 42, "get_value(\$packed) = 42";
    is $get_name->($packed),  "hi there", "get_name(\$packed) = hi there";
    is $is_null->(undef), 1, "is_null(undef)";
  };
  
  subtest out => sub {
    my $packed = $create->("platypus", 47);
    note "packed size = ", length $packed;
    
    is $get_value->($packed), 47, "get_value(\$packed) = 47";
    is $get_name->($packed), 'platypus', "get_value(\$packed) = platypus";
    is $null->(), undef, 'null() = undef';
  };
  
};


subtest 'is a reference' => sub {
  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);

  $ffi->type("record(My::FooRecord)" => 'foo_record_t');
  my $get_name  = $ffi->function( foo_get_name    => [ 'foo_record_t' ] => 'string' );
  my $get_value = $ffi->function( foo_get_value   => [ 'foo_record_t' ] => 'sint32' );
  my $is_null   = $ffi->function( pointer_is_null => [ 'foo_record_t' ] => 'int' );
  my $create    = $ffi->function( foo_create      => [ 'string', 'sint32' ] => 'foo_record_t' );
  my $null      = $ffi->function( pointer_null    => [] => 'foo_record_t' );
  
  subtest in => sub {
    my $packed = pack('A16l', "hi there\0", 42);
    note "packed size = ", length $packed;
  
    is $get_value->(\$packed), 42, "get_value(\\\$packed) = 42";
    is $get_name->(\$packed),  "hi there", "get_name(\\\$packed) = hi there";
    is $is_null->(\undef), 1, "is_null(\\undef)";
  };

  subtest out => sub {
    my $packed = $create->("platypus", 47);
    note "packed size = ", length $packed;

    isa_ok $packed, 'My::FooRecord';
    is $packed->my_method, "starscream", "packed.my_method = starscream";
    is $get_value->($packed), 47, "get_value(\$packed) = 47";
    is $get_name->($packed), 'platypus', "get_value(\$packed) = platypus";
    is $null->(), undef, 'null() = \undef';
  };

};

subtest 'closure' => sub {

  { package Closture::Record::RW;
  
    use FFI::Platypus::Record;
  
    record_layout(
      'string_rw' => 'one',
      'string_rw' => 'two',
      'int'       => 'three',
      'string_rw' => 'four',
    );
  }

  { package Closture::Record::RO;
  
    use FFI::Platypus::Record;
  
    record_layout(
      'string_ro' => 'one',
      'string_ro' => 'two',
      'int'       => 'three',
      'string_ro' => 'four',
    );
  }

  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);
  
  $ffi->type('record(Closture::Record::RO)' => 'cx_struct_ro_t');
  $ffi->type('record(Closture::Record::RW)' => 'cx_struct_rw_t');
  eval { $ffi->type('(cx_struct_ro_t,int)->void' => 'cx_closure_t') };
  is $@, '', 'allow record type as arg';

  my $cx_closure_set = $ffi->function(cx_closure_set => [ 'cx_closure_t' ] => 'void' );
  my $cx_closure_call = $ffi->function(cx_closure_call => [ 'cx_struct_rw_t', 'int' ] => 'void' );

  my $r = Closture::Record::RW->new;
  $r->one("one");
  $r->two("two");
  $r->three(3);
  $r->four("four");

  my $here = 0;

  my $f = $ffi->closure(sub {
    my($r2,$num) = @_;
    is($r2->one, "one");
    is($r2->two, "two");
    is($r2->three, 3);
    is($r2->four, "four");
    is($num, 42);
    $here = 1;
  });
  
  $cx_closure_set->($f);
  $cx_closure_call->($r, 42);
  
  is($here, 1);
  
  $here = 0;
  my $f2 = $ffi->closure(sub {
    my($r2, $num) = @_;
    is($r2, undef);
    is($num, 0);
    $here = 1;
  });
  
  $cx_closure_set->($f2);
  $cx_closure_call->(undef, undef);
  is($here,  1);
  
};

done_testing;

package
  My::FooRecord;

use constant ffi_record_size => do {
  my $ffi = FFI::Platypus->new;
  $ffi->sizeof('char[16]') + $ffi->sizeof('sint32');
};

sub my_method { "starscream" }
