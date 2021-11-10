package FFI::Build::Plugin::Foo1;

use strict;
use warnings;

sub new
{
  my($class) = @_;
  bless {}, $class;
}

sub bar
{
  my($self, @args) = @_;
  $self->{bar} = \@args;
}

1;
