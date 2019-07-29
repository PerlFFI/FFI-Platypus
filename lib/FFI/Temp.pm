package FFI::Temp;

use strict;
use warnings;
use Carp qw( croak );
use File::Spec;
use File::Temp qw( tempdir );

# ABSTRACT: Temp Dir support for FFI::Platypus
# VERSION

=head1 DESCRIPTION

This class is private to L<FFI::Platypus>.

=cut

# problem with vanilla File::Temp is that is often uses
# as /tmp that has noexec turned on.  Workaround is to
# create a temp directory in the build directory, but
# we have to be careful about cleanup.  This puts all that
# (attempted) carefulness in one place so that when we
# later discover it isn't so careful we can fix it in
# one place rather thabn alllll the places that we need
# temp directories.

my %root;

sub _root
{
  my $root = File::Spec->rel2abs(File::Spec->catdir(".tmp"));
  unless(-d $root)
  {
    mkdir $root or die "unable to create temp root $!";
  }

  # TODO: doesn't account for fork...
  my $lock = File::Spec->catfile($root, "l$$");
  unless(-f $lock)
  {
    open my $fh, '>', $lock;
    close $fh;
  }
  $root{$root} = 1;
  $root;
}

END {
  foreach my $root (keys %root)
  {
    my $lock = File::Spec->catfile($root, "l$$");
    unlink $lock;
    # try to delete if possible.
    # if not possible then punt
    rmdir $root if -d $root;
  }
}

sub newdir
{
  my $class = shift;
  croak "uneven" if @_ % 2;
  File::Temp->newdir(DIR => _root, @_);
}

sub new
{
  my $class = shift;
  croak "uneven" if @_ % 2;
  File::Temp->new(DIR => _root, @_);
}

1;
