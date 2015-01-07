package My::ModuleBuild;

use strict;
use warnings;
use Alien::FFI;
use My::LibTest;
use My::AutoConf;
use Config;
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;

  $args{c_source}             = 'xs';  
  $args{include_dirs}         = 'include';
  $args{extra_compiler_flags} = Alien::FFI->cflags;
  $args{extra_linker_flags}   = Alien::FFI->libs;
  $args{requires}->{'Math::Int64'} = '0.34' if $Config{uvsize} < 8;

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

  my $self = $class->SUPER::new(%args);

  if($ENV{FFI_PLATYPUS_DEBUG})
  {
    my $config = $self->config;
    print "\n\n";
    print "DEBUG:\n";
    foreach my $key (keys %Config)
    {
      my $value = $Config{$key};
      next unless defined $value;
      if($value =~ s/-O[0-9]/-g3/g)
      {
        print "  + \$Config{$key} = ", $config->{$key}, "\n";
        print "  - \$Config{$key} = $Config{$key}\n";
        $self->config($key, $value);
      }
    }
    print "\n\n";
  }
  
  $self->add_to_cleanup(
    'libtest/*.o',
    'libtest/*.obj',
    'libtest/*.so',
    'libtest/*.dll',
    'libtest/*.bundle',
    'xs/ffi_platypus_config.h',
    'config.log',
    'test*.o',
    'test*.c',
  );
  
  $self->config_data(done_libtest   => 0);
  $self->config_data(done_ac => 0);

  $self;
}

sub ACTION_ac
{
  my($self) = @_;
  My::AutoConf->build_configure($self);
  $self->config_data('done_ac' => 1);
}

sub ACTION_build
{
  my $self = shift;
  
  if(-e "lib/FFI/Platypus.c"
  && -e "lib/FFI/Platypus.o")
  {
    if((stat "lib/FFI/Platypus.c")[9] < (stat "include/ffi_platypus_call.h")[9])
    {
      unlink "lib/FFI/Platypus.c";
      unlink "lib/FFI/Platypus.o";
    }
  }
  
  $self->depends_on('ac') unless $self->config_data('done_ac');
  $self->SUPER::ACTION_build(@_);
}

sub ACTION_libtest
{
  my($self) = @_;
  My::LibTest->build_libtest(shift);
  $self->config_data('done_libtest' => 1);
}

sub ACTION_test
{
  my $self = shift;
  $self->depends_on('libtest') unless $self->config_data('done_libtest');
  $self->SUPER::ACTION_test(@_);
}

sub ACTION_clean
{
  my $self = shift;
  $self->config_data(done_libtest   => 0);
  $self->config_data(done_ac => 0);
  $self->SUPER::ACTION_clean(@_);
}

1;
