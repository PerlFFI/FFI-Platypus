package My::LibTest;

use strict;
use warnings;
use File::Spec;
use ExtUtils::CBuilder;
use FindBin ();

my $root = $FindBin::Bin;

sub build_libtest
{
  my $mb = shift;
  
  my $b = ExtUtils::CBuilder->new;
  
  my @obj = map {
    $b->compile(
      source => $_,
      include_dirs => [
        File::Spec->catdir($root, 'libtest'),
        File::Spec->catdir($root, 'xs'),
      ],
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
    $b->link(
      lib_file => $b->lib_file(File::Spec->catfile($root, 'libtest', 'libtest.o')),
      objects  => \@obj,
    );
  }
  else
  {
    die 'TODO';
  }
}

1;
