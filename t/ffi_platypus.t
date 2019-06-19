use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib;
use Data::Dumper;
use File::Spec;

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

sub xdump ($)
{
  my($object) = @_;
  note(Data::Dumper->new([$object])->Indent(0)->Terse(1)->Sortkeys(1)->Dump);
}

subtest 'constructor' => sub {

  subtest 'basic' => sub {
    my $ffi = eval { FFI::Platypus->new };
    diag $@ if $@;
    isa_ok $ffi, 'FFI::Platypus';
  };

  subtest 'no arguments' => sub {
    my $ffi = FFI::Platypus->new;
    isa_ok $ffi, 'FFI::Platypus', 'FFI::Platypus.new';
    is_deeply [$ffi->lib], [], 'ffi.lib';
  };

  subtest 'with single lib' => sub {
    my $ffi = FFI::Platypus->new( lib => "libfoo.so" );
    isa_ok $ffi, 'FFI::Platypus', 'FFI::Platypus.new';
    is_deeply [$ffi->lib], ['libfoo.so'], 'ffi.lib';
  };

  subtest 'with multiple lib' => sub {
    my $ffi = FFI::Platypus->new( lib => ["libfoo.so", "libbar.so", "libbaz.so" ] );
    isa_ok $ffi, 'FFI::Platypus', 'FFI::Platypus.new';
    is_deeply [$ffi->lib], ['libfoo.so', 'libbar.so', 'libbaz.so'], 'ffi.lib';
  };

};

subtest 'abi' => sub {

  my $ffi = FFI::Platypus->new;

  my %abis = %{ $ffi->abis };

  ok defined $abis{default_abi}, 'has a default ABI';

  foreach my $abi (keys %abis)
  {
    subtest $abi => sub {
      eval { $ffi->abi($abi) };
      is $@, '', 'string';
      eval { $ffi->abi($abis{$abi}) };
      is $@, '', 'integer';
    };
  }

  subtest 'bogus' => sub {
    eval { $ffi->abi('bogus') };
    like $@, qr{no such ABI: bogus}, 'string';
    eval { $ffi->abi(999999) };
    like $@, qr{no such ABI: 999999}, 'integer';
  };

};

subtest 'alignof' => sub {
  my $ffi = FFI::Platypus->new;

  my $pointer_align = $ffi->alignof('opaque');

  subtest 'ffi types' => sub {

    foreach my $type (qw( sint8 uint8 sint16 uint16 sint32 uint32 sint64 uint64 float double opaque string ))
    {
      my $align = $ffi->alignof($type);
      like $align, qr{^[0-9]$}, "alignof $type = $align";

      next if $type eq 'string';

      my $align2 = $ffi->alignof("$type [2]");
      is $align2, $align, "alignof $type [2] = $align";

      my $align3 = $ffi->alignof("$type *");
      is $align3, $pointer_align, "alignof $type * = $pointer_align";

      $ffi->custom_type("custom_$type" => {
        native_type => $type,
        native_to_perl => sub {},
      });

      my $align4 = $ffi->alignof("custom_$type");
      is $align4, $align, "alignof custom_$type = $align";
    }
  };


  subtest 'aliases' => sub {
    $ffi->type('ushort' => 'foo');

    my $align = $ffi->alignof('ushort');
    like $align, qr{^[0-9]$}, "alignof ushort = $align";

    my $align2 = $ffi->alignof('foo');
    is $align2, $align, "alignof foo = $align";

  };

  subtest 'closure' => sub {
    $ffi->type('(int)->int' => 'closure_t');

    my $align = $ffi->alignof('closure_t');
    is $align, $pointer_align, "sizeof closure_t = $pointer_align";

  };

  subtest 'record' => sub {
    my $align = $ffi->alignof('record(22)');
    is $align, 1;
    xdump($ffi->type_meta('record(22)'));
  };
};

