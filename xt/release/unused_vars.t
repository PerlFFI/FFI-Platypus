use strict;
use warnings;
use Test::More;
BEGIN { plan skip_all => 'test requires Test::Vars ' unless eval q{ use Test::Vars; 1 } }
BEGIN { plan skip_all => 'test requires Path::Class' unless eval q{ use Path::Class::Dir; 1 } }
BEGIN { plan skip_all => 'test requires YAML' unless eval q{ use YAML; 1 } }

my $dir = Path::Class::Dir->new(__FILE__)->parent->parent->parent;
my $config = YAML::LoadFile($dir->file(qw( xt release release.yml )));

plan skip_all => 'disabled' unless defined $config->{unused_vars}->{skip} && !$config->{unused_vars}->{skip};

my @modules;
recurse($dir->subdir('lib'));

sub recurse
{
  my $dir = shift;
  foreach my $child ($dir->children)
  {
    if($child->is_dir)
    {
      recurse($child);
    }
    else
    {
      push @modules, $child if $child->basename =~ /\.pm$/;
    }
  }
}

plan tests => scalar @modules;

my %global = (
  ignore_vars => { map { $_ => 1 } @{ $config->{unused_vars}->{global}->{ignore_vars} } },
);
if(defined $config->{unused_vars}->{global}->{ignore_if})
{
  $global{ignore_if} = eval $config->{unused_vars}->{global}->{ignore_if};
  die $@ if $@;
}

foreach my $file (@modules)
{
  my @mod = $file->components;
  shift @mod; # get rid of '.';
  shift @mod; # get rid of 'lib';
  $mod[-1] =~ s/\.pm$//;
  my $mod = join '::', @mod;
  
  my %local = %global;
  foreach my $ignore (@{ $config->{unused_vars}->{module}->{$mod}->{ignore_vars} || []})
  {
    $local{ignore_vars}->{$ignore} = 1;
  }
  if(defined $config->{unused_vars}->{module}->{$mod}->{ignore_if})
  {
    $local{ignore_if} = eval $config->{unused_vars}->{module}->{$mod}->{ignore_if};
    die $@ if $@;
  }
  
  vars_ok($file, %local);
}
