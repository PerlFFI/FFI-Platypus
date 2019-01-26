use strict;
use warnings;
use ExtUtils::CBuilder;
use Text::ParseWords qw( shellwords );
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

my $share_config = $probe->share_config;

{
  my $class = $share_config->get('alien')->{class};
  my $pm = "$class.pm";
  $pm =~ s/::/\//g;
  require $pm;
  $share_config->set(extra_compiler_flags => [ shellwords($class->cflags) ]);
  $share_config->set(extra_linker_flags   => [ shellwords($class->libs) ]);
  $share_config->set(ccflags => $class->cflags);
}
