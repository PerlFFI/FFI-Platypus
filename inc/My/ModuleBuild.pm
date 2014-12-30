package My::ModuleBuild;

use strict;
use warnings;
use Alien::FFI;
use My::Util;
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
  );
  
  $self;
}

sub ACTION_build_libtest
{
  My::Util->build_libtest;
}

sub ACTION_test {
  my $self = shift;
  $self->depends_on('build_libtest');
  $self->SUPER::ACTION_test;
}

1;
