package My::ModuleBuild;

use strict;
use warnings;
use Alien::FFI;
use My::LibTest;
use My::AutoConf;
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;

  $args{c_source}             = 'xs';  
  $args{extra_compiler_flags} = Alien::FFI->cflags;
  $args{extra_linker_flags}   = Alien::FFI->libs;
  
  my $self = $class->SUPER::new(%args);

  $self->add_to_cleanup(
    'libtest/*.o',
    'libtest/*.obj',
    'libtest/*.so',
    'libtest/*.dll',
    'libtest/*.bundle',
    'xs/ffi_platypus_config.h',
    'config.log',
  );
  
  $self;
}

sub ACTION_build_configure
{
  my($self) = @_;
  return if $self->config_data('done_build_configure');
  My::AutoConf->build_configure($self);
  $self->config_data('done_build_configure' => 1);
}

sub ACTION_build
{
  my $self = shift;
  $self->depends_on('build_configure');
  $self->SUPER::ACTION_build(@_);
}

sub ACTION_build_libtest
{
  my($self) = @_;
  return if $self->config_data('done_build_libtest');
  My::LibTest->build_libtest(shift);
  $self->config_data('done_build_libtest' => 1);
}

sub ACTION_test
{
  my $self = shift;
  $self->depends_on('build_libtest');
  $self->SUPER::ACTION_test(@_);
}

sub ACTION_clean
{
  my $self = shift;
  $self->config_data(done_build_libtest   => 0);
  $self->config_data(done_build_configure => 0);
  $self->SUPER::ACTION_clean(@_);
}

1;
