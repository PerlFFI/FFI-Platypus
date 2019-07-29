use strict;
use warnings;
use lib 'inc';
use My::BuildConfig;

my($key, @value) = @ARGV;

my $config = My::BuildConfig->new;
my $eumm = $config->get('eumm');
$eumm->{$key} = [@value];
$config->set('eumm' => $eumm);
