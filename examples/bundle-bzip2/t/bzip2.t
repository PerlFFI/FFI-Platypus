use Test2::V0;
use Bzip2;

subtest 'compress' => sub {
  my $bzip2 = Bzip2->new;
  isa_ok $bzip2, 'Bzip2';
};

done_testing;
