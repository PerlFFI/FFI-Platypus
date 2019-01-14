package FFI::Probe::Runner::Result;

use strict;
use warnings;

# ABSTRACT: The results from a probe run.
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new

 my $result = FFI::Probe::Runner::Result->new(%args);

Creates a new instance of the class.

=cut

sub new
{
  my($class, %args) = @_;
  my $self = bless \%args, $class;
  $self;
}

=head1 METHODS

=head2 stdout

 my $stdout = $result->stdout;

=head2 stderr

 my $stderr = $result->stderr;

=head2 rv

 my $rv = $result->rv;

=head2 signal

 my $signal = $result->signal;

=cut

sub stdout { shift->{stdout} }
sub stderr { shift->{stderr} }
sub rv     { shift->{rv}     }
sub signal { shift->{signal} }

=head2 pass

 my $pass = $result->pass;

=cut

sub pass
{
  my($self) = @_;
  $self->rv == 0 && $self->signal == 0;
}

1;
