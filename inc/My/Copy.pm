package inc::My::Copy;

use strict;
use warnings;
use Moose;
use File::Copy qw( copy );
use inc::My::CopyList;

with 'Dist::Zilla::Role::AfterBuild';

sub after_build
{
  my($self, $data) = @_;
  
  my $build_root = $data->{build_root};
  
  foreach my $name (@inc::My::CopyList::list)
  {
    my $src = $build_root->file(@$name);
    my $dst = $self->zilla->root->file(@$name);
    if(-e $src)
    {
      $self->log("copy $src => $dst");
      copy("$src", "$dst") 
        || $self->log_fatal("unable to copy $!");
    }
    else
    {
      $self->log_fatal("no such file: $src");
    }
  }
}

1;
