package FFI::Platypus;

use strict;
use warnings;
use 5.008001;

# ABSTRACT: Glue a duckbill to an adorable aquatic mammal
# VERSION

require XSLoader;
XSLoader::load('FFI::Platypus', $VERSION);

sub new
{
  my($class) = @_;
  bless {}, $class;
}

1;
