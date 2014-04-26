package inc::DynamicConfig;

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

sub metadata 
{
  return { dynamic_config => 1 };
}

1;
