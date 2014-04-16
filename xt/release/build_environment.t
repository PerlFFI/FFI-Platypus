use strict;
use warnings;
use Test::More tests => 1;

SKIP: {
  eval q{ use Dist::Zilla::PluginBundle::Author::Plicease };
  skip '[@Plicease] is not installed', 1 if $@;
  ok $Dist::Zilla::PluginBundle::Author::Plicease::VERSION >= 0.7, '[@Plicease] >= 0.7';
}
