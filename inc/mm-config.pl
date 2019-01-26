use strict;
use warnings;
use ExtUtils::CBuilder;
use lib 'inc';
use My::Config;
use lib 'lib';

exit if -f '_mm/config';

my $config = My::Config->new;
$config->generate_dev;
$config->configure;
$config->alien;
