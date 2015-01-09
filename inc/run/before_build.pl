use strict;
use warnings;
use inc::My::CopyList;
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

  foreach my $file (map { File::Spec->catfile(@$_) } @inc::My::CopyList::list)
  {
    if(-e $file)
    {
      unlink $file;
    }
  }
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
