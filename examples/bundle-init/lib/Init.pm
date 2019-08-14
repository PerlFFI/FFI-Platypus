package Init;

use strict;
use warnings;
use FFI::Platypus;

our $VERSION = '1.00';

{
  my $ffi = FFI::Platypus->new( api => 1 );

  my $say = $ffi->closure(sub {
    my $string = shift;
    print "$string\n";
  });
  
  $ffi->bundle([
    $ffi->cast( 'string' => 'opaque', $VERSION ),
    $ffi->cast( '(string)->void' => 'opaque', $say ),
  ]);

  undef $ffi;
  undef $say;
}

1;
