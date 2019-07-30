package FFI::Platypus::Legacy;

use strict;
use warnings;

# ABSTRACT: Legacy Platypus interfaces
# VERSION

=head1 DESCRIPTION

This class is private to L<FFI::Platypus>.

=cut

package FFI::Platypus;

sub _package
{
  my($self, $module, $modlibname) = @_;

  ($module, $modlibname) = caller unless defined $modlibname;
  my @modparts = split /::/, $module;
  my $modfname = $modparts[-1];
  my $modpname = join('/',@modparts);
  my $c = @modparts;
  $modlibname =~ s,[\\/][^\\/]+$,, while $c--;    # Q&D basename

  {
    my @maybe = (
      "$modlibname/auto/$modpname/$modfname.txt",
      "$modlibname/../arch/auto/$modpname/$modfname.txt",
    );
    foreach my $file (@maybe)
    {
      if(-f $file)
      {
        open my $fh, '<', $file;
        my $line = <$fh>;
        close $fh;
        if($line =~ /^FFI::Build\@(.*)$/)
        {
          $self->lib("$modlibname/$1");
          return $self;
        }
      }
    }
  }

  require FFI::Platypus::ShareConfig;
  my @dlext = @{ FFI::Platypus::ShareConfig->get("config_dlext") };

  foreach my $dlext (@dlext)
  {
    my $file = "$modlibname/auto/$modpname/$modfname.$dlext";
    unless(-e $file)
    {
      $modlibname =~ s,[\\/][^\\/]+$,,;
      $file = "$modlibname/arch/auto/$modpname/$modfname.$dlext";
    }

    if(-e $file)
    {
      $self->lib($file);
      return $self;
    }
  }

  $self;
}

1;
