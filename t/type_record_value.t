use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib qw( find_lib );
use FFI::Platypus::Memory qw( malloc free );
use FFI::Platypus::ShareConfig;

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

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
  my $ffi = FFI::Platypus->new( api => 1 );
  $ffi->lib($libtest);

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

done_testing;

