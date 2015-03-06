package My::Dev;

use strict;
use warnings;
use File::Spec;

my $ppport_version = 3.28;
my $ppport_h = File::Spec->catfile(qw( include ppport.h ));

sub generate
{
  if(!-r $ppport_h || -d '.git')
  {
    require Devel::PPPort;
    die "Devel::PPPort $ppport_version or better required for development"
      unless $Devel::PPPort::VERSION >= $ppport_version;
    
    my $old = '';
    if(-e $ppport_h)
    {
      open my $fh, '<', $ppport_h;
      $old = do { local $/; <$fh> };
      close $fh;
    }
  
    my $content = Devel::PPPort::GetFileContents('include/ppport.h');

    if($content ne $old)
    {
      print "generating new $ppport_h\n";
      open my $fh, '>', $ppport_h;
      print $fh $content;
      close $fh;
    }
  }
}

sub clean
{
  unlink $ppport_h;
}

1;
