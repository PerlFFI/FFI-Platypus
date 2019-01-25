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
  Capture::Tiny
  ExtUtils::CBuilder
  ExtUtils::MakeMaker
  FFI::CheckLib
  IPC::Cmd
  JSON::PP
  List::Util
  PkgConfig
  Test::More
  constant
);

$post_diag = sub {
  eval {
    use lib 'inc';
    require FFI::Platypus::ShareConfig;
    my $share_config = 'FFI::Platypus::ShareConfig';
    my $class = $share_config->get('alien')->{class};
    my $pm = "$class.pm";
    $pm =~ s/::/\//g;
    require $pm;
    $Alien::FFI::pkgconfig::VERBOSE =
    $Alien::FFI::pkgconfig::VERBOSE = 0;
    use FFI::Platypus;
    use FFI::Platypus::Memory;
    diag "mode : ", $share_config->get('alien')->{mode};
    diag "$class->VERSION      = ", $class->VERSION;
    diag "$class->install_type = ", $class->install_type;
    diag "$class->cflags       = ", $class->cflags;
    diag "$class->libs         = ", $class->libs;
    diag "$class->dist_dir     = ", eval { $class->dist_dir } || 'undef';
    diag "$class->version      = ", eval { $class->config('version') } || 'unknown';
    diag "my_configure             = ", $class->runtime_prop->{my_configure} if defined $class->runtime_prop->{my_configure};
    spacer();
    my %type_map = %{ $share_config->get('type_map') };
    my $diag = $share_config->get('diag');
    foreach my $key (sort keys %{ $diag->{args} })
    {
      diag "mb.args.$key=", $diag->{args}->{$key};
    }
    foreach my $key (sort keys %{ $diag->{config} })
    {
      diag "config.$key=", $diag->{config}->{$key};
    }
    diag "ffi.platypus.memory.strdup_impl =@{[ FFI::Platypus::Memory->_strdup_impl ]}";
    diag "ffi.platypus.memory.strndup_impl=@{[ FFI::Platypus::Memory->_strndup_impl ]}";
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
    spacer();
    diag "Probes:";
    my $probe = $share_config->get("probe");
    diag sprintf("  %-20s %s", $_, $probe->{$_}) for keys %$probe;
  };
  diag "extended diagnostic failed: $@" if $@;
  if(-f "/proc/cpuinfo")
  {
    open my $fh, '<', '/proc/cpuinfo';
    my @lines = <$fh>;
    close $fh;
    my($model_name)    = grep /^model name/, @lines;
    my($flags)         = grep /^flags/, @lines;
    my($address_sizes) = grep /^address sizes/, @lines;
    spacer();
    diag "CPU Info:";
    diag "  $model_name";
    diag "  $flags" if $flags;;
    diag "  $address_sizes" if $address_sizes;
  }
  require IPC::Cmd;
  require Capture::Tiny;
  if(IPC::Cmd::can_run('lsb_release'))
  {
    spacer();
    diag Capture::Tiny::capture_merged(sub {
      system 'lsb_release', '-a';
      ();
    });
  }
  require FFI::Build::Platform;
  spacer();
  diag "[PLATFORM]\n";
  diag(FFI::Build::Platform->diag);
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

