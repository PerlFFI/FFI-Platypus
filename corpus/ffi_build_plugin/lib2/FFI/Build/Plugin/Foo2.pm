package FFI::Build::Plugin::Foo2;

use strict;
use warnings;

sub new
{
  my($class) = @_;
  bless {}, $class;
}

1;
