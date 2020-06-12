use strict;
use warnings;
use Config;

if($] == 5.010 && $Config{useithreads})
{
  print "\n\n\n";
  print " !! WARNING WARNING WARNINGS WARNING !!\n";
  print "\n";
  print "The version of Perl you are using (5.10.0) when compiled\n";
  print "with threads is buggy and not supported by the Platypus team.\n";
  print "Please take the time to upgraded to a supported version of\n";
  print "Perl.  Easiest upgrade is probably to 5.10.0 unthreaded, or\n";
  print "5.10.1.  Better would be to upgrade to 5.32.\n";
  print "\n";
  print "https://github.com/Perl5-FFI/FFI-Platypus/issues/271\n";
  print "\n";
  print " !! WARNING WARNING WARNINGS WARNING !!\n";
  print "\n\n\n";
  print "sleep 45\n";
}
