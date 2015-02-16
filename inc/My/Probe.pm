package My::Probe;

use strict;
use warnings;
use File::Glob qw( bsd_glob );
use ExtUtils::CBuilder;
use File::Spec;
use Config;
use Alien::FFI;
use File::Copy qw( copy );

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
  
  my $b = ExtUtils::CBuilder->new;

  my %probe;
  
  foreach my $cfile (bsd_glob 'inc/probe/*.c')
  {
    my $name = (File::Spec->splitpath($cfile))[2];
    $name =~ s{\.c$}{};
    
    my $obj = eval { $b->compile(
      source               => $cfile,
      include_dirs         => [ 'include' ],
      extra_compiler_flags => Alien::FFI->cflags,
    ) };
    next if $@;
    $mb->add_to_cleanup($obj) if $mb;
    
    my($exe,@rest) = eval { $b->link_executable(
      objects            => $obj,
      extra_linker_flags => Alien::FFI->libs,
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
  
  $mb->config_data( probe => \%probe ) if $mb;
  
  return;
}

sub run
{
  my @cmd = @_;
  
  if($^O eq 'MSWin32')
  {
    if($Config{myuname} =~ /strawberry-perl/ && $] >= 5.020)
    {
    
      # 1. annoyance the first:
      # Strawberry Perl 5.20.0 and better comes with libffi
      # unfortunately it is distributed as a .dll and to make
      # things a little worse the .exe files generated for some
      # reason link to a .dll with a different name.
    
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
      
      # 2. annoyance the second
      # If there is a missing symbol in the .dll (which happens
      # with the complex float probe), then we get an annoying dialog
      # that the users has to click on.  Strawberry of at least 5.20.1
      # seems to come with Win32::Process so we are okay with using it.
      # see 
      # http://www.activestate.com/blog/2007/11/supressing-windows-error-report-messagebox-subprocess-and-ctypes
      
      require Win32;
      require Win32::Process;
      require Win32API::File;
      
      print "$cmd[0] $cmd[1]\n";
      
      # SEM_NOGPFAULTERRORBOX
      my $oldmode = Win32API::File::SetErrorMode(0x0002 | 0x8000 | 0x0004 | 0x0001);
      
      my $proc;
      Win32::Process::Create($proc,
        $cmd[0],
        $cmd[1],
        0,
        Win32::Process::CREATE_NO_WINDOW(),
        ".") || do { 
          print "FAILED TO EXECUTE\n"; 
          return 2 << 8;
        };
      
      # 2.a. subannoyance the third
      # Who writes interfaces like this anyway?
      
      $proc->Wait(Win32::Process::INFINITE());
      my $code;
      $proc->GetExitCode($code);
      print "exit = $code\n";
      
      Win32API::File::SetErrorMode($oldmode);
      
      unlink $_ for @cleanup;
      
      return $code;
    }
  }
  
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

1;
