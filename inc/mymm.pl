package mymm;

use strict;
use warnings;
use Config;
use File::Glob qw( bsd_glob );
use ExtUtils::MakeMaker ();
use IPC::Cmd ();
use lib 'inc';
use File::Spec;
use My::BuildConfig;
use My::ShareConfig;

{
  my $dh;
  opendir $dh, 'inc';
  my @files = map { File::Spec->catfile('inc', $_) } grep /^bad-.*\.pl$/, readdir $dh;
  close $dh;

  foreach my $badcheck (@files)
  {
    system $^X, $badcheck;
    if($?)
    {
      print "bad check $badcheck failed\n";
      exit;
    }
  }
}

sub vcpkg
{
  return unless $Config{ccname} eq 'cl';
  require Alien::FFI::Vcpkg;
  !!eval { Alien::FFI::Vcpkg->vcpkg }
}

sub myWriteMakefile
{
  my %args = @_;
  my $build_config = My::BuildConfig->new;
  my $share_config = My::ShareConfig->new;
  my %diag;
  my %alien;

  ExtUtils::MakeMaker->VERSION('7.12');
  $build_config->set(version => [ $args{VERSION} =~ /^([0-9]+)\.([0-9]{2})/ ]);

  if(eval { require Alien::FFI; Alien::FFI->VERSION('0.20'); 1 })
  {
    print "using already installed Alien::FFI (version @{[ Alien::FFI->VERSION ]})\n";
    $build_config->set(alien => { class => 'Alien::FFI', mode => 'already-installed' });
    require Alien::Base::Wrapper;
    Alien::Base::Wrapper->import( 'Alien::FFI', 'Alien::psapi', '!export' );
    %alien = Alien::Base::Wrapper->mm_args;
  }
  elsif(vcpkg())
  {
    print "using vcpkg libffi package\n";
    $build_config->set(alien => { class => 'Alien::FFI::Vcpkg', mode => 'system' });
    require Alien::Base::Wrapper;
    Alien::Base::Wrapper->import( 'Alien::FFI::Vcpkg', '!export');
    %alien = Alien::Base::Wrapper->mm_args;
    delete $args{BUILD_REQUIRES}->{'Alien::FFI'};
  }
  else
  {
    require Alien::FFI::pkgconfig    if $^O ne 'MSWin32';
    require Alien::FFI::PkgConfigPP  if $^O eq 'MSWin32';

    my $alien_install_type_unset = !defined $ENV{ALIEN_INSTALL_TYPE};

    if($alien_install_type_unset && $^O eq 'MSWin32' && Alien::FFI::PkgConfigPP->exists)
    {
      print "using system libffia via PkgConfigPP\n";
      $build_config->set(alien => { class => 'Alien::FFI::PkgConfigPP', mode => 'system' });
      require Alien::Base::Wrapper;
      Alien::Base::Wrapper->import( 'Alien::FFI::PkgConfigPP', 'Alien::psapi', '!export' );
      %alien = Alien::Base::Wrapper->mm_args;
      delete $args{BUILD_REQUIRES}->{'Alien::FFI'};
    }
    elsif($alien_install_type_unset && $^O ne 'MSWin32' && Alien::FFI::pkgconfig->exists)
    {
      print "using system libffi via @{[ Alien::FFI::pkgconfig->pkg_config_exe ]}\n";
      $build_config->set(alien => { class => 'Alien::FFI::pkgconfig', mode => 'system' });
      require Alien::Base::Wrapper;
      Alien::Base::Wrapper->import( 'Alien::FFI::pkgconfig', 'Alien::psapi', '!export' );
      %alien = Alien::Base::Wrapper->mm_args;
      delete $args{BUILD_REQUIRES}->{'Alien::FFI'};
    }
    else
    {
      print "requiring Alien::FFI in fallback mode.\n";
    $build_config->set(alien => { class => 'Alien::FFI', mode => 'fallback' });
      %alien = (
        CC => '$(FULLPERL) -Iinc -MAlien::Base::Wrapper=Alien::FFI,Alien::psapi -e cc --',
        LD => '$(FULLPERL) -Iinc -MAlien::Base::Wrapper=Alien::FFI,Alien::psapi -e ld --',
      );
    }
  }
  $alien{INC} = defined $alien{INC} ? "-Iinclude $alien{INC}" : "-Iinclude";

  %args = (%args, %alien);

  if($ENV{FFI_PLATYPUS_DEBUG_FAKE32} || $Config{uvsize} < 8)
  {
    $args{BUILD_REQUIRES}->{'Math::Int64'} = '0.34';
  }

  if($ENV{FFI_PLATYPUS_DEBUG_FAKE32} && $Config{uvsize} == 8)
  {
    print "DEBUG_FAKE32:\n";
    print "  + making Math::Int64 a prereq\n";
    print "  + Using Math::Int64's C API to manipulate 64 bit values\n";
    $build_config->set(config_debug_fake32 => 1);
    $diag{config}->{config_debug_fake32} = 1;
  }
  if($ENV{FFI_PLATYPUS_NO_ALLOCA})
  {
    print "NO_ALLOCA:\n";
    print "  + alloca() will not be used, even if your platform supports it.\n";
    $build_config->set(config_no_alloca => 1);
    $diag{config}->{config_no_alloca} = 1;
  }

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

  # dlext as understood by MB and MM
  my @dlext = ($Config{dlext});

  # extra dlext as understood by the OS
  push @dlext, 'dll'             if $^O =~ /^(cygwin|MSWin32|msys)$/;
  push @dlext, 'xs.dll'          if $^O =~ /^(MSWin32)$/;
  push @dlext, 'so'              if $^O =~ /^(cygwin|darwin)$/;
  push @dlext, 'bundle', 'dylib' if $^O =~ /^(darwin)$/;

  # uniq'ify it
  @dlext = do { my %seen; grep { !$seen{$_}++ } @dlext };

  $build_config->set(diag => \%diag);
  $share_config->set(config_dlext => \@dlext);

  ExtUtils::MakeMaker::WriteMakefile(%args);
}

