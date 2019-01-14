package FFI::Probe::Runner;

use strict;
use warnings;
use Capture::Tiny qw( capture );
use FFI::Probe::Runner::Result;

# ABSTRACT: Probe runner for FFI
# VERSION

=head1 SYNOPSIS

 use FFI::Probe::Runner;

 my $runner = FFI::Probe::Runner->new;
 $runner->run('foo.so');

=head1 DESCRIPTION

This class executes code in a dynamic library for probing and detecting platform
properties.

=head1 CONSTRUCTOR

=head2 new

 my $runner = FFI::Probe::Runner->new(%args);

Creates a new instance.

=over 4

=item exe

The path to the dlrun wrapper.  The default is usually correct.

=item flags

The flags to pass into C<dlopen>.  The default is C<RTLD_LAZY> on Unix
and C<0> on windows..

=back

=cut

sub new
{
  my($class, %args) = @_;

  $args{exe} ||= do {
    require FFI::Platypus::ShareConfig;
    require File::Spec;
    require Config;
    File::Spec->catfile(FFI::Platypus::ShareConfig::dist_dir('FFI::Platypus'), 'probe', 'bin', "dlrun$Config::Config{exe_ext}");
  };

  defined $args{flags} or $args{flags} = '-';

  die "probe runner executable not found at: $args{exe}" unless -f $args{exe};

  my $self = bless {
    exe   => $args{exe},
    flags => $args{flags},
  }, $class;
  $self;
}

=head1 METHODS

=head2 exe

 my $exe = $runner->exe;

The path to the dlrun wrapper.

=head2 flags

 my $flags = $runner->flags;

The flags to pass into C<dlopen>.

=cut

sub exe   { shift->{exe}   }
sub flags { shift->{flags} }

=head2 verify

 $runner->verify;

Verifies the dlrun wrapper is working.  Throws an exception in the event of failure.

=cut

sub verify
{
  my($self) = @_;
  my $exe = $self->exe;
  my($out, $err, $ret) = capture {
    system $exe, 'verify', 'self';
  };
  return 1 if $ret == 0 && $out =~ /dlrun verify self ok/;
  print $out;
  print STDERR $err;
  die "verify failed";
}

=head2 run

 $runner->run($dll, @args);

Runs the C<dlmain> function in the given dynamic library, passing in the
given arguments.  Returns a L<FFI::Probe::Runner::Result> object which
contains the results.

=cut

sub run
{
  my($self, $dll, @args) = @_;
  my $exe   = $self->exe;
  my $flags = $self->flags;
  my($out, $err, $ret) = capture {
    my @cmd = ($exe, $dll, $flags, @args);
    system @cmd;
    $?;
  };
  FFI::Probe::Runner::Result->new(
    stdout => $out,
    stderr => $err,
    rv     => $ret >> 8,
    signal => $ret & 127,
  );
}

1;