subtest 'custom type' => sub {

  my $ffi = FFI::Platypus->new;

  my @basic_types = (qw( float double opaque ), map { ("uint$_", "sint$_") } (8,16,32,64));

  foreach my $basic (@basic_types)
  {
    subtest $basic => sub {
      eval { $ffi->custom_type("foo_${basic}_1", { native_type => $basic, perl_to_native => sub {} }) };
      is $@, '', 'ffi.custom_type 1';
      xdump({ "${basic}_1" => $ffi->type_meta("foo_${basic}_1") });

      eval { $ffi->custom_type("bar_${basic}_1", { native_type => $basic, native_to_perl => sub {} }) };
      is $@, '', 'ffi.custom_type 1';
      xdump({ "${basic}_1" => $ffi->type_meta("bar_${basic}_1") });

      eval { $ffi->custom_type("baz_${basic}_1", { native_type => $basic, perl_to_native => sub {}, native_to_perl => sub {} }) };
      is $@, '', 'ffi.custom_type 1';
      xdump({ "${basic}_1" => $ffi->type_meta("baz_${basic}_1") });

      eval { $ffi->custom_type("foo_${basic}_2", { native_type => $basic, perl_to_native => sub {}, perl_to_native_post => sub { } }) };
      is $@, '', 'ffi.custom_type 1';
      xdump({ "${basic}_1" => $ffi->type_meta("foo_${basic}_2") });

      eval { $ffi->custom_type("bar_${basic}_2", { native_type => $basic, native_to_perl => sub {}, perl_to_native_post => sub { }  }) };
      is $@, '', 'ffi.custom_type 1';
      xdump({ "${basic}_1" => $ffi->type_meta("bar_${basic}_2") });

      eval { $ffi->custom_type("baz_${basic}_2", { native_type => $basic, perl_to_native => sub {}, native_to_perl => sub {}, perl_to_native_post => sub { }  }) };
      is $@, '', 'ffi.custom_type 1';
      xdump({ "${basic}_1" => $ffi->type_meta("baz_${basic}_2") });
    };
  }
};

subtest 'find lib' => sub {

  subtest 'find_lib' =>sub {
    my $ffi = FFI::Platypus->new;
    $ffi->find_lib(lib => 'test', symbol => 'f0', libpath => 't/ffi');
    my $address = $ffi->find_symbol('f0');
    ok $address, "found f0 = $address";
  };

  subtest external => sub {
    my $ffi = FFI::Platypus->new;
    $ffi->lib($libtest);

    my $good = $ffi->find_symbol('f0');
    ok $good, "ffi.find_symbol(f0) = $good";

    my $bad  = $ffi->find_symbol('bogus');
    is $bad, undef, 'ffi.find_symbol(bogus) = undef';
  };

  subtest internal => sub {
    my $ffi = FFI::Platypus->new;
    $ffi->lib(undef);

    my $good = $ffi->find_symbol('printf');
    ok $good, "ffi.find_symbol(printf) = $good";

    my $bad  = $ffi->find_symbol('bogus');
    is $bad, undef, 'ffi.find_symbol(bogus) = undef';
  };
};

subtest 'find symbol' => sub {
  subtest external => sub {
    my $ffi = FFI::Platypus->new;
    $ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi');

    my $good = $ffi->find_symbol('f0');
    ok $good, "ffi.find_symbol(f0) = $good";

    my $bad  = $ffi->find_symbol('bogus');
    is $bad, undef, 'ffi.find_symbol(bogus) = undef';
  };

  subtest internal => sub {
    my $ffi = FFI::Platypus->new;
    $ffi->lib(undef);

    my $good = $ffi->find_symbol('printf');
    ok $good, "ffi.find_symbol(printf) = $good";

    my $bad  = $ffi->find_symbol('bogus');
    is $bad, undef, 'ffi.find_symbol(bogus) = undef';
  };
};

subtest 'lib' => sub {
  subtest 'basic' => sub {

    my $ffi = FFI::Platypus->new;

    my($lib) = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';
    ok -e $lib, "exists $lib";

    eval { $ffi->lib($lib) };
    is $@, '', 'ffi.lib (set)';

    is_deeply [eval { $ffi->lib }], [$lib], 'ffi.lib (get)';

  };

  subtest 'undef' => sub {

    subtest 'baseline' => sub {
      my $ffi = FFI::Platypus->new;
      is_deeply([$ffi->lib], []);
    };

    subtest 'lib => [undef]' => sub {
      my $ffi = FFI::Platypus->new(lib => [undef]);
      is_deeply([$ffi->lib], [undef]);
    };

    subtest 'lib => undef' => sub {
      my $ffi = FFI::Platypus->new(lib => undef);
      is_deeply([$ffi->lib], [undef]);
    };

  };

  subtest 'coderef' => sub {

    my $ffi = FFI::Platypus->new;

    my($lib) = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';
    ok -e $lib, "exists $lib";

    eval { $ffi->lib(sub{ $lib }) };
    is $@, '', 'ffi.lib (set)';

    is_deeply [eval { $ffi->lib }], [$lib], 'ffi.lib (get)';

  };
};

