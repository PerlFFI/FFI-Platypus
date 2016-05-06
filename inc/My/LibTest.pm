package My::LibTest;

use strict;
use warnings;
use File::Spec;
use ExtUtils::CBuilder;
use FindBin ();
use File::Copy qw( move );
use File::Glob qw( bsd_glob );
use Config;
use Text::ParseWords qw( shellwords );

my $root = $FindBin::Bin;

sub build
{
  my($class, $mb) = @_;

  my($header_time) = reverse sort map { (stat $_)[9] } bsd_glob "include/*.h";
  my $compile_count = 0;
  
  my $b = $mb->cbuilder;
  
  my @obj = map {
    my $filename = $_;
    my($source_time) = reverse sort ((stat $filename)[9], $header_time);
    my $obj_name = $b->object_file($filename);
    my $obj_time = -e $obj_name ? ((stat $obj_name)[9]) : 0;
    if($obj_time < $source_time)
    {
      $b->compile(
        source => $filename,
        include_dirs => [
          File::Spec->catdir($root, 'include'),
        ],
        extra_compiler_flags => $mb->extra_compiler_flags,
      );
      $compile_count++;
    }
    $obj_name;
  } bsd_glob("libtest/*.c");
  
  return unless $compile_count > 0;
  
  if($^O ne 'MSWin32')
  {
    my $dll = $b->link(
      lib_file           => $b->lib_file(File::Spec->catfile($root, 'libtest', $b->object_file('libtest.c'))),
      objects            => \@obj,
      extra_linker_flags => $mb->extra_linker_flags,
    );
    
    if($^O =~ /^(cygwin|msys)$/)
    {
      my $old = $dll;
      my $new = $dll;
      if($^O eq 'cygwin')
      {
        $new =~ s{libtest.dll$}{cygtest-1.dll};
      }
      elsif($^O eq 'msys')
      {
        $new =~ s{libtest.dll$}{msys-test-1.dll};
      }
      else
      {
        die "how?";
      }
      move($old => $new) || die "unable to copy $old => $new $!";
    }
  }
  else
  {
    # On windows we can't depend on MM::CBuilder to make the .dll file because it creates dlls
    # that export only one symbol (which is used for bootstrapping XS modules).
    my $dll = File::Spec->catfile($FindBin::Bin, 'libtest', 'libtest.dll');
    $dll =~ s{\\}{/}g;
    my @cmd;
    my $cc = $Config{cc};
    if($cc !~ /cl(\.exe)?$/)
    {
      my $lddlflags = $Config{lddlflags};
      $lddlflags =~ s{\\}{/}g;
      @cmd = ($cc, shellwords($lddlflags), -o => $dll, "-Wl,--export-all-symbols", @obj);
    }
    else
    {
      @cmd = ($cc, @obj, '/link', '/dll', '/out:' . $dll);
    }
    print "@cmd\n";
    system @cmd;
    exit 2 if $?;
  }
}

1;
