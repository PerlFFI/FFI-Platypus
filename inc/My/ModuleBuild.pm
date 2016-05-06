package My::ModuleBuild;

use strict;
use warnings;
use 5.008001;
use Alien::FFI;
use My::LibTest;
use My::AutoConf;
use My::Dev;
use ExtUtils::CBuilder;
use File::Glob qw( bsd_glob );
use Config;
use Text::ParseWords qw( shellwords );
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;

  my %diag;

  if($^O eq 'openbsd' && !$Config{usethreads} && Alien::FFI->install_type eq 'system')
  {
    print "Configuration not supported.\n";
    print "Please reinstall Alien::FFI with ALIEN_FORCE=1\n";
    print "See https://github.com/plicease/FFI-Platypus/issues/19\n";
    exit 0;
  }

  $args{c_source}             = 'xs';  
  $args{include_dirs}         = 'include';
  $args{extra_compiler_flags} = Alien::FFI->cflags;
  $args{extra_linker_flags}   = Alien::FFI->libs;
  $args{requires}->{'Math::Int64'} = '0.34' if $ENV{FFI_PLATYPUS_DEBUG_FAKE32} || $Config{uvsize} < 8;

  if($^O eq 'MSWin32' && $Config{cc} =~ /cl(\.exe)?$/i)
  {
    $args{extra_linker_flags} .= ' psapi.lib';
  }
  elsif($^O =~ /^(MSWin32|cygwin|msys)$/)
  {
    # TODO: ac this bad boy ?
    $args{extra_linker_flags} .= " -L/usr/lib/w32api" if $^O =~ /^(cygwin|msys)$/;
    $args{extra_linker_flags} .= " -lpsapi";
  }

  my $lddlflags = $Config{lddlflags};
  my $ldflags   = $Config{ldflags};
  my $ccflags   = $Config{ccflags};
  
  if($^O eq 'darwin')
  {
    # strip the -arch flags on darwin / os x.
    my @lddlflags_in = shellwords $lddlflags;
    my @lddlflags;
    while(@lddlflags_in)
    {
      my $arg = shift @lddlflags_in;
      if($arg eq '-arch')
      {
        shift @lddlflags_in;
      }
      else
      {
        push @lddlflags, $arg;
      }
    }
    $lddlflags = "@lddlflags";

    my @ldflags_in = shellwords $ldflags;
    my @ldflags;
    while(@ldflags_in)
    {
      my $arg = shift @ldflags_in;
      if($arg eq '-arch')
      {
        shift @ldflags_in;
      }
      else
      {
        push @ldflags, $arg;
      }
    }
    $ldflags = "@ldflags";

    my @ccflags_in = shellwords $ccflags;
    my @ccflags;
    while(@ccflags_in)
    {
      my $arg = shift @ccflags_in;
      if($arg eq '-arch')
      {
        shift @ccflags_in;
      }
      else
      {
        push @ccflags, $arg;
      }
    }
    $ccflags = "@ccflags";
  }

  # on some configurations (eg. Solaris 64 bit, Strawberry Perl)
  # -L flags are included in the lddlflags configuration, but we
  # need to make sure OUR -L comes first
  my @libdirflags = grep /^-L/, shellwords(Alien::FFI->libs);
  if(@libdirflags)
  {
    $lddlflags = join ' ', @libdirflags, $lddlflags;
  }
  
  if($^O eq 'MSWin32')
  {
    # needed by My/Probe.pm on any MSWin32 platform
    $args{build_requires}->{'Win32::ErrorMode'} = 0;
  }
  
  $diag{args}->{extra_compiler_flags} = $args{extra_compiler_flags};
  $diag{args}->{extra_linker_flags}   = $args{extra_linker_flags};
  
  my $self = $class->SUPER::new(%args);

  print "\n\n";
  print "CONFIGURE\n";
  print "  + \$args{extra_compiler_flags} = $args{extra_compiler_flags}\n";
  print "  + \$args{extra_linker_flags} = $args{extra_linker_flags}\n";
  print "\n\n";

  if($ENV{FFI_PLATYPUS_DEBUG})
  {
    my $config = $self->config;
    print "\n\n";
    print "DEBUG:\n";
    foreach my $key (keys %Config)
    {
      my $value = $Config{$key};
      next unless defined $value;
      if($value =~ s/-O[0-9]?/-g3/g)
      {
        print "  - \$Config{$key} = ", $config->{$key}, "\n";
        print "  + \$Config{$key} = $value\n";
        $self->config($key, $value);
        $diag{config}->{$key} = $value;
      }
    }
    print "\n\n";
  }
  if($ENV{FFI_PLATYPUS_DEBUG_FAKE32} && $Config{uvsize} == 8)
  {
    print "\n\n";
    print "DEBUG_FAKE32:\n";
    print "  + making Math::Int64 a prerequsite (not normally done on 64 bit Perls)\n";
    print "  + using Math::Int64's C API to manipulate 64 bit values (not normally done on 64 bit Perls)\n";
    print "\n\n";
    $self->config_data(config_debug_fake32 => 1);
    $diag{config}->{config_debug_fake32} = 1;
  }
  if($ENV{FFI_PLATYPUS_NO_ALLOCA})
  {
    print "\n\n";
    print "NO_ALLOCA:\n";
    print "  + alloca() will not be used, even if your platform supports it.\n";
    print "\n\n";
    $self->config_data(config_no_alloca => 1);
    $diag{config}->{config_no_alloca} = 1;
  }

  if($lddlflags ne $Config{lddlflags})
  {
    $self->config(lddlflags => $lddlflags);
    $diag{config}->{lddlflags} = $lddlflags;
    print "\n\n";
    print "Adjusted lddlflags:\n";
    print "  - \$Config{lddlflags} = $Config{lddlflags}\n";
    print "  + \$Config{lddlflags} = $lddlflags\n";
    print "\n\n";
  }

  if($ldflags ne $Config{ldflags})
  {
    $self->config(ldflags => $ldflags);
    $diag{config}->{ldflags} = $ldflags;
    print "\n\n";
    print "Adjusted ldflags:\n";
    print "  - \$Config{ldflags} = $Config{ldflags}\n";
    print "  + \$Config{ldflags} = $ldflags\n";
    print "\n\n";
  }

  if($ccflags ne $Config{ccflags})
  {
    $self->config(ccflags => $ccflags);
    $diag{config}->{ccflags} = $ccflags;
    print "\n\n";
    print "Adjusted ccflags:\n";
    print "  - \$Config{ccflags} = $Config{ccflags}\n";
    print "  + \$Config{ccflags} = $ccflags\n";
    print "\n\n";
  }

  $self->add_to_cleanup(
    'libtest/*.o',
    'libtest/*.obj',
    'libtest/*.so',
    'libtest/*.dll',
    'libtest/*.bundle',
    'examples/*.o',
    'examples/*.so',
    'examples/*.dll',
    'examples/*.bundle',
    'examples/java/*.so',
    'examples/java/*.o',
    'xs/ffi_platypus_config.h',
    'config.log',
    'test*.o',
    'test*.c',
    '*.core',
    'Build.bat',
    'build.bat',
    'core',
  );

  # dlext as understood by MB and MM
  my @dlext = ($Config{dlext});
  
  # extra dlext as understood by the OS
  push @dlext, 'dll'             if $^O =~ /^(cygwin|MSWin32|msys)$/;
  push @dlext, 'xs.dll'          if $^O =~ /^(MSWin32)$/;
  push @dlext, 'so'              if $^O =~ /^(cygwin|darwin)$/;
  push @dlext, 'bundle', 'dylib' if $^O =~ /^(darwin)$/;

  # uniq'ify it
  @dlext = do { my %seen; grep { !$seen{$_}++ } @dlext };

  #print "dlext[]=$_\n" for @dlext;

  $self->config_data(diag => \%diag);
  $self->config_data(config_dlext => \@dlext);

  $self;
}