subtest 'sizeof' => sub {
  my $ffi = FFI::Platypus->new;

  subtest integers => sub {
    is $ffi->sizeof('uint8'), 1, 'sizeof uint8 = 1';
    is $ffi->sizeof('uint16'), 2, 'sizeof uint16 = 2';
    is $ffi->sizeof('uint32'), 4, 'sizeof uint32 = 4';
    is $ffi->sizeof('uint64'), 8, 'sizeof uint64 = 8';

    is $ffi->sizeof('sint8'), 1, 'sizeof sint8 = 1';
    is $ffi->sizeof('sint16'), 2, 'sizeof sint16 = 2';
    is $ffi->sizeof('sint32'), 4, 'sizeof sint32 = 4';
    is $ffi->sizeof('sint64'), 8, 'sizeof sint64 = 8';
  };

  subtest floats => sub {
    is $ffi->sizeof('float'), 4, 'sizeof float = 4';
    is $ffi->sizeof('double'), 8, 'sizeof double = 8';
  };

  subtest pointers => sub {
    my $pointer_size = $ffi->sizeof('opaque');
    ok $pointer_size == 4 || $pointer_size == 8, "sizeof opaque = $pointer_size";

    is $ffi->sizeof('uint8*'), $pointer_size, "sizeof uint8* = $pointer_size";
    is $ffi->sizeof('uint16*'), $pointer_size, "sizeof uint16* = $pointer_size";
    is $ffi->sizeof('uint32*'), $pointer_size, "sizeof uint32* = $pointer_size";
    is $ffi->sizeof('uint64*'), $pointer_size, "sizeof uint64* = $pointer_size";

    is $ffi->sizeof('sint8*'), $pointer_size, "sizeof sint8* = $pointer_size";
    is $ffi->sizeof('sint16*'), $pointer_size, "sizeof sint16* = $pointer_size";
    is $ffi->sizeof('sint32*'), $pointer_size, "sizeof sint32* = $pointer_size";
    is $ffi->sizeof('sint64*'), $pointer_size, "sizeof sint64* = $pointer_size";

    is $ffi->sizeof('float*'), $pointer_size, "sizeof float* = $pointer_size";
    is $ffi->sizeof('double*'), $pointer_size, "sizeof double* = $pointer_size";
    is $ffi->sizeof('opaque*'), $pointer_size, "sizeof opaque* = $pointer_size";

    is $ffi->sizeof('string'), $pointer_size, "sizeof string = $pointer_size";
    is $ffi->sizeof('(int)->int'), $pointer_size, "sizeof (int)->int = $pointer_size";
  };

  subtest arrays => sub {
    foreach my $type (qw( uint8 uint16 uint32 uint64 sint8 sint16 sint32 sint64 float double opaque ))
    {
      my $unit_size = $ffi->sizeof($type);
      foreach my $size (1..10)
      {
        is $ffi->sizeof("$type [$size]"), $unit_size*$size, "sizeof $type [32] = @{[$unit_size*$size]}";
      }
    }

  };

  subtest custom_type => sub {

    foreach my $type (qw( uint8 uint16 uint32 uint64 sint8 sint16 sint32 sint64 float double opaque ))
    {
      my $expected = $ffi->sizeof($type);
      $ffi->custom_type( "my_$type" => { native_type => $type, native_to_perl => sub {} } );
      is $ffi->sizeof("my_$type"), $expected, "sizeof my_$type = $expected";
    }
  };
};

