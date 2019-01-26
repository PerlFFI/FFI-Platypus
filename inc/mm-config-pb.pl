use strict;
use warnings;
use lib 'inc';
use My::Config;

my $config = My::Config->new;
$config->probe_runner_build;
