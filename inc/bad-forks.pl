use strict;
use warnings;
use File::Spec;

my $path;
foreach my $inc (@INC)
{
  $path = File::Spec->catfile($inc, 'forks.pm');
  last if -f $path;
}

if(-f $path)
{
  eval q{ use forks };
  if(my $error = $@)
  {
    print "There seems to be something wrong with your forks.pm module.\n";
    print "This exception was raised when trying to use forks:\n\n";

    print "  $error\n\n";

    print "Although forks.pm is not required by FFI-Platypus, it does test\n";
    print "against forks.pm if it is installed, so please fix your forks.pm\n";
    print "before trying to install FFI-Platypus.\n\n";

    print "If you believe this to be an error in FFI-Platypus, please feel\n";
    print "free to open a ticket here:\n\n";

    print "https://github.com/PerlFFI/FFI-Platypus/issues\n\n";
    exit 2;
  }
}
