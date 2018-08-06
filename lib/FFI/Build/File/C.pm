package FFI::Build::File::C;

use strict;
use warnings;
use 5.008001;
use base qw( FFI::Build::File::Base );
use constant default_suffix => '.c';
use constant default_encoding => ':utf8';
use Capture::Tiny ();
use File::Path ();
use FFI::Build::File::Object;

# ABSTRACT: Class to track C source file in FFI::Build
# VERSION

sub accept_suffix
{
  (qr/\.c$/)
}

sub build
{
  my($self) = @_;

  my $oname = $self->basename;
  $oname =~ s/\.c$//;
  $oname .= $self->platform->object_suffix;

  my $buildname = '_build';
  $buildname = $self->library->buildname if $self->library;

  my $object = FFI::Build::File::Object->new(
    [ $self->dirname, $buildname, $oname ],
    platform => $self->platform,
    library  => $self->library,
  );
  
  File::Path::mkpath($object->dirname, { verbose => 0, mode => 0700 });

  my @cmd = (
    $self->platform->cc,
    $self->platform->cflags,
    $self->platform->extra_system_inc,
    -c => $self->path,
    -o => $object->path,
  );
  
  my($out, $exit) = Capture::Tiny::capture_merged(sub {
    print "+ @cmd\n";
    system @cmd;
  });

  if($exit || !-f $object->path)
  {
    print $out;
    die "error building $object from $self";
  }
  elsif($self->library && $self->library->verbose)
  {
    print $out;
  }
  
  $object;
}

1;
