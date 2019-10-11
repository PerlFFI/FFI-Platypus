use strict;
use warnings;
use FFI::Platypus;
use Test::More;
use Math::Complex;
use Test::LeakTrace qw( no_leaks_ok );

my @types = map { $_ . '[2]' }
            ( 'float', 'double', 'longdouble',
            map { ( "sint$_" , "uint$_" ) }
            qw( 8 16 32 64 ));

foreach my $type (@types)
{
  subtest $type => sub {
    my $ffi = FFI::Platypus->new( lib => [undef] );
    my $malloc = $ffi->function( 'malloc' => [ 'size_t'                      ] => 'opaque' );
    my $free   = $ffi->function( 'free'   => [ 'opaque'                      ] => 'void'   );
    my $memcpy = $ffi->function( 'memcpy' => [ 'opaque', $type, 'size_t' ] => 'opaque' );

    my $size = $ffi->sizeof($type);
    my $ptr = $malloc->call($size);
    $memcpy->call($ptr, [1,2], $size);

    no_leaks_ok {
      $ffi->cast( 'opaque' => $type, $ptr );
    };

    if($type =~ /^longdouble/)
    {
      my @o = @{ $ffi->cast( 'opaque' => $type, $ptr ) };
      cmp_ok $o[0], '==', 1;
      cmp_ok $o[1], '==', 2;
    }
    else
    {
      is_deeply $ffi->cast( 'opaque' => $type, $ptr ), [1,2];
    }

    $free->call($ptr);
  }
}

subtest 'string/opaque' => sub {

  my $ffi = FFI::Platypus->new( lib => [undef] );
  my $malloc = $ffi->function( 'malloc' => [ 'size_t'                      ] => 'opaque' );
  my $strdup = $ffi->function( 'strdup' => [ 'string'                      ] => 'opaque' );
  my $free   = $ffi->function( 'free'   => [ 'opaque'                      ] => 'void'   );
  my $memcpy = $ffi->function( 'memcpy' => [ 'opaque', 'opaque[2]', 'size_t' ] => 'opaque' );

  my $size = $ffi->sizeof('string[2]');
  my $ptr = $malloc->call($size);
  my $frooble = $strdup->call("frooble");
  $memcpy->call($ptr, [$frooble,undef], $size);

  no_leaks_ok {
    $ffi->cast( 'opaque' => 'string[2]', $ptr );
  };

  is_deeply $ffi->cast( 'opaque' => 'string[2]', $ptr ), ["frooble",undef];

  no_leaks_ok {
    $ffi->cast( 'opaque' => 'opaque[2]', $ptr );
  };

  is_deeply $ffi->cast( 'opaque' => 'opaque[2]', $ptr ), [$frooble,undef];

  $free->call($frooble);
  $free->call($ptr);

};

foreach my $type (qw( complex_float[2] complex_double[2] ))
{
  subtest $type => sub {
    my $ffi = FFI::Platypus->new( lib => [undef] );
    my $malloc = $ffi->function( 'malloc' => [ 'size_t'                      ] => 'opaque' );
    my $free   = $ffi->function( 'free'   => [ 'opaque'                      ] => 'void'   );
    my $memcpy = $ffi->function( 'memcpy' => [ 'opaque', $type, 'size_t' ] => 'opaque' );

    my $size = $ffi->sizeof($type);
    my $ptr = $malloc->call($size);
    $memcpy->call($ptr, [[1.0,2.0],[3.0,4.0]], $size);

    no_leaks_ok {
      $ffi->cast( 'opaque' => $type, $ptr );
    };

    is_deeply $ffi->cast( 'opaque' => $type, $ptr ), [[1.0,2.0],[3.0,4.0]];

    $free->call($ptr);
  };

}

done_testing;
