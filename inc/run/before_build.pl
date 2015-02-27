use strict;
use warnings;
use inc::My::Dev;
use File::Spec;

if(@ARGV > 0)
{
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

  My::Dev->clean;
}

foreach my $bits (qw( 16 32 64 ))
{
  foreach my $orig (qw( libtest/uint8.c libtest/sint8.c t/type_uint8.t t/type_sint8.t ))
  {
    my $new = $orig;
    $new =~ s/8/$bits/;
    
    open my $in, '<', $orig;
    open my $out, '>', $new;

    if($orig =~ /\.c$/)
    {
      print $out join "\n", "/*",
                            " * DO NOT MODIFY THIS FILE.",
                            " * Thisfile generated from similar file $orig",
                            " * all instances of \"int8\" have been changed to \"int$bits\"",
                            " */",
                            "";
    }
    else
    {
      print $out join "\n", "#",
                            "# DO NOT MODIFY THIS FILE.",
                            "# Thisfile generated from similar file $orig",
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
  foreach my $orig (qw( libtest/float.c t/type_float.t ))
  {
    my $new = $orig;
    $new =~ s/float/$type/;
    
    open my $in, '<', $orig;
    open my $out, '>', $new;

    if($orig =~ /\.c$/)
    {
      print $out join "\n", "/*",
                            " * DO NOT MODIFY THIS FILE.",
                            " * Thisfile generated from similar file $orig",
                            " * all instances of \"float\" have been changed to \"$type\"",
                            " */",
                            "";
    }
    else
    {
      print $out join "\n", "#",
                            "# DO NOT MODIFY THIS FILE.",
                            "# Thisfile generated from similar file $orig",
                            "# all instances of \"float\" have been changed to \"$type\"",
                            "#",
                            "";
    }
    
    while(<$in>)
    {
      s/float/$type/eg;
      print $out $_;
    }
    
    close $out;
    close $in;
  }
}
