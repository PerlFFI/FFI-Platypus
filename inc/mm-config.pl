use strict;
use warnings;
use ExtUtils::CBuilder;
use lib 'inc';
use My::Probe;
use My::Dev;
use lib 'lib';
use FFI::Probe::Runner::Builder;

exit if -f '_mm/config';

FFI::Probe::Runner::Builder->new->build;

My::Dev->generate;

my $probe = My::Probe->new;
$probe->configure;
$probe->alien;
