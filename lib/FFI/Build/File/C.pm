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

=head1 SYNOPSIS

 use FFI::Build::File::C;
 
 my $c = FFI::Build::File::C->new('src/foo.c');

=head1 DESCRIPTION

File class for C source files.

=cut

sub accept_suffix
{
  (qr/\.(c|i)$/)
}

sub build_item
{
  my($self) = @_;

  my $oname = $self->basename;
  $oname =~ s/\.(c(xx|pp)|i)?$//;
  $oname .= $self->platform->object_suffix;

  my $buildname = '_build';
  $buildname = $self->build->buildname if $self->build;

  my $object = FFI::Build::File::Object->new(
    [ $self->dirname, $buildname, $oname ],
    platform => $self->platform,
    build    => $self->build,
  );
  
  return $object if -f $object->path && !$object->needs_rebuild($self->_deps);
  
  File::Path::mkpath($object->dirname, { verbose => 0, mode => 0700 });

  my @cmd = (
    $self->_base_args,
    -c => $self->path,
    $self->platform->flag_object_output($object->path),
  );

  my($out, $exit) = Capture::Tiny::capture_merged(sub {
    $self->platform->run(@cmd);
  });

  if($exit || !-f $object->path)
  {
    print $out;
    die "error building $object from $self";
  }
  elsif($self->build && $self->build->verbose >= 2)
  {
    print $out;
  }
  elsif($self->build && $self->build->verbose >= 1)
  {
    print "CC @{[ $self->path ]}\n";
  }
  
  $object;
}

sub cc
{
  my($self) = @_;
  $self->platform->cc;
}

sub _base_args
{
  my($self) = @_;
  my @cmd = ($self->cc);
  push @cmd, $self->build->cflags_I if $self->build;
  push @cmd, $self->platform->ccflags;
  push @cmd, @{ $self->build->cflags } if $self->build;
  @cmd;
}

sub _base_args_cpp
{
  my($self) = @_;
  my @cmd = ($self->platform->cpp);
  push @cmd, $self->build->cflags_I if $self->build;
  push @cmd, grep /^-[DI]/, $self->platform->ccflags;
  push @cmd, grep /^-D/, @{ $self->build->cflags } if $self->build;
  @cmd;
}

sub build_item_cpp
{
  my($self) = @_;

  my $oname = $self->basename;
  $oname =~ s/\.(c(xx|pp)|i)$?$//;
  $oname .= '.i';

  my $buildname = '_build';
  $buildname = $self->build->buildname if $self->build;

  my $ifile = FFI::Build::File::C->new(
    [ $self->dirname, $buildname, $oname ],
    platform => $self->platform,
    build    => $self->build,
  );

  File::Path::mkpath($ifile->dirname, { verbose => 0, mode => 0700 });

  my @cmd = (
    $self->_base_args_cpp,
    $self->path,
  );

  my($out, $err, $exit) = Capture::Tiny::capture(sub {
    $self->platform->run(@cmd);
  });

  if($exit)
  {
    print "[out]\n$out\n" if defined $out && $out ne '';
    print "[err]\n$err\n" if defined $err && $err ne '';
    die "error building $ifile from $self";
  }
  else
  {
    my $fh;
    open($fh, '>', $ifile->path);
    print $fh $out;
    close $fh;
  }

  $ifile;
}

sub _deps
{
  my($self) = @_;
  
  return $self->path unless $self->platform->cc_mm_works;

  my @cmd = (
    $self->_base_args,
    '-MM',
    $self->path,
  );
  
  my($out,$err,$exit) = Capture::Tiny::capture(sub {
    $self->platform->run(@cmd);
  });
  
  if($exit)
  {
    print $out;
    print $err;
    warn "error computing dependencies for $self";
    return ($self->path);
  }
  else
  {
    my(undef, $deps) = split /:/, $out, 2;
    $deps =~ s/^\s+//;
    $deps =~ s/\s+$//;
    return grep !/^\\$/, split /\s+/, $deps;
  }
}

1;
