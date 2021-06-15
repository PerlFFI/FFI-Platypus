use Test2::V0;
use Const;

foreach my $name (sort keys %Const::)
{
  next unless $name =~ /^MY/;
  note "$name=@{[ Const->$name ]}";
}

ok 1;

done_testing;