#package MM;
#
#sub init_tools
#{
#  my $self = shift;
#  $self->SUPER::init_tools(@_);
#
#  return if !!$ENV{V};
#
#  my $noecho = $^O eq 'MSWin32' ? 'REM ' : '@';
#
#  foreach my $tool (qw( RM_F RM_RF CP MV ))
#  {
#    $self->{$tool} = $noecho . $self->{$tool};
#  }
#
#  return;
#}

package MY;

use Config;

sub dynamic_lib
{
  my($self, @therest) = @_;
  my $dynamic_lib = $self->SUPER::dynamic_lib(@therest);

  my %h = map { m!include/(.*?)$! && $1 => [$_] } File::Glob::bsd_glob('include/*.h');
  push @{ $h{"ffi_platypus.h"} }, map { "include/ffi_platypus_$_.h" } qw( config );

  my %targets = (
    'include/ffi_platypus_config.h' => ['_mm/config'],
    'lib/FFI/Platypus.c' => [File::Glob::bsd_glob('xs/*.xs'), 'lib/FFI/Platypus.xs', 'lib/FFI/typemap'],
  );

  foreach my $cfile (File::Glob::bsd_glob('xs/*.c'), 'lib/FFI/Platypus.c')
  {
    my $ofile = $cfile;
    $ofile =~ s/\.c$/\$(OBJ_EXT)/;

    my @deps = ($cfile, '_mm/config');

    if(-d ".git")
    {
      # for a development build, lets go ahead and compute the .h
      # dependencies to make it easier to do a partial rebuild.
      my $source_file = $cfile;
      $source_file = 'lib/FFI/Platypus.xs' if $source_file =~ /^lib\/FFI/;
      my $fh;
      open $fh, '<', $source_file;
      while(<$fh>)
      {
        if(/^#include [<"](.*?)[>"]/ && $h{$1})
        {
          push @deps, @{$h{$1}};
        }
      }
      close $fh;
    }

    $targets{$ofile} = \@deps;
  }

  $dynamic_lib .= "\n";

  foreach my $target (sort keys %targets)
  {
    $dynamic_lib .= "$target : @{$targets{$target}}\n";
  }

  $dynamic_lib;
}

sub postamble {
  my $postamble = '';

  my $noecho = !!$ENV{V} ? '' : '$(NOECHO) ';

  my $sep = $^O eq 'MSWin32' && $Config{make} eq 'nmake'
    ? '\\'
    : '/';

  $postamble .=
    "flags: _mm${sep}flags\n" .
    "_mm${sep}flags:\n";

  foreach my $key (qw( cc inc ccflags cccdlflags optimize ld ldflags lddlflags ))
  {
    $postamble .=
      sprintf "\t$noecho\$(FULLPERL) inc${sep}mm-config-set.pl %-20s \$(%s)\n", $key, uc $key;
  }

  $postamble .=
    "\t$noecho\$(MKPATH) _mm\n" .
    "\t$noecho\$(TOUCH) _mm${sep}flags\n\n";

  $postamble .=
    "probe-runner-builder prb: _mm${sep}probe-builder\n" .
    "_mm${sep}probe-builder: _mm${sep}flags\n" .
    "\t$noecho\$(FULLPERL) inc${sep}mm-config-pb.pl\n" .
    "\t$noecho\$(MKPATH) _mm\n" .
    "\t$noecho\$(TOUCH) _mm${sep}probe-builder\n\n";

  $postamble .=
    "config :: _mm${sep}config\n" .
    "_mm${sep}config: _mm${sep}flags _mm${sep}probe-builder\n" .
    "\t$noecho\$(FULLPERL) inc${sep}mm-config.pl\n" .
    "\t$noecho\$(MKPATH) _mm\n" .
    "\t$noecho\$(TOUCH) _mm${sep}config\n\n";

  $postamble .=
    "pure_all :: ffi\n" .
    "ffi: _mm${sep}config\n" .
    "\t$noecho\$(FULLPERL) inc${sep}mm-build.pl\n\n";

  $postamble .=
    "subdirs-test_dynamic subdirs-test_static subdirs-test :: ffi-test\n" .
    "ffi-test : _mm${sep}config\n" .
    "\t$noecho\$(FULLPERL) inc${sep}mm-test.pl\n\n";

  $postamble .=
    "clean :: mm-clean\n" .
    "mm-clean :\n" .
    "\t$noecho\$(FULLPERL) inc${sep}mm-clean.pl\n" .
    "\t$noecho\$(RM_RF) _mm ffi-probe-*\n" .
    "\t$noecho\$(RM_RF) .tmp\n" .
    "\t$noecho\$(RM_RF) corpus${sep}*${sep}*${sep}tmpbuild*\n\n";

  # Workaround for the tireless testers out there
  # who want to make -jX a thing.  For some reason.
  #
  # When bsd make is passed -jX it turns off compat
  # mode, even if the Makefile itself turns off
  # parallel build.  Unfortunately the Makefile
  # generated by EUMM does not work without compat
  # mode.  So we:
  $postamble .=
    # 1. turn off parallel build using the bsd-only
    #    faux rule `.NO_PARALLEL` rather than the
    #    more portable `.NOTPARALLEL`, because this
    #    will allow parallel build with gmake, which
    #    does work.
    ".NO_PARALLEL:\n\n";

  if($^O eq 'MSWin32' && $Config{ccname} eq 'cl')
  {
    # nothing.
  }
  else
  {
    $postamble .=
      # 2. turn compat mode back on.
      ".MAKE.MODE=compat\n\n";
  }

  $postamble;
}

sub special_targets {
  my($self, @therest) = @_;
  my $st = $self->SUPER::special_targets(@therest);
  $st .= "\n.PHONY: flags probe-runner-builder prb ffi ffi-test\n";
  $st;
}

1;
