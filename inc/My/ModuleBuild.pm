package My::ModuleBuild;

use strict;
use warnings;
use 5.008001;
use Alien::FFI;
use My::LibTest;
use My::AutoConf;
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
  elsif($^O =~ /^(MSWin32|cygwin)$/)
  {
    # TODO: ac this bad boy ?
    $args{extra_linker_flags} .= " -L/usr/lib/w32api" if $^O eq 'cygwin';
    $args{extra_linker_flags} .= " -lpsapi";
  }

  my $strawberry_lddlflags;
  
  if($^O eq 'MSWin32' && $Config{myuname} =~ /strawberry-perl/ && $] >= 5.020)
  {
    # On Strawberry Perl (let me count the ways...) the c/lib directory gets 
    # inserted before the Alien::FFI -L directory, meaning if you do an
    # ALIEN_FORCE=1 install of Alien::FFI you get a header file / lib mismatch
    # and shit breaks.  To work around this we reorder the flags.
    
    if(Alien::FFI->install_type eq 'share')
    {
      $strawberry_lddlflags = '';
      my $lddlflags = $Config{lddlflags};
      $lddlflags =~ s{\\}{/}g;
      my @lddlflags = shellwords $lddlflags;
      foreach my $flag (@lddlflags)
      {
        if($flag =~ m!^-L.*/c/lib$!)
        {
          $args{extra_linker_flags} .= " $flag";
        }
        else
        {
          $strawberry_lddlflags .= "$flag ";
        }
      }
      $strawberry_lddlflags =~ s{\s+$}{};
    }
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

  if(defined $strawberry_lddlflags)
  {
    $self->config(lddlflags => $strawberry_lddlflags);
    $diag{config}->{lddlflags} = $strawberry_lddlflags;
    print "\n\n";
    print "Strawberry Perl work around:\n";
    print "  - \$Config{lddlflags} = $Config{lddlflags}\n";
    print "  + \$Config{lddlflags} = $strawberry_lddlflags\n";
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
  push @dlext, 'dll'             if $^O =~ /^(cygwin|MSWin32)$/;
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
