use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use FFI::CheckLib;
use FFI::Platypus::ShareConfig;

my @lib = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

my @legal = qw( float double opaque );
push @legal, map { ("sint$_","uint$_") } qw( 8 16 32 64 );

my $return_ok = FFI::Platypus::ShareConfig->get('probe')->{recordvalue};

subtest 'legal custom types' => sub {

  my $ffi = FFI::Platypus->new( api => 1 );

  foreach my $type (@legal)
  {
    local $@ = "";
    eval {
      $ffi->custom_type( "foo_$type" => {
        native_type => $type,
        native_to_perl => sub {},
      });
    };
    is "$@", "";
  }

};

subtest 'illegal types' => sub {

  my $ffi = FFI::Platypus->new( api => 1 );

  foreach my $type (qw( sint8[32] sint8* ))
  {
    local $@ = "";
    my $alias = "foo_$type";
    $alias =~ s/[\*\[\]]/_/g;
    note "alias = $alias";
    eval {
      $ffi->custom_type( $alias => {
        native_type => $type,
        native_to_perl => sub {},
      });
    };
    like "$@", qr/\Q$type\E is not a legal basis for a custom type/;
  }

};

subtest 'records' => sub {

  {
    package Foo;
    use FFI::Platypus::Record;
    record_layout qw(
      string(16) name
      sint32 value
    );
  }


  subtest 'pointer' => sub {

    my $ffi = FFI::Platypus->new( api => 2, lib => [@lib] );
    local $@ = '';
    eval {
      $ffi->custom_type(
        'foo_t' => {
          native_type => 'record(Foo)*',
          perl_to_native => sub {
            my $var = shift;
            return Foo->new(name => $var->[0], value => $var->[1]);
          },
          native_to_perl => sub {
            my $rec = shift;
            return defined $rec ? [$rec->name, $rec->value] : [];
          },
        },
      );
    };

    is "$@", '' or return;

    {
      is(
        $ffi->function( foo_get_name => [ 'foo_t' ] => 'string' )
            ->call( ["Graham", 47] ),
        "Graham",
      );
      is(
        $ffi->function( foo_get_value => [ 'foo_t' ] => 'sint32' )
            ->call( ["Graham", 47] ),
        47,
      );
      is(
        $ffi->function( foo_create => ['string','sint32'] => 'foo_t' )
            ->call("Adams", 42),
        ["Adams\0\0\0\0\0\0\0\0\0\0\0", 42],
      );
      is(
        $ffi->function( pointer_null => [] => 'foo_t' )
            ->call,
        [],
      );
    }

  };

  subtest 'by-value' => sub {

    my $ffi = FFI::Platypus->new( api => 1, lib => [@lib] );
    local $@ = '';
    eval {
      $ffi->custom_type(
        'foo_t' => {
          native_type => 'record(Foo)',
          perl_to_native => sub {
            my $var = shift;
            return Foo->new(name => $var->[0], value => $var->[1]);
          },
          native_to_perl => sub {
            my $rec = shift;
            return [$rec->name, $rec->value];
          },
        },
      );
    };

    is "$@", '' or return;

    {
      is(
        $ffi->function( foo_value_get_name => [ 'foo_t' ] => 'string' )
            ->call( ["Graham", 47] ),
        "Graham",
      );
      is(
        $ffi->function( foo_value_get_value => [ 'foo_t' ] => 'sint32' )
            ->call( ["Graham", 47] ),
        47,
      );
      subtest 'return-value' => sub {
        skip_all 'test requires working return records-by-value'
        unless $return_ok;

        is(
          $ffi->function( foo_value_create => ['string','sint32'] => 'foo_t' )
              ->call("Adams", 42),
         ["Adams\0\0\0\0\0\0\0\0\0\0\0", 42],
        );
      };
    }

  };

};

done_testing;
