use strict;
use warnings;
use Test::More tests => 45;

do {
  package
    Foo;
  
  use FFI::Platypus::Record;
  use FFI::Platypus::Record::TieArray;
  
  record_layout(qw(
    int[20] _bar
  ));
  
  sub bar
  {
    my($self) = @_;
    tie my @list, 'FFI::Platypus::Record::TieArray', $self, '_bar', 20;
    \@list;
  }
};


my $foo = Foo->new( _bar => [1..20] );
isa_ok $foo, 'Foo';

is $foo->bar->[1], 2;
$foo->bar->[1] = 22;
is $foo->bar->[1], 22;

is scalar(@{ $foo->bar }), 20;
is $#{ $foo->bar}, 19;

@{ $foo->bar } = ();

is $foo->bar->[$_], 0 for 0..19;

@{ $foo->bar } = (0..5);

is $foo->bar->[$_], $_ for 0..5;
is $foo->bar->[$_], 0  for 6..19;
