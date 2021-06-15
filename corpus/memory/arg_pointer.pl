use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use Math::Complex;
use Test::LeakTrace qw( no_leaks_ok );

my @types = map { "$_*" } ( 'float', 'double', 'longdouble',
            map { ( "sint$_" , "uint$_" ) }
            qw( 8 16 32 64 ));

foreach my $type (@types)
{
  subtest $type => sub {
    my $ffi = FFI::Platypus->new;
    my $f = $ffi->function(0 => [ $type ] => 'void' );
    no_leaks_ok {
      my $val = 129;
      $f->call(\$val)
    };
    no_leaks_ok { $f->call(undef) };
  }
}

subtest 'opaque' => sub {
  my $ffi    = FFI::Platypus->new( lib => [undef] );
  my $malloc = $ffi->function( malloc => [ 'size_t' ] => 'opaque' );
  my $free   = $ffi->function( free => [ 'opaque' ] => 'void' );
  my $ptr    = $malloc->call(200);
  my $f      = $ffi->function(0 => [ 'opaque*' ] => 'void' );

  no_leaks_ok { $f->call(\$ptr) };
  $free->call($ptr);
  no_leaks_ok { $f->call(undef) };
};

subtest 'string' => sub {
  my $ffi = FFI::Platypus->new;
  my $f = $ffi->function(0 => [ 'string*' ] => 'void' );
  no_leaks_ok { $f->call(\"hello world") };
  my $str = "hello world";
  no_leaks_ok { $f->call(\$str) };
  no_leaks_ok { $f->call(undef) };
};

subtest 'complex' => sub {

  foreach my $type (qw( complex_float* complex_double* ))
  {
    subtest $type => sub {
      my $ffi = FFI::Platypus->new;
      my $f = $ffi->function(0 => [ $type ] => 'void' );

      {
        my $c = [1.0,2.0];
        no_leaks_ok { $f->call(\$c) };
      }

      {
        my $c = Math::Complex->make(1.0,2.0);
        no_leaks_ok { $f->call(\$c) };
      }
      no_leaks_ok { $f->call(undef) };
    };
  }

};

done_testing;
