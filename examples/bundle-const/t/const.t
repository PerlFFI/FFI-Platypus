use strict;
use warnings;
use Test::More;
use Const;

foreach my $name (sort keys %Const::)
{
  next unless $name =~ /^MY/;
  note "$name=@{[ Const->$name ]}";
}

ok 1;

done_testing;
