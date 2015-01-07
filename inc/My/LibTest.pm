package My::LibTest;

use strict;
use warnings;
use File::Spec;
use ExtUtils::CBuilder;
use FindBin ();
use Alien::FFI;
use File::Copy qw( move );
use Config;
use Text::ParseWords qw( shellwords );

my $root = $FindBin::Bin;

sub build_libtest
{
  my $mb = shift;
  
  my $b = ExtUtils::CBuilder->new;
  
  my @obj = map {
    $b->compile(
      source => $_,
      include_dirs => [
        File::Spec->catdir($root, 'include'),
      ],
      extra_compiler_flags => Alien::FFI->cflags,
    );
  } do {
    my $dh;
    opendir $dh, 'libtest';
    my @list = map { File::Spec->catfile($root, 'libtest', $_) } grep /\.c$/, readdir $dh;
    closedir $dh;
    @list;
  };
  
  if($^O ne 'MSWin32')
  {
    my $dll = $b->link(
      lib_file => $b->lib_file(File::Spec->catfile($root, 'libtest', 'libtest.o')),
      objects  => \@obj,
      extra_linker_flags => Alien::FFI->libs,
    );
    
    if($^O eq 'cygwin')
    {
      my $old = $dll;
      my $new = $dll;
      $new =~ s{libtest.dll$}{cygtest-1.dll};
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
    print "@cmd";
    system @cmd;
    exit 2 if $?;
  }
}

1;
