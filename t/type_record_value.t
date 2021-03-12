use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib qw( find_lib );
use FFI::Platypus::Memory qw( malloc free );
use FFI::Platypus::ShareConfig;

my @lib = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

my $return_ok = FFI::Platypus::ShareConfig->get('probe')->{recordvalue};

{
  package
    FooRecord;
  use FFI::Platypus::Record;
  record_layout(qw(
    string(16) name
    sint32     value
  ));
}

subtest 'is a reference' => sub {
  my $ffi = FFI::Platypus->new( lib => [@lib], api => 1 );

  $ffi->type("record(FooRecord)" => 'foo_record_t');
  my $get_name  = $ffi->function( foo_value_get_name    => [ 'foo_record_t' ] => 'string' );
  my $get_value = $ffi->function( foo_value_get_value   => [ 'foo_record_t' ] => 'sint32' );

  subtest 'argument' => sub {

    subtest 'bad' => sub {

      my $data = "\0" x 100;
      my $bad1 = bless \$data, 'FooRecordBad';
      eval { $get_name->call($bad1) };
      like "$@", qr/^argument 0 is not an instance of FooRecord/;

      eval { $get_name->call(\42) };
      like "$@", qr/^argument 0 is not an instance of FooRecord/;

      eval { $get_name->call(42) };
      like "$@", qr/^argument 0 is not an instance of FooRecord/;

    };

    subtest 'good' => sub {

      my $rv = FooRecord->new(
        name => "hello",
        value => 42,
      );

      is $get_name->call($rv), "hello";
      is $get_value->call($rv), 42;

    };

  };

  subtest 'return value' => sub {

    plan skip_all => 'test requires working return records-by-value'
      unless $return_ok;

    subtest 'function object' => sub {

      my $create    = $ffi->function( foo_value_create      => [ 'string', 'sint32' ] => 'foo_record_t' );

      my $rv = $create->call("laters", 47);
      is $rv->name,  "laters\0\0\0\0\0\0\0\0\0\0";
      is $rv->value, 47;
    };

    subtest 'xsub_ref' => sub {

      my $create = $ffi->function( foo_value_create      => [ 'string', 'sint32' ] => 'foo_record_t' )->sub_ref;

      my $rv = $create->("laters", 47);
      is $rv->name,  "laters\0\0\0\0\0\0\0\0\0\0";
      is $rv->value, 47;

    };

    subtest 'attach' => sub {

      $ffi->attach( foo_value_create      => [ 'string', 'sint32' ] => 'foo_record_t' );

      my $rv = foo_value_create("laters", 47);
      is $rv->name,  "laters\0\0\0\0\0\0\0\0\0\0";
      is $rv->value, 47;

    };

  };

};

subtest 'closure' => sub {

  { package Closure::Record::RW;

    use FFI::Platypus::Record;

    record_layout_1(
      'string rw' => 'one',
      'string rw' => 'two',
      'int'       => 'three',
      'string rw' => 'four',
      'int[2]'    => 'myarray1',
      'opaque'    => 'opaque1',
      'opaque[2]' => 'myarray2',
      'string(5)' => 'fixedfive',
    );
  }

  my $ffi = FFI::Platypus->new( lib => [@lib], api => 1 );

  $ffi->type('record(Closure::Record::RW)' => 'cx_struct_rw_t');
  {
    local $@ = '';
    eval { $ffi->type('(cx_struct_rw_t,int)->void' => 'cxv_closure_t') };
    is $@, '', 'do allow record type as arg';
  }

  {
    local $@ = '';
    eval { $ffi->type('()->cx_struct_rw_t' )  };
    like "$@", qr/Record return type contains types that cannot be returned from a closure/, 'do not allow record type with pointer strings as ret type';
  }

  my $cxv_closure_set = $ffi->function(cxv_closure_set => [ 'cxv_closure_t' ] => 'void' );
  my $cxv_closure_call = $ffi->function(cxv_closure_call => [ 'cx_struct_rw_t', 'int' ] => 'void' );

  my $r = Closure::Record::RW->new;
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
    note "first closure";
    isa_ok $r2, 'Closure::Record::RW';
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

  $cxv_closure_set->($f);
  $cxv_closure_call->($r, 42);

  is($here, 1);

};

subtest 'closure ret' => sub {

  { package Closure::Record::Simple;

    use FFI::Platypus::Record;

    record_layout_1(
      char  => 'foo',
      short => 'bar',
      int   => 'baz',
    );

  }

  my $ffi = FFI::Platypus->new( lib => [@lib], api => 1 );

  $ffi->type('record(Closure::Record::Simple)' => 'cx_struct_simple_t');

  {
    local $@ = '';
    eval { $ffi->type('()->cx_struct_simple_t' => 'cxv_closure_simple_t' )  };
    is "$@", '';
  }

  my $cxv_closure_simple_call = do {
    local $@ = '';
    my $f = eval { $ffi->function( cxv_closure_simple_call => ['cxv_closure_simple_t'] => 'cx_struct_simple_t') };
    is "$@", '';
    $f;
  };

  subtest 'good' => sub {

    my $f = $ffi->closure(sub {
      return Closure::Record::Simple->new( foo => 1, bar => 2, baz => 3 );
    });

    my $r = $cxv_closure_simple_call->call($f);

    isa_ok $r, 'Closure::Record::Simple';
    is $r->foo, 1;
    is $r->bar, 2;
    is $r->baz, 3;
  };

  subtest 'bad' => sub {

    my $f = $ffi->closure(sub {
      return undef;
    });

    local $SIG{__WARN__} = sub {
      note @_;
    };

    my $r = $cxv_closure_simple_call->call($f);

    isa_ok $r, 'Closure::Record::Simple';
    is $r->foo, 0;
    is $r->bar, 0;
    is $r->baz, 0;

  };

  subtest 'short' => sub {

    my $f = $ffi->closure(sub {
      my $r = Closure::Record::Simple->new;
      $$r = "";
      return $r;
    });

    local $SIG{__WARN__} = sub {
      note @_;
    };

    my $r = $cxv_closure_simple_call->call($f);

    isa_ok $r, 'Closure::Record::Simple';
    is $r->foo, 0;
    is $r->bar, 0;
    is $r->baz, 0;

  };

};

done_testing;

