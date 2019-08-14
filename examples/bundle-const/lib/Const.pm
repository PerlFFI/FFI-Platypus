package Const;

use strict;
use warnings;
use FFI::Platypus;

{
  my $ffi = FFI::Platypus->new( api => 1 );
  $ffi->bundle;
}

1;
