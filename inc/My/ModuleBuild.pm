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
  My::AutoConf->build_configure(shift);
}

sub ACTION_build
{
  my $self = shift;
  $self->depends_on('build_configure');
  $self->SUPER::ACTION_build(@_);
}

sub ACTION_build_libtest
{
  My::LibTest->build_libtest(shift);
}

sub ACTION_test
{
  my $self = shift;
  $self->depends_on('build_libtest');
  $self->SUPER::ACTION_test(@_);
}

1;
