package FFI::Platypus::Function;

use strict;
use warnings;
use FFI::Platypus;

# ABSTRACT: An FFI function object
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus;
 
 # call directly
 my $ffi = FFI::Platypus->new( api => 1 );
 my $f = $ffi->function(puts => ['string'] => 'int');
 $f->call("hello there");
 
 # attach as xsub and call (faster for repeated calls)
 $f->attach('puts');
 puts('hello there');

=head1 DESCRIPTION

This class represents an unattached platypus function.  For more
context and better examples see L<FFI::Platypus>.

=head1 METHODS

=head2 attach

 $f->attach($name);
 $f->attach($name, $prototype);

Attaches the function as an xsub (similar to calling attach directly
from an L<FFI::Platypus> instance).  You may optionally include a
prototype.

=head2 call

 my $ret = $f->call(@arguments);
 my $ret = $f->(@arguments);

Calls the function and returns the result. You can also use the
function object B<like> a code reference.

=head2 sub_ref

 my $code = $f->sub_ref;

Returns an anonymous code reference.  This will usually be faster
than using the C<call> method above.

=cut

use overload '&{}' => sub {
  my $ffi = shift;
  sub { $ffi->call(@_) };
}, 'bool' => sub {
  my $ffi = shift;
  return $ffi;
}, fallback => 1;

package FFI::Platypus::Function::Function;

use base qw( FFI::Platypus::Function );

sub attach
{
  my($self, $perl_name, $proto) = @_;

  my $frame = -1;
  my($caller, $filename, $line);

  do {
    ($caller, $filename, $line) = caller(++$frame);
  } while( $caller =~ /^FFI::Platypus(|::Function|::Function::Wrapper|::Declare)$/ );

  $perl_name = join '::', $caller, $perl_name
    unless $perl_name =~ /::/;

  $self->_attach($perl_name, "$filename:$line", $proto);
  $self;
}

sub sub_ref
{
  my($self) = @_;

  my $frame = -1;
  my($caller, $filename, $line);

  do {
    ($caller, $filename, $line) = caller(++$frame);
  } while( $caller =~ /^FFI::Platypus(|::Function|::Function::Wrapper|::Declare)$/ );

  $self->_sub_ref("$filename:$line");
}

package FFI::Platypus::Function::Wrapper;

use base qw( FFI::Platypus::Function );

sub new
{
  my($class, $function, $wrapper) = @_;
  bless [ $function, $wrapper ], $class;
}

sub call
{
  my($function, $wrapper) = @{ shift() };
  @_ = ($function, @_);
  goto &$wrapper;
}

sub attach
{
  my($self, $perl_name, $proto) = @_;
  my($function, $wrapper) = @{ $self };

  unless($perl_name =~ /::/)
  {
    my $caller;
    my $frame = -1;
    do { $caller = caller(++$frame) } while( $caller =~ /^FFI::Platypus(|::Declare)$/ );
    $perl_name = join '::', $caller, $perl_name
  }

  my $xsub = $function->sub_ref;

  {
    my $code = sub {
      unshift @_, $xsub;
      goto &$wrapper;
    };
    if(defined $proto)
    {
      _set_prototype($proto, $code);
    }
    no strict 'refs';
    *{$perl_name} = $code;
  }

  $self;
}

sub sub_ref
{
  my($self) = @_;
  my($function, $wrapper) = @{ $self };
  my $xsub = $function->sub_ref;

  return sub {
    unshift @_, $xsub;
    goto &$wrapper;
  };
}

1;
