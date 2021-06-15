use Test2::Require::Module 'Test2::Tools::PerlCritic';
use Test2::Require::Module 'Perl::Critic';
use Test2::Require::Module 'Perl::Critic::Community';
use Test2::V0;
use Perl::Critic;
use Test2::Tools::PerlCritic;

my $critic = Perl::Critic->new(
  -profile => 'perlcriticrc',
);

perl_critic_ok ['lib','t'], $critic;

done_testing;
