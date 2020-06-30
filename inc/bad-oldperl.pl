if($] < 5.008004)
{
  print "\n\n\n";
  print " !! ERROR ERROR ERRORS ERROR !!\n";
  print "\n";
  print "The version of Perl you are using is very old (at least 15 years)\n";
  print "as of this writing.  The FFI-Platypus team plans on dropping support\n";
  print "for Perls older than 5.8.4 on or after July 1st 2020.  At that time\n";
  print "FFI-Platypus will refuse to install on these old Perls.  Please take\n";
  print "the time to migrate to a supported version of Perl ASAP.\n";
  print "\n";
  print "https://github.com/PerlFFI/FFI-Platypus/issues/271\n";
  print "\n";
  print " !! ERROR ERROR ERRORS ERROR !!\n";
  print "\n\n\n";
  exit;
}

