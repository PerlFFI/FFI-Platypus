package My::Probe;

use strict;
use warnings;
use if $^O eq 'MSWin32', 'Win32::ErrorMode';
use File::Glob qw( bsd_glob );
use File::Spec;
use Config;
use File::Temp qw( tempdir );
use File::Copy qw( copy );
use File::Path qw( rmtree );

sub probe
{
  my($class, $mb) = @_;

  my $probe_include = File::Spec->catfile('include', 'ffi_platypus_probe.h');

  return if -e $probe_include && $mb && $mb->config_data('probe');
  
  $mb->add_to_cleanup($probe_include);
  do {
    my $fh;
    open $fh, '>', $probe_include;
    close $fh;
  };
  
  my $b = $mb->cbuilder;

  my %probe;
  
  foreach my $cfile (bsd_glob 'inc/probe/*.c')
  {
    my $name = (File::Spec->splitpath($cfile))[2];
    $name =~ s{\.c$}{};
    
    my $obj = eval { $b->compile(
      source               => $cfile,
      include_dirs         => [ 'include' ],
      extra_compiler_flags => $mb->extra_compiler_flags,
    ) };
    next if $@;
    $mb->add_to_cleanup($obj) if $mb;
    
    my($exe,@rest) = eval { $b->link_executable(
      objects            => $obj,
      extra_linker_flags => $mb->extra_linker_flags,
    ) };
    next if $@;
    $mb->add_to_cleanup($exe,@rest) if $mb;
    my $ret = run($exe, '--test');
    $probe{$name} = 1 if $ret == 0;
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
  
  $class->probe_abi($mb);
  
  $mb->config_data( probe => \%probe ) if $mb;
  
  return;
}

sub run
{
  my @cmd = @_;
  
  # 1. annoyance the first:
  # Strawberry Perl 5.20.0 and better comes with libffi
  # unfortunately it is distributed as a .dll and to make
  # things a little worse the .exe files generated for some
  # reason link to a .dll with a different name.
    
  if($^O eq 'MSWin32' && $Config{myuname} =~ /strawberry-perl/ && $] >= 5.020)
  {
    my($vol, $dir, $file) = File::Spec->splitpath($^X);
    my @dirs = File::Spec->splitdir($dir);
    splice @dirs, -3;
    my $path = (File::Spec->catdir($vol, @dirs, qw( c bin )));
    $path =~ s{\\}{/}g;
      
    my($dll) = bsd_glob("$path/libffi*.dll");
      
    my @cleanup;
    foreach my $line (`objdump -p $cmd[0]`)
    {
      next unless $line =~ /^\s+DLL Name: (libffi.*\.dll)/;
      my $want = $1;
      next if $dll eq $want;
      copy($dll, $want);
      push @cleanup, $want;
    }
  }
  
  # 2. annoyance the second
  # If there isa problem with the .exe generated it may pop up a
  # dialog, but we don't want to stop the build, as this may be
  # normal if the probe is supposed to fail.
  
  local $Win32::ErrorMode::ErrorMode = 0x3;
  
  print "@cmd\n";
  system @cmd;
  my $ret = $?;
  if($ret == -1)
  { print "FAILED TO EXECUTE $!\n" }
  elsif($ret & 127)
  { print "DIED with signal ", ($ret & 127), "\n" }
  else
  { print "exit = ", $ret >> 8, "\n" }
  
  $ret;
}

sub probe_abi
{
  my($class, $mb) = @_;
  
  print "probing for ABIs...\n";

  mkdir '.abi-probe-test';
  my $dir = tempdir( CLEANUP => 1, DIR => '.abi-probe-test' );
  my $file_c = File::Spec->catfile($dir, "ffitest.c");

  if($^O eq 'MSWin32' && $file_c =~ /\s/)
  {
    $file_c = Win32::GetShortPathName($file_c);
  }
  
  do {
    my $fh;
    open $fh, '>', $file_c;
    print $fh "#include <ffi.h>\n";
    close $fh;
  };

  my @cpp_flags = grep /^-[DI]/, @{ $mb->extra_compiler_flags };
  
  print "$Config{cpprun} @cpp_flags $file_c\n";
  my $text = join '', grep !/^#/, `$Config{cpprun} @cpp_flags $file_c`;
  if($?)
  {
    print "C pre-processor failed...\n";
    print "only default will be available.\n";
    return;
  }
  
  my %abi;

  if($text =~ m/typedef\s+enum\s+ffi_abi\s+{(.*?)}/s)
  {
    my $enum = $1;
    
    #print "[enum]\n";
    #print "$enum\n";
    
    while($enum =~ s/FFI_([A-Z_0-9]+)//)
    {
      my $abi = $1;
      next if $abi =~ /^(FIRST|LAST)_ABI$/;
      $abi{lc $abi} = -1;
    }
  }
  
  my $template_c = File::Spec->catfile(qw( inc template abi.c ));
  
  my $b = $mb->cbuilder;
  
  foreach my $abi (sort keys %abi)
  {
    my $file_c = File::Spec->catfile($dir, "$abi.c");
    
    do {
      my $in;
      my $out;
      open $in, '<', $template_c;
      open $out, '>', $file_c;

      my $line;    
      while(1)
      {
        $line = <$in>;
        last unless defined $line;
        $line =~ s/##ARG##/"FFI_".uc($abi)/eg;
        print $out $line;
      }
      
      close $out;
      close $in;
    };
    
    my $obj = eval { $b->compile(
      source               => $file_c,
      include_dirs         => [ 'include' ],
      extra_compiler_flags => [ @{ $mb->extra_compiler_flags }, '-DTRY_FFI_ABI=FFI_'.uc $abi ],
    ) };
    next if $@;
    
    my $exe = eval { $b->link_executable(
      objects            => $obj,
      extra_linker_flags => $mb->extra_linker_flags,
    ) };
    next if $@;
    
    local $Win32::ErrorMode::ErrorMode = 0x3;

    if($^O eq 'MSWin32' && $file_c =~ /\s/)
    {
      $exe = Win32::GetShortPathName($exe);
    }

    my $out = `$exe`;
    if($? == -1)
    {
      die "unable to execute: $exe";
    }
    elsif($? == 0 && $out =~ /\|value=([0-9]+)\|/)
    {
      $abi{$abi} = $1;
    }
  }
  
  foreach my $abi (sort keys %abi)
  {
    if($abi{$abi} == -1)
    {
      delete $abi{$abi};
      next;
    }
    print "  found abi: $abi = $abi{$abi}\n";
  }

  $mb->config_data( abi => \%abi );

  rmtree('.abi-probe-test', { verbose => 0 });
  return;
}

1;
