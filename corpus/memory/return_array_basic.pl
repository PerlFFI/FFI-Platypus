use strict;
use warnings;
use FFI::Platypus;
use Test::More;
use Test::LeakTrace qw( no_leaks_ok );

my @types = map { $_ . '[2]' }
            map { ( "sint$_" , "uint$_" ) }
            qw( 8 16 32 64 );

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
  
    is_deeply $ffi->cast( 'opaque' => $type, $ptr ), [1,2];
  
    $free->call($ptr);
  }
}

done_testing;
