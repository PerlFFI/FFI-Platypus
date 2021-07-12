package FFI::Temp;

use strict;
use warnings;
use 5.008004;
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
  my $lock = File::Spec->catfile($root, "l$$");

  foreach my $try (0..9)
  {
    sleep $try if $try != 0;
    mkdir $root or die "unable to create temp root $!" unless -d $root;

    # There is a race condition here if the FFI::Temp is
    # used in parallel.  To work around we run this 10
    # times until it works.  There is still a race condition
    # if it fails 10 times, but hopefully that is unlikely.

    # ??: doesn't account for fork, but probably doesn't need to.
    open my $fh, '>', $lock or next;
    close $fh or next;

    $root{$root} = 1;
    return $root;
  }
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
