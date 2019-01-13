use strict;
use warnings;
use ExtUtils::CBuilder;
use Text::ParseWords qw( shellwords );
use lib 'inc';
use My::Probe;
use My::Dev;
use My::ShareConfig;

exit if -f '_mm/config';

{
  require './lib/FFI/Probe/Runner/Builder.pm';
  print "building probe runner...\n";
  my $builder = FFI::Probe::Runner::Builder->new;
  $builder->build;
}

My::Dev->generate;

my $share_config = My::ShareConfig->new;

My::Probe->configure($share_config);

{
  my $class = $share_config->get('alien')->{class};
  my $pm = "$class.pm";
  $pm =~ s/::/\//g;
  require $pm;
  $share_config->set(extra_compiler_flags => [ shellwords($class->cflags) ]);
  $share_config->set(extra_linker_flags   => [ shellwords($class->libs) ]);
  $share_config->set(ccflags => $class->cflags);
}

mkdir '_mm' unless -d '_mm';
{
  my $fh;
  open $fh, '>', '_mm/config';
  close $fh;
}
