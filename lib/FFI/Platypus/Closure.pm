package FFI::Platypus::Closure;

use strict;
use warnings;
use FFI::Platypus;
use Scalar::Util qw( refaddr);
use Carp qw( croak );
use overload '&{}' => sub {
  my $self = shift;
  sub { $self->{code}->(@_) };
}, bool => sub { 1 }, fallback => 1;

# ABSTRACT: Platypus closure object
# VERSION

=head1 SYNOPSIS

create closure with OO interface

 use FFI::Platypus::Closure;
 my $closure = FFI::Platypus::Closure->new(sub { print "hello world\n" });

create closure from Platypus object

 use FFI::Platypus;
 my $ffi = FFI::Platypus->new( api => 1 );
 my $closure = $ffi->closure(sub { print "hello world\n" });

use closure

 $ffi->function(foo => ['()->void'] => 'void')->call($closure);

=head1 DESCRIPTION

This class represents a Perl code reference that can be called from compiled code.
When you create a closure object, you can pass it into any function that expects
a function pointer.  Care needs to be taken with closures because compiled languages
typically have a different way of handling lifetimes of objects.  You have to make
sure that if the compiled code is going to call a closure that the closure object
is still in scope somewhere, or has been made sticky, otherwise you may get a
segment violation or other mysterious crash.

=head1 CONSTRUCTOR

=head2 new

 my $closure = FFI::Platypus::Closure->new($coderef);

Create a new closure object; C<$coderef> must be a subroutine code reference.

=cut

sub new
{
  my($class, $coderef) = @_;
  croak "not a coderef" unless ref($coderef) eq 'CODE';
  my $self = bless { code => $coderef, cbdata => {}, sticky => 0 }, $class;
  $self;
}

sub add_data
{
  my($self, $payload, $type) = @_;
  $self->{cbdata}{$type} = bless \$payload, 'FFI::Platypus::ClosureData';
}

sub get_data
{
  my($self, $type) = @_;

  if (exists $self->{cbdata}->{$type}) {
      return ${$self->{cbdata}->{$type}};
  }

  return 0;
}

=head1 METHODS

=head2 call

 $closure->call(@arguments);
 $closure->(@arguments);

Call the closure from Perl space.  May also be invoked by treating
the closure object as a code reference.

=cut

sub call
{
  my $self = shift;
  $self->{code}->(@_)
}

=head2 sticky

 $closure->sticky;

Mark the closure sticky, meaning that it won't be free'd even if
all the reference of the object fall out of scope.

=cut

sub sticky
{
  my($self) = @_;
  return if $self->{sticky};
  $self->{sticky} = 1;
  $self->_sticky;
}

=head2 unstick

 $closure->unstick;

Unmark the closure as sticky.

=cut

sub unstick
{
  my($self) = @_;
  return unless $self->{sticky};
  $self->{sticky} = 0;
  $self->_unstick;
}

package FFI::Platypus::ClosureData;

# VERSION

1;
