package FFI::Platypus;

use strict;
use warnings;

BEGIN {

# ABSTRACT: Kinda like gluing a duckbill to an adorable mammal
# VERSION

  require XSLoader;
  XSLoader::load('FFI::Platypus', $VERSION);

}

1;
