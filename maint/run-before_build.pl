use strict;
use warnings;
use lib 'inc';
use My::Config;
use File::Spec;
use File::Spec ();
use File::Find ();

if(@ARGV > 0)
{
  if(-e 'Makefile')
  {
    if($^O eq 'MSWin32')
    {
      print "> gmake realclean\n";
      system 'gmake', 'realclean';
    }
    else
    {
      print "% make realclean\n";
      system 'make', 'realclean';
    }
  }

  My::Config->new->clean;
}

foreach my $bits (qw( 16 32 64 ))
{
  foreach my $orig (qw( t/ffi/uint8.c t/ffi/sint8.c t/type_uint8.t t/type_sint8.t ))
  {
    my $new = $orig;
    $new =~ s/8/$bits/;

    open my $in, '<', $orig or die "unable to read $orig";
    open my $out, '>', $new or die "unable to write $new";

    if($orig =~ /\.c$/)
    {
      print $out join "\n", "/*",
                            " * DO NOT MODIFY THIS FILE.",
                            " * This file generated from similar file $orig",
                            " * all instances of \"int8\" have been changed to \"int$bits\"",
                            " */",
                            "";
    }
    else
    {
      print $out join "\n", "#",
                            "# DO NOT MODIFY THIS FILE.",
                            "# This file generated from similar file $orig",
                            "# all instances of \"int8\" have been changed to \"int$bits\"",
                            "#",
                            "";
    }

    while(<$in>)
    {
      s/int8/"int$bits"/eg;
      print $out $_;
    }

    close $out;
    close $in;
  }
}

foreach my $type (qw( double ))
{
  foreach my $orig (qw( t/ffi/float.c t/type_float.t t/type_complex_float.t t/ffi/complex_float.c ))
  {
    my $new = $orig;
    $new =~ s/float/$type/;

    open my $in, '<', $orig or die "unable to read $orig $!";
    open my $out, '>', $new or die "unable to write $new $!";

    if($orig =~ /\.c$/)
    {
      print $out join "\n", "/*",
                            " * DO NOT MODIFY THIS FILE.",
                            " * This file generated from similar file $orig",
                            " * all instances of \"float\" have been changed to \"$type\"",
                            " */",
                            "";
    }
    else
    {
      print $out join "\n", "#",
                            "# DO NOT MODIFY THIS FILE.",
                            "# This file generated from similar file $orig",
                            "# all instances of \"float\" have been changed to \"$type\"",
                            "#",
                            "";
    }

    while(<$in>)
    {
      s/float/$type/eg;
      s/SIZEOF_FLOAT_COMPLEX/"SIZEOF_@{[ uc $type ]}_COMPLEX"/eg;
      if($type eq 'double')
      {
        s/crealf/creal/g;
        s/cimagf/cimag/g;
      }
      else
      {
        die 'todo';
      }
      print $out $_;
    }

    close $out;
    close $in;
  }
}
