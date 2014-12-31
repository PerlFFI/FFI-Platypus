use strict;
use warnings;
use inc::My::CopyList;
use File::Spec;

if(-e 'Build')
{
  if($^O eq 'MSWin32')
  {
    print "> Build distclean\n";
    system 'Build', 'distclean';
  }
  else
  {
    print "% ./Build distclean\n";
    system './Build', 'distclean';
  }
}

foreach my $file (map { File::Spec->catfile(@$_) } @inc::My::CopyList::list)
{
  if(-e $file)
  {
    unlink $file;
  }
}
