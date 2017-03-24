package My::MakeMaker;

# This does not work.  It is interesting, in playing around it
# showed me some more limitations to MakeMaker, and the pitfalls
# of trying to migrate from MB to MM for a use of MB as customized
# as FFI::Platypus uses.

use strict;
use warnings;
use Config;
use My::ShareConfig;
use My::AutoConf;
use File::Glob qw( bsd_glob );
use Alien::FFI;
use File::ShareDir::Install ();
use Text::ParseWords qw( shellwords );

my $share_config = My::ShareConfig->new;

sub modify_args
{
  my(undef, $args) = @_;
  
  $args->{OBJECT}  = [map { s/\.c$/$Config{obj_ext}/; $_ } bsd_glob "xs/*.c"];
  $args->{CCFLAGS} = Alien::FFI->cflags;
  $args->{LIBS}    = [ Alien::FFI->libs ];
  $args->{INC}     = '-Iinclude';
  $args->{PREREQ_PM}->{'Math::Int64'} = '0.34'
    if $ENV{FFI_PLATYPUS_DEBUG_FAKE32} || $Config{uvsize} < 8;
  
  if($^O eq 'MSWin32' && $Config{ccname} eq 'cl')
  {
    push @{ $args->{LIBS} }, 'psapi.lib';
  }
  elsif($^O =~ /^(MSWin32|cygwin|msys)$/)
  {
    # TODO: ac this bad boy ?
    push @{ $args->{LIBS} }, '-L/usr/lib/w32api' if $^O =~ /^(cygwin|msys)$/;
    push @{ $args->{LIBS} }, '-lpsapi';
  }

  $share_config->set(extra_compiler_flags => [ shellwords $args->{CCFLAGS} ]);
  $share_config->set(extra_linker_flags   => [ @{ $args->{LIBS} } ]);  
  $args->{CCFLAGS} = "@{[ $args->{CCFLAGS} ]} $Config{ccflags}";
  $share_config->set(ccflags => $args->{CCFLAGS});
}

package MY;

sub postamble
{
  MY2::postamble(@_) .

  "\n\n" .
 
  "config :: _mm/probe _mm/config\n\n" . 
  
  "_mm :\n" .
  "\t\$(FULLPERL) -Iinc -MMy::MakeMaker -e action_mm\n" .
  "\t\$(TOUCH) _mm/mm\n\n" .

  "_mm/ac my_ac : _mm\n" .
  "\t\$(FULLPERL) -Iinc -MMy::MakeMaker -e action_ac\n" . 
  "\t\$(TOUCH) _mm/ac\n\n" .

  "my_ac_clean :\n" .
  "\t\$(FULLPERL) -Iinc -MMy::MakeMaker -e action_ac_clean\n" . 
  "\t\$(RM_F) _mm/ac\n\n" .
  
  "_mm/probe my_probe : _mm/ac\n" .
  "\t\$(FULLPERL) -Iinc -MMy::MakeMaker -e action_probe\n" .
  "\t\$(TOUCH) _mm/probe\n\n" .
  
  "clean ::\n" .
  "\t\$(FULLPERL) -Iinc -MMy::MakeMaker -e action_clean\n" .
  "\t\$(RM_RF) _mm\n\n";
}

package main;

use File::Glob qw( bsd_glob );

sub action_mm
{
  mkdir '_mm';
}

sub action_ac
{
  My::AutoConf->configure;
}

sub action_ac_clean
{
  My::AutoConf->clean;
}

sub action_probe
{
  require My::Probe;
  require ExtUtils::CBuilder;
  My::Probe->probe(
    ExtUtils::CBuilder->new( config => { ccflags => $share_config->get('ccflags') }),
    [],
    $share_config->get('extra_linker_flags'),
  );
  unlink $_ for My::Probe->cleanup;
}

sub action_clean
{
  My::AutoConf->clean;
  unlink $_ for map { bsd_glob($_) } (
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
    'share/config.json',
    'include/ffi_platypus_config.h',
  );
}

1;
