use strict;
use warnings;
use Test::More;
use Foo;

my $foo = Foo->new("platypus", 10);
isa_ok $foo, 'Foo';
is $foo->name, "platypus";
is $foo->value, 10;

done_testing;
