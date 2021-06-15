use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test::FauxAttach;
use FFI::Platypus;
use Math::Complex;
use Test::LeakTrace qw( no_leaks_ok );
use FFI::Platypus::Record::Meta;

my @types = ( 'float', 'double', 'longdouble',
            map { ( "sint$_" , "uint$_" ) }
            qw( 8 16 32 64 ));

foreach my $type (@types)
{
  subtest $type => sub {
    my $ffi = FFI::Platypus->new;
    my $f = $ffi->function(0 => [ $type ] => 'void' );
    no_leaks_ok { $f->call(129) };
  }
}

subtest 'opaque' => sub {
  my $ffi    = FFI::Platypus->new( lib => [undef] );
  my $malloc = $ffi->function( malloc => [ 'size_t' ] => 'opaque' );
  my $free   = $ffi->function( free => [ 'opaque' ] => 'void' );
  my $ptr    = $malloc->call(200);
  my $f      = $ffi->function(0 => [ 'opaque' ] => 'void' );

  no_leaks_ok { $f->call($ptr) };
  $free->call($ptr);
  no_leaks_ok { $f->call(undef) };
};

subtest 'string' => sub {
  my $ffi = FFI::Platypus->new;
  my $f = $ffi->function(0 => [ 'string' ] => 'void' );
  no_leaks_ok { $f->call("hello world") };
  no_leaks_ok { $f->call(undef) };
};

subtest 'complex' => sub {

  foreach my $type (qw( complex_float complex_double ))
  {
    subtest $type => sub {
      my $ffi = FFI::Platypus->new;
      my $f = $ffi->function(0 => [ $type ] => 'void' );

      {
        my $c = [1.0,2.0];
        no_leaks_ok { $f->call($c) };
      }

      {
        my $c = Math::Complex->make(1.0,2.0);
        no_leaks_ok { $f->call($c) };
      }
    };
  }

};

subtest 'record' => sub {

  my $ffi = FFI::Platypus->new( api => 1 );

  our $meta = FFI::Platypus::Record::Meta->new(['sint32']);

  {
    package Foo;
    sub new
    {
      my $value = "\0" x 4;
      return bless \$value, 'Foo';
    }
    sub _ffi_record_size { 4 }
    sub _ffi_meta { $meta }
  }

  $ffi->type('record(Foo)' => 'foo_t');
  my $foo = Foo->new;

  foreach my $type (qw( foo_t foo_t* ))
  {
    subtest $type => sub {
      my $f = $ffi->function(0 => [ $type ] => 'void' );
      no_leaks_ok { $f->call($foo) };
    }
  }

  subtest 'record(4)*' => sub {
    my $f = $ffi->function(0 => [ 'record(4)*' ] => 'void' );
    my $str = "\0" x 4;
    no_leaks_ok { $f->call($str) };
  };

  undef $meta;

};

subtest 'closure' => sub {

  my $ffi = FFI::Platypus->new;
  $ffi->type('()->void' => 'closure_t');
  my $f = $ffi->function(0 => [ 'closure_t' ] => 'void' );

  no_leaks_ok { $f->call(undef) };
  no_leaks_ok {
    my $closure = $ffi->closure(sub {});
    $f->call($closure);
  };

  {
    my $closure = $ffi->closure(sub {});
    $f->call($closure);
    no_leaks_ok {
      $f->call($closure);
    }
  };

};

done_testing;