subtest 'type' => sub {
  subtest 'simple type' => sub {
    my $ffi = FFI::Platypus->new;
    eval { $ffi->type('sint8') };
    is $@, '', 'ffi.type(sint8)';

    isa_ok $ffi->{types}->{sint8}, 'FFI::Platypus::Type';
  };

  subtest 'aliased type' => sub {
    my $ffi = FFI::Platypus->new;
    eval { $ffi->type('sint8', 'my_integer_8') };
    is $@, '', 'ffi.type(sint8 => my_integer_8)';

    isa_ok $ffi->{types}->{my_integer_8}, 'FFI::Platypus::Type';
    isa_ok $ffi->{types}->{sint8}, 'FFI::Platypus::Type';

    ok scalar(grep { $_ eq 'my_integer_8' } $ffi->types), 'ffi.types returns my_integer_8';
  };

  my @list = grep { FFI::Platypus::_have_type($_) } qw( sint8 uint8 sint16 uint16 sint32 uint32 sint64 uint64 float double opaque string longdouble complex_float complex_double );

  subtest 'ffi basic types' => sub {
    foreach my $name (@list)
    {
      subtest $name => sub {
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
    foreach my $name (map { "$_ *" } @list)
    {
      subtest $name => sub {
        plan skip_all => 'ME GRIMLOCK SAY STRING CAN NO BE POINTER' if $name eq 'string *';
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
    my $size = 5;

    foreach my $basic (@list)
    {
      my $name = "$basic [$size]";

      subtest $name => sub {
        plan skip_all => 'ME GRIMLOCK SAY STRING CAN NO BE ARRAY' if $name =~ /^string \[[0-9]+\]$/; # TODO: actually this should be doable
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

  subtest 'record' => sub {
    { package My::Record22; use constant ffi_record_size => 22 }
    { package My::Record44; use constant _ffi_record_size => 44 }

    my $ffi = FFI::Platypus->new;

    $ffi->type('record(1)' => 'my_record_1');
    note xdump($ffi->type_meta('my_record_1'));
    $ffi->type('record (32)' => 'my_record_32');
    note xdump($ffi->type_meta('my_record_32'));

    is $ffi->type_meta('my_record_1')->{size}, 1, "sizeof my_record_1 = 1";
    is $ffi->type_meta('my_record_32')->{size}, 32, "sizeof my_record_32 = 32";

    $ffi->type('record(My::Record22)' => 'my_record_22');
    note xdump($ffi->type_meta('my_record_22'));
    $ffi->type('record (My::Record44)' => 'my_record_44');
    note xdump($ffi->type_meta('my_record_44'));

    is $ffi->type_meta('my_record_22')->{size}, 22, "sizeof my_record_22 = 22";
    is $ffi->type_meta('my_record_44')->{size}, 44, "sizeof my_record_44 = 44";
  };

  subtest 'string' => sub {
    my $ffi = FFI::Platypus->new;
    my $ptr_size = $ffi->sizeof('opaque');

    foreach my $type ('string', 'string_rw', 'string_ro', 'string rw', 'string ro')
    {
      subtest $type => sub {
        my $meta = $ffi->type_meta($type);

        is $meta->{size}, $ptr_size, "sizeof $type = $ptr_size";

        my $access = $type =~ /rw$/ ? 'rw' : 'ro';

        is $meta->{access}, $access, "access = $access";

        note xdump($meta);
      }
    }

    foreach my $type ('string (10)', 'string(10)')
    {
      subtest $type => sub {

        my $meta = $ffi->type_meta($type);

        is $meta->{type}, 'record', 'is actually a record type';
        is $meta->{size}, 10, "sizeof $type = 10";

        note xdump($meta);

      };
    }
  };

  subtest 'private' => sub {
    # this tests the private OO type API used only internally
    # to FFI::Platypus.  DO NOT USE FFI::Platypus::Type
    # its interface can and WILL change.

    my @names = qw(
    void
    uint8
    sint8
    uint16
    sint16
    uint32
    sint32
    uint64
    sint64
    float
    double
    longdouble
    opaque
    pointer
    );

    foreach my $name (@names)
    {
      subtest $name => sub {
        plan skip_all => 'test requires longdouble support'
          unless FFI::Platypus::_have_type($name);
        my $type = eval { FFI::Platypus::Type->new($name) };
        is $@, '', "type = FFI::Platypus::Type->new($name)";
        isa_ok $type, 'FFI::Platypus::Type';
        my $expected = $name eq 'opaque' ? 'pointer' : $name;
        is eval { $type->meta->{ffi_type} }, $expected, "type.meta.ffi_type = $expected";
      }
    }

    subtest string => sub {
      my $type = eval { FFI::Platypus::Type->new('string') };
      is $@, '', "type = FFI::Platypus::Type->new(string)";
      isa_ok $type, 'FFI::Platypus::Type';
      is eval { $type->meta->{ffi_type} }, 'pointer', 'type.meta.ffi_type = pointer';
    };
  };

};

subtest 'class or instance method' => sub {
  my @class = FFI::Platypus->types;
  my @instance = FFI::Platypus->new->types;
  is_deeply \@class, \@instance, 'class and instance methods are identical';
  note "type: $_" foreach sort @class;
};

subtest 'cast' => sub {
  my $ffi = FFI::Platypus->new;
  $ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi');

  subtest 'cast from string to pointer' => sub {
    my $string = "foobarbaz";
    my $pointer = $ffi->cast(string => opaque => $string);

    is $ffi->function(string_matches_foobarbaz => ['opaque'] => 'int')->call($pointer), 1, 'dynamic';

    $ffi->attach_cast(cast1 => string => 'opaque');
    my $pointer2 = cast1($string);

    is $ffi->function(string_matches_foobarbaz => ['opaque'] => 'int')->call($pointer2), 1, 'static';

  };

  subtest 'cast from pointer to string' => sub {
    my $pointer = $ffi->function(string_return_foobarbaz => [] => 'opaque')->call();
    my $string = $ffi->cast(opaque => string => $pointer);

    is $string, "foobarbaz", "dynamic";

    $ffi->attach_cast(cast2 => pointer => 'string');
    my $string2 = cast2($pointer);

    is $string2, "foobarbaz", "static";

  };

  subtest 'cast closure to opaque' => sub {
    my $testname = 'dynamic';

    my $closure = $ffi->closure(sub { is $_[0], "testvalue", $testname });
    my $pointer = $ffi->cast('(string)->void' => opaque => $closure);

    $ffi->function(string_set_closure => ['opaque'] => 'void')->call($pointer);
    $ffi->function(string_call_closure => ['string'] => 'void')->call("testvalue");

    $ffi->function(string_set_closure => ['(string)->void'] => 'void')->call($pointer);
    $ffi->function(string_call_closure => ['string'] => 'void')->call("testvalue");

    $ffi->attach_cast('cast3', '(string)->void' => 'opaque');
    my $pointer2 = cast3($closure);

    $testname = 'static';
    $ffi->function(string_set_closure => ['opaque'] => 'void')->call($pointer2);
    $ffi->function(string_call_closure => ['string'] => 'void')->call("testvalue");

    $ffi->function(string_set_closure => ['(string)->void'] => 'void')->call($pointer2);
    $ffi->function(string_call_closure => ['string'] => 'void')->call("testvalue");
  };
};

subtest 'ignore_not_found' => sub {

  subtest 'ignore_not_found=undef' => sub {
    my $ffi = FFI::Platypus->new;
    $ffi->lib($libtest);

    my $f1 = eval { $ffi->function(f1 => [] => 'void') };
    is $@, '', 'no exception';
    ok ref($f1), 'returned a function';
    note "f1 isa ", ref($f1);

    my $f2 = eval { $ffi->function(bogus => [] => 'void') };
    isnt $@, '', 'function exception';
    note "exception=$@";

    eval { $ffi->attach(bogus => [] => 'void') };
    isnt $@, '', 'attach exception';
    note "exception=$@";

  };

  subtest 'ignore_not_found=0' => sub {
    my $ffi = FFI::Platypus->new;
    $ffi->lib($libtest);
    $ffi->ignore_not_found(0);

    my $f1 = eval { $ffi->function(f1 => [] => 'void') };
    is $@, '', 'no exception';
    ok ref($f1), 'returned a function';
    note "f1 isa ", ref($f1);

    my $f2 = eval { $ffi->function(bogus => [] => 'void') };
    isnt $@, '', 'function exception';
    note "exception=$@";

    eval { $ffi->attach(bogus => [] => 'void') };
    isnt $@, '', 'attach exception';
    note "exception=$@";
  };

  subtest 'ignore_not_found=0 (constructor)' => sub {
    my $ffi = FFI::Platypus->new( ignore_not_found => 0 );
    $ffi->lib($libtest);

    my $f1 = eval { $ffi->function(f1 => [] => 'void') };
    is $@, '', 'no exception';
    ok ref($f1), 'returned a function';
    note "f1 isa ", ref($f1);

    my $f2 = eval { $ffi->function(bogus => [] => 'void') };
    isnt $@, '', 'function exception';
    note "exception=$@";

    eval { $ffi->attach(bogus => [] => 'void') };
    isnt $@, '', 'attach exception';
    note "exception=$@";
  };

  subtest 'ignore_not_found=1' => sub {
    my $ffi = FFI::Platypus->new;
    $ffi->lib($libtest);
    $ffi->ignore_not_found(1);

    my $f1 = eval { $ffi->function(f1 => [] => 'void') };
    is $@, '', 'no exception';
    ok ref($f1), 'returned a function';
    note "f1 isa ", ref($f1);

    my $f2 = eval { $ffi->function(bogus => [] => 'void') };
    is $@, '', 'function no exception';
    is $f2, undef, 'f2 is undefined';

    eval { $ffi->attach(bogus => [] => 'void') };
    is $@, '', 'attach no exception';

  };

  subtest 'ignore_not_found=1 (constructor)' => sub {
    my $ffi = FFI::Platypus->new( ignore_not_found => 1 );
    $ffi->lib($libtest);

    my $f1 = eval { $ffi->function(f1 => [] => 'void') };
    is $@, '', 'no exception';
    ok ref($f1), 'returned a function';
    note "f1 isa ", ref($f1);

    my $f2 = eval { $ffi->function(bogus => [] => 'void') };
    is $@, '', 'function no exception';

    is $f2, undef, 'f2 is undefined';
    eval { $ffi->attach(bogus => [] => 'void') };
    is $@, '', 'attach no exception';
  };

  subtest 'ignore_not_found bool context' => sub {
    my $ffi = FFI::Platypus->new( ignore_not_found => 1 );
    $ffi->lib($libtest);

    my $f1 = eval { $ffi->function(f1 => [] => 'void') };
    ok $f1, 'f1 exists and resolved to boolean true';

    my $f2 = eval { $ffi->function(bogus => [] => 'void') };
    ok !$f2, 'f2 does not exist and resolved to boolean false';
  };
};

subtest 'attach basic' => sub {

  package
    attach_basic;

  use FFI::Platypus;
  use Test::More;

  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);

  $ffi->attach('f0' => ['uint8'] => 'uint8');
  $ffi->attach([f0=>'f1'] => ['uint8'] => 'uint8');
  $ffi->attach([f0=>'Roger::f1'] => ['uint8'] => 'uint8');

  is f0(22), 22, 'f0(22) = 22';
  is f1(22), 22, 'f1(22) = 22';
  is Roger::f1(22), 22, 'Roger::f1(22) = 22';

  $ffi->attach([f0 => 'f0_wrap'] => ['uint8'] => uint8 => sub {
    my($inner, $value) = @_;

    return $inner->($value+1)+2;
  });

  $ffi->attach([f0 => 'f0_wrap2'] => ['uint8'] => uint8 => '$' => sub {
    my($inner, $value) = @_;

    return $inner->($value+1)+2;
  });

  is f0_wrap(22), 25, 'f0_wrap(22) = 25';
  is f0_wrap2(22), 25, 'f0_wrap(22) = 25';
};

subtest 'attach void' => sub {

  package
    attach_void;

  use FFI::Platypus;
  use Test::More;

  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);

  $ffi->attach('f2' => ['int*'] => 'void');
  $ffi->attach([f2=>'f2_implicit'] => ['int*']);

  my $i_ptr = 42;

  f2(\$i_ptr);
  is $i_ptr, 43, '$i_ptr = 43 after f2(\$i_ptr)';

  f2_implicit(\$i_ptr);
  is $i_ptr, 44, '$i_ptr = 44 after f2_implicit(\$i_ptr)';

};

subtest 'customer mangler' => sub {

  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);
  $ffi->mangler( sub { "mystrangeprefix_$_[0]" });
  is($ffi->function(bar => [] => 'int')->call, 42 );
};

done_testing;
