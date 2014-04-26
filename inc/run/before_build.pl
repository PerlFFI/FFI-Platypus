use strict;
use warnings;
use File::Spec;

unless(-r File::Spec->catfile(qw( inc PkgConfig Makefile.PL ))
&&     -r File::Spec->catfile(qw( inc libffi autogen.sh )))
{
  system qw( git submodule init );
  die if $?;
}

system qw( git submodule update );
die if $?;

chdir(File::Spec->catdir(qw( inc libffi ))) || die "unable to chdir";

unless(-x 'configure')
{
  system qw( sh autogen.sh );
  die if $?;
  system qw( git checkout texinfo.tex );
  die if $?;
}
