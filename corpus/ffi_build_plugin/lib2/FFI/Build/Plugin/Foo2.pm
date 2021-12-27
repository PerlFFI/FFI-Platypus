package FFI::Build::Plugin::Foo2;

use strict;
use warnings;
use constant api_version => 0;

sub new
{
  my($class) = @_;
  bless {}, $class;
}

1;
