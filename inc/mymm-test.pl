use strict;
use warnings;
use lib 'inc';
use My::Once;
use My::LibTest;
use My::ShareConfig;

#My::Once->check('test');

my $share_config = My::ShareConfig->new;
My::LibTest->build(
  ExtUtils::CBuilder->new( config => { ccflags => $share_config->get('ccflags') }),
  $share_config->get('ccflags'),
  [],
  $share_config->get('extra_linker_flags'),
);

#My::Once->done;
