use strict;
use warnings;

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
