package My::Probe;

use strict;
use warnings;
use File::Glob qw( bsd_glob );
use ExtUtils::CBuilder;
use File::Spec;
use Alien::FFI;

sub probe
{
  my($class, $mb) = @_;
  
  my $probe_include = File::Spec->catfile('include', 'ffi_platypus_probe.h');

  $DB::single = 1;  
  return if -e $probe_include && $mb && $mb->config_data('probe');
  
  $mb->add_to_cleanup($probe_include);
  do {
    my $fh;
    open $fh, '>', $probe_include;
    close $fh;
  };
  
  my $b = ExtUtils::CBuilder->new;

  my %probe;
  
  foreach my $cfile (bsd_glob 'inc/probe/*.c')
  {
    my $name = (File::Spec->splitpath($cfile))[2];
    $name =~ s{\.c$}{};
    
    my $obj = $b->compile(
      source               => $cfile,
      include_dirs         => [ 'include' ],
      extra_compiler_flags => Alien::FFI->cflags,
    );
    $mb->add_to_cleanup($obj) if $mb;
    
    my($exe,@rest) = $b->link_executable(
      objects            => $obj,
      extra_linker_flags => Alien::FFI->libs,
    );
    $mb->add_to_cleanup($exe,@rest) if $mb;
    my @cmd = ($exe, '--test');
    print "@cmd\n";
    system @cmd;
    my $ret = $?;
    if($ret == -1)
    { print "FAILED TO EXECUTE $!\n" }
    elsif($ret & 127)
    { print "DIED with siganl ", ($ret & 127), "\n" }
    else
    { print "exit = ", $ret >> 8, "\n" }
    $probe{$name} = 1 if $? == 0;
  }
  
  do {
    my $fh;
    open $fh, '>', $probe_include;
    print $fh "#ifndef FFI_PLATYPUS_PROBE_H\n";
    print $fh "#define FFI_PLATYPUS_PROBE_H\n";
    
    foreach my $key (sort keys %probe)
    {
      print $fh "#define FFI_PL_PROBE_", uc($key), " 1\n";
    }
    
    print $fh "#endif\n";
    close $fh;
  };
  
  $mb->config_data( probe => \%probe ) if $mb;
  
  return;
}

1;
