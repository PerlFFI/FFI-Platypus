package mymm;

use strict;
use warnings;
use Config;
use File::Glob qw( bsd_glob );
use ExtUtils::MakeMaker ();
use Text::ParseWords qw( shellwords );
use lib 'inc';
use My::ShareConfig;

sub myWriteMakefile
{
  my %args = @_;
  my $share_config = My::ShareConfig->new;

  ExtUtils::MakeMaker->VERSION('7.12');
  require Alien::Base::Wrapper;
  Alien::Base::Wrapper->import( 'Alien::FFI', 'My::psapi', '!export' );
  my %alien = Alien::Base::Wrapper->mm_args;
  $alien{INC} = defined $alien{INC} ? "-Iinclude $alien{INC}" : "-Iinclude";

  %args = (%args, %alien);

  delete $args{PM};
  $args{XSMULTI} = 1;
  $args{XSBUILD} = {
    xs => {
      'lib/FFI/Platypus' => {
        OBJECT => 'lib/FFI/Platypus$(OBJ_EXT) ' . join(' ', map { s/\.c$/\$(OBJ_EXT)/; $_ } bsd_glob "xs/*.c"),
        %alien,
      },
    },
  };

  $args{PREREQ_PM}->{'Math::Int64'} = '0.34'
    if $ENV{FFI_PLATYPUS_DEBUG_FAKE32} || $Config{uvsize} < 8;

  $share_config->set(extra_compiler_flags => [ shellwords(Alien::FFI->cflags) ]);
  $share_config->set(extra_linker_flags   => [ shellwords(Alien::FFI->libs) ]);  
  $share_config->set(ccflags => Alien::FFI->cflags);

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

  $share_config->set(config_dlext => \@dlext);

  ExtUtils::MakeMaker::WriteMakefile(%args);
}

package MY;

sub dynamic_lib
{
  my($self, @therest) = @_;
  my $dynamic_lib = $self->SUPER::dynamic_lib(@therest);
  $dynamic_lib .= "\nlib/FFI/Platypus.c : mymm_config\n";
  my %o = map { $_ => 1 } $dynamic_lib =~ /(\S+\$\(OBJ_EXT\))/g;
  foreach my $o (sort keys %o)
  {
    $dynamic_lib .= "$o : mymm_config\n";
  }
  $dynamic_lib;
}

1;
