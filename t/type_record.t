use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib qw( find_lib );
use FFI::Platypus::Memory qw( malloc free );

my @lib = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';
my $record_size = My::FooRecord->ffi_record_size;
note "record size = $record_size";

subtest 'not a reference' => sub {
  my $ffi = FFI::Platypus->new( lib => [@lib] );

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


subtest 'return null' => sub {

  is_deeply(
    [FFI::Platypus->new( api => 1, lib => [@lib] )->function( pointer_null => [] => 'record(10)*' )->call],
    [],
  );

  is_deeply(
    [FFI::Platypus->new( api => 2, experimental => 2, lib => [@lib] )->function( pointer_null => [] => 'record(10)*' )->call],
    [undef],
  );

};

subtest 'is a reference' => sub {
  my $ffi = FFI::Platypus->new( lib => [@lib] );

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
      'int[2]'    => 'myarray1',
      'opaque'    => 'opaque1',
      'opaque[2]' => 'myarray2',
      'string(5)' => 'fixedfive',
    );
  }

  my $ffi = FFI::Platypus->new( lib => [@lib] );

  $ffi->type('record(Closture::Record::RW)' => 'cx_struct_rw_t');
  eval { $ffi->type('(cx_struct_rw_t,int)->void' => 'cx_closure_t') };
  is $@, '', 'allow record type as arg';

  my $cx_closure_set = $ffi->function(cx_closure_set => [ 'cx_closure_t' ] => 'void' );
  my $cx_closure_call = $ffi->function(cx_closure_call => [ 'cx_struct_rw_t', 'int' ] => 'void' );

  my $r = Closture::Record::RW->new;
  $r->one("one");
  $r->two("two");
  $r->three(3);
  $r->four("four");
  $r->myarray1([1,2]);
  $r->opaque1(malloc(22));
  $r->myarray2([malloc(33),malloc(44)]);
  $r->fixedfive("five\0");
  is($r->_ffi_record_ro, 0);

  my $here = 0;

  my $f = $ffi->closure(sub {
    my($r2,$num) = @_;
    is($r2->_ffi_record_ro, 1);
    is($r2->one, "one");
    is($r2->two, "two");
    is($r2->three, 3);
    {
      local $@ = '';
      eval { $r2->three(64) };
      isnt $@, '';
      note "error = $@";
    }
    is($r2->three, 3);
    is($r2->four, "four");
    is_deeply($r2->myarray1, [1,2]);
    {
      local $@ = '';
      eval { $r2->myarray1([3,4]) };
      isnt $@, '';
      note "error = $@";
    }
    is_deeply($r2->myarray1, [1,2]);
    {
      local $@ = '';
      eval { $r2->myarray1(3,4) };
      isnt $@, '';
      note "error = $@";
    }
    is_deeply($r2->myarray1, [1,2]);

    is($r2->opaque1, $r->opaque1);
    {
      local $@ = '';
      eval { $r2->opaque1(undef) };
      isnt $@, '';
      note "error = $@";
    }
    is($r2->opaque1, $r->opaque1);

    is_deeply($r2->myarray2, $r->myarray2);
    {
      local $@ = '';
      eval { $r2->myarray2([undef,undef]) };
      isnt $@, '';
      note "error = $@";
    }
    is_deeply($r2->myarray2, $r->myarray2);
    {
      local $@ = '';
      eval { $r2->myarray2(undef,undef) };
      isnt $@, '';
      note "error = $@";
    }
    is_deeply($r2->myarray2, $r->myarray2);

    {
      local $@ = '';
      eval { $r2->one("new string!") };
      isnt $@, '';
      note "error = $@";
    }
    is($r2->one, "one");

    is($r2->fixedfive, "five\0");
    {
      local $@ = '';
      eval { $r2->fixedfive("xxxxx") };
      isnt $@, '';
      note "error = $@";
    }
    is($r2->fixedfive, "five\0");

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

subtest 'api = 1 fixed string' => sub {

  my $ffi = FFI::Platypus->new( api => 1, lib => [@lib] );

  {
    package My::FooRecord2;
    use FFI::Platypus::Record;
    eval { record_layout( $ffi, qw( string(5)* foo string(5) bar )) };
  }

  is "$@", "";

  my $r = My::FooRecord2->new( foo => '12345', bar => '67890' );

  is $r->foo, '12345';
  is $r->bar, '67890';

};

done_testing;

package
  My::FooRecord;

use constant ffi_record_size => do {
  my $ffi = FFI::Platypus->new;
  $ffi->sizeof('char[16]') + $ffi->sizeof('sint32');
};

sub my_method { "starscream" }
