use strict;
use warnings;
use Config;
use Test::More tests => 1;

# This .t file is generated.
# make changes instead to dist.ini

my %modules;
my $post_diag;

$modules{$_} = $_ for qw(
  Alien::Base
  Alien::FFI
  Config::AutoConf
  ExtUtils::CBuilder
  FFI::CheckLib
  File::ShareDir
  JSON::PP
  Module::Build
  PkgConfig
  Test::More
  constant
);

$post_diag = sub {
  eval {
    use Alien::FFI;
    use FFI::Platypus;
    use FFI::Platypus::ConfigData;
    use Module::Build::FFI;
    diag "Alien::FFI version       = ", $Alien::FFI::VERSION;
    diag "Alien::FFI->install_type = ", Alien::FFI->install_type;
    diag "Alien::FFI->cflags       = ", Alien::FFI->cflags;
    diag "Alien::FFI->libs         = ", Alien::FFI->libs;
    diag "Alien::FFI->dist_dir     = ", eval { Alien::FFI->dist_dir } || 'undef';
    diag "Alien::FFI->version      = ", eval { Alien::FFI->config('version') } || 'unknown';
    spacer();
    diag "dlext[]=$_" for Module::Build::FFI->ffi_dlext;
    my %type_map = %{ FFI::Platypus::ConfigData->config('type_map') };
    my $diag = FFI::Platypus::ConfigData->config('diag');
    foreach my $key (sort keys %{ $diag->{args} })
    {
      diag "mb.args.$key=", $diag->{args}->{$key};
    }
    foreach my $key (sort keys %{ $diag->{config} })
    {
      diag "config.$key=", $diag->{config}->{$key};
    }
    spacer();
    my %r;
    while(my($k,$v) = each %type_map)
    {
      push @{ $r{$v} }, $k;
    }
    diag "Types:";
    foreach my $type (sort keys %r)
    {
      diag sprintf("  %-8s : %s", $type, join(', ', sort @{ $r{$type} }));
    }
    spacer();
    my $abi = FFI::Platypus->abis;
    diag "ABIs:";
    foreach my $key (sort keys %$abi)
    {
      diag sprintf("  %-20s %s", $key, $abi->{$key});
    }
  };
  diag "extended diagnostic failed: $@" if $@;
};

my @modules = sort keys %modules;

sub spacer ()
{
  diag '';
  diag '';
  diag '';
}

pass 'okay';

my $max = 1;
$max = $_ > $max ? $_ : $max for map { length $_ } @modules;
our $format = "%-${max}s %s"; 

spacer;

my @keys = sort grep /(MOJO|PERL|\A(LC|HARNESS)_|\A(SHELL|LANG)\Z)/i, keys %ENV;

if(@keys > 0)
{
  diag "$_=$ENV{$_}" for @keys;
  
  if($ENV{PERL5LIB})
  {
    spacer;
    diag "PERL5LIB path";
    diag $_ for split $Config{path_sep}, $ENV{PERL5LIB};
    
  }
  elsif($ENV{PERLLIB})
  {
    spacer;
    diag "PERLLIB path";
    diag $_ for split $Config{path_sep}, $ENV{PERLLIB};
  }
  
  spacer;
}

diag sprintf $format, 'perl ', $];

foreach my $module (@modules)
{
  if(eval qq{ require $module; 1 })
  {
    my $ver = eval qq{ \$$module\::VERSION };
    $ver = 'undef' unless defined $ver;
    diag sprintf $format, $module, $ver;
  }
  else
  {
    diag sprintf $format, $module, '-';
  }
}

if($post_diag)
{
  spacer;
  $post_diag->();
}

spacer;

