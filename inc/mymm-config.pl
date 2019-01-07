use strict;
use warnings;
use ExtUtils::CBuilder;
use lib 'inc';
use My::Once;
use My::AutoConf;
use My::Probe;
use My::Dev;
use My::ShareConfig;

My::Once->check('config');

{
  require './lib/FFI/Probe/Runner/Builder.pm';
  print "building probe runner...\n";
  my $builder = FFI::Probe::Runner::Builder->new;
  $builder->build;
}

My::Dev->generate;

My::AutoConf->configure;

my $share_config = My::ShareConfig->new;

My::Probe->probe(
  ExtUtils::CBuilder->new( config => { ccflags => $share_config->get('ccflags') }),
  $share_config->get('ccflags'),
  [],
  $share_config->get('extra_linker_flags'),
);
unlink $_ for My::Probe->cleanup;

My::Once->done;
