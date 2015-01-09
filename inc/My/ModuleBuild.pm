package My::ModuleBuild;

use strict;
use warnings;
use Alien::FFI;
use My::LibTest;
use My::AutoConf;
use ExtUtils::CBuilder;
use File::Glob qw( bsd_glob );
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
      if($value =~ s/-O[0-9]?/-g3/g)
      {
        print "  + \$Config{$key} = ", $config->{$key}, "\n";
        print "  - \$Config{$key} = $value\n";
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
    '*.core',
    'core',
  );

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

sub ACTION_build
{
  my $self = shift;
  
  my $b = ExtUtils::CBuilder->new;
  
  my($header_time) = reverse sort map { (stat $_)[9] } bsd_glob "include/*.h";
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
  $self->SUPER::ACTION_build(@_);
}

sub ACTION_libtest
{
  my($self) = @_;
  $self->depends_on('ac');
  My::LibTest->build(shift);
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
