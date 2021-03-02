package Const;

use strict;
use warnings;
use FFI::Platypus 1.00;

{
  my $ffi = FFI::Platypus->new( api => 1 );
  $ffi->bundle;
}

1;
