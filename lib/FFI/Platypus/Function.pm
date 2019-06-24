package FFI::Platypus::Function;

use strict;
use warnings;
use FFI::Platypus;

# ABSTRACT: An FFI function object
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus;
 
 # call directly
 my $ffi = FFI::Platypus->new;
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
than using the C<call> method above.  It can also tie up resources,
because an C<attach> is done under the hood, which keeps an xsub
around, even if the returned code reference falls out of scope.

Thus, this is essentially a shortcut for:

 $f->attach("Generated::Function::name");
 my $code = \&Generated::Function::name;

But it can be useful when you just need a sub reference and don't
care about the "real" name.

=cut

use overload '&{}' => sub {
  my $ffi = shift;
  sub { $ffi->call(@_) };
};

use overload 'bool' => sub {
  my $ffi = shift;
  return $ffi;
};

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

{
  my $serial = 0;

  sub sub_ref
  {
    my($self) = @_;
    my $perl_name = "FFI::Platypus::Function::Serial::S@{[ $serial++ ]}";
    $self->attach($perl_name);
    my $xsub_ref = \&{$perl_name};

    ## it would be nice to be able to undef this
    ## but then the xsub_ref won't work.
    #undef &{$perl_name};

    ## we also reveal the name of the real sub.  It would be better
    ## to use Sub::Name to rename it to something else, though not
    ## crazy about adding that as a dep.

    $xsub_ref;
  }
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
    no strict 'refs';
    *{$perl_name} = sub {
      unshift @_, $xsub;
      goto &$wrapper;
    };
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
