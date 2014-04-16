use strict;
use warnings;
use Test::More tests => 1;
BEGIN {
  my @modules;
  eval q{
    require FindBin;
    require File::Spec;
    1;
  } || die $@;
  do {
    my $fh;
    open($fh, '<', File::Spec->catfile($FindBin::Bin, '00_diag.pre.txt'));
    @modules = <$fh>;
    close $fh;
    chomp @modules;
  };
  eval qq{ require $_ } for @modules;
};

pass 'okay';

my @modules;
do {
  my $fh;
  open($fh, '<', File::Spec->catfile($FindBin::Bin, '00_diag.txt'));
  @modules = <$fh>;
  close $fh;
  chomp @modules;
};

my $max = 1;
$max = $_ > $max ? $_ : $max for map { length $_ } @modules;
our $format = "%-${max}s %s"; 

diag '';
diag '';
diag '';

diag sprintf $format, 'perl ', $^V;

require(File::Spec->catfile($FindBin::Bin, '00_diag.pl'))
  if -e File::Spec->catfile($FindBin::Bin, '00_diag.pl');

foreach my $module (@modules)
{
  if(eval qq{ require $module; 1 })
  {
    my $ver = eval qq{ \$$module\::VERSION };
    $ver = 'undef' unless defined $ver;
    diag sprintf $format, $module, $ver;
  }
  else
  {
    diag sprintf $format, $module, '-';
  }
}

diag '';
diag '';
diag '';
