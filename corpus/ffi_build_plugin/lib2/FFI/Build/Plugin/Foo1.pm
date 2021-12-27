package FFI::Build::Plugin::Foo1;

use strict;
use warnings;
use constant api_version => 0;

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