sub ACTION_ac
{
  my($self) = @_;
  My::AutoConf->configure($self);
}

sub ACTION_ac_clean
{
  my($self) = @_;
  My::AutoConf->clean($self);
}

sub ACTION_probe
{
  my($self) = @_;
  $self->depends_on('ac');
  require My::Probe;
  My::Probe->probe($self);
}

sub ACTION_build
{
  my $self = shift;
  
  my $b = ExtUtils::CBuilder->new;
  
  My::Dev->generate;
  
  my($header_time) = reverse sort map { (stat $_)[9] } map { bsd_glob($_) } qw( include/*.h xs/*.xs);
  my $c = File::Spec->catfile(qw(lib FFI Platypus.c));
  my($obj) = $b->object_file($c);
  my $obj_time = (stat $obj)[9];
  $obj_time ||= 0;
  
  if($obj_time < $header_time)
  {
    unlink $obj;
    unlink $c;
  }

  $self->depends_on('ac');
  $self->depends_on('probe');
  $self->SUPER::ACTION_build(@_);
}

sub ACTION_libtest
{
  my($self) = @_;
  $self->depends_on('ac');
  $self->depends_on('probe');
  My::LibTest->build($self);
}

sub ACTION_test
{
  my $self = shift;
  $self->depends_on('libtest');
  $self->SUPER::ACTION_test(@_);
}

sub ACTION_distclean
{
  my($self) = @_;
  
  $self->depends_on('realclean');
}

1;
