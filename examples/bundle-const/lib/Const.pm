package Const;

use strict;
use warnings;
use FFI::Platypus 2.00;

{
  my $ffi = FFI::Platypus->new( api => 2 );
  $ffi->bundle;
}

1;
