use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::Pod::Coverage' 
    unless eval q{ use Test::Pod::Coverage; 1 };
  plan skip_all => 'test requires YAML'
    unless eval q{ use YAML; 1; };
};
use Test::Pod::Coverage;
use YAML qw( LoadFile );
use FindBin;
use File::Spec;

my $config_filename = File::Spec->catfile(
  $FindBin::Bin, 'release.yml'
);

my $config;
$config = LoadFile($config_filename)
  if -r $config_filename;

plan skip_all => 'disabled' if $config->{pod_coverage}->{skip};

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

my @private_classes;
my %private_methods;

push @{ $config->{pod_coverage}->{private} },
  'Alien::.*::Install::Files#Inline';

foreach my $private (@{ $config->{pod_coverage}->{private} })
{
  my($class,$method) = split /#/, $private;
  if(defined $class && $class ne '')
  {
    my $regex = eval 'qr{^' . $class . '$}';
    if(defined $method && $method ne '')
    {
      push @private_classes, { regex => $regex, method => $method };
    }
    else
    {
      push @private_classes, { regex => $regex, all => 1 };
    }
  }
  elsif(defined $method && $method ne '')
  {
    $private_methods{$_} = 1 for split /,/, $method;
  }
}

my @classes = all_modules;

plan tests => scalar @classes;

foreach my $class (@classes)
{
  SKIP: {
    my($is_private_class) = map { 1 } grep { $class =~ $_->{regex} && $_->{all} } @private_classes;
    skip "private class: $class", 1 if $is_private_class;
    
    my %methods = map {; $_ => 1 } map { split /,/, $_->{method} } grep { $class =~ $_->{regex} } @private_classes;
    $methods{$_} = 1 for keys %private_methods;
    
    my $also_private = eval 'qr{^' . join('|', keys %methods ) . '$}';
    
    pod_coverage_ok $class, { also_private => [$also_private] };
  };
}

