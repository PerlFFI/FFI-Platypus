use strict;
use warnings;
use Config;
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
    if(open($fh, '<', File::Spec->catfile($FindBin::Bin, '00_diag.pre.txt')))
    {
      @modules = <$fh>;
      close $fh;
      chomp @modules;
    }
  };
  eval qq{ require $_ } for @modules;
};

sub spacer ()
{
  diag '';
  diag '';
  diag '';
}

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

spacer;

my @keys = sort grep /(MOJO|PERL|\A(LC|HARNESS)_|\A(SHELL|LANG)\Z)/i, keys %ENV;

if(@keys > 0)
{
  diag "$_=$ENV{$_}" for @keys;
  
  if($ENV{PERL5LIB})
  {
    spacer;
    diag "PERL5LIB path";
    diag $_ for split $Config{path_sep}, $ENV{PERL5LIB};
    
  }
  elsif($ENV{PERLLIB})
  {
    spacer;
    diag "PERLLIB path";
    diag $_ for split $Config{path_sep}, $ENV{PERLLIB};
  }
  
  spacer;
}

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

spacer;

