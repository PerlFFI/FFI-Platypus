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

=head2 call

 my $ret = $f->call(@arguments);
 my $ret = $f->(@arguments);

Calls the function and returns the result.  You can also use the
function object like a code reference.

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
  } while( $caller =~ /^FFI::Platypus(|::Function|::Function::Wrapper)$/ );

  $perl_name = join '::', $caller, $perl_name
    unless $perl_name =~ /::/;

  $self->_attach($perl_name, "$filename:$line", $proto);
  $self;
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
  $wrapper->($function, @_);
}

my $counter = 0;

sub attach
{
  my($self, $perl_name, $proto) = @_;
  my($function, $wrapper) = @{ $self };

  unless($perl_name =~ /::/)
  {
    my $caller;
    my $frame = -1;
    do { $caller = caller(++$frame) } while( $caller eq 'FFI::Platypus' );
    $perl_name = join '::', $caller, $perl_name
  }

  my $attach_name = "FFI::Platypus::Inner::xsub@{[ $counter++ ]}";
  $function->attach($attach_name);
  my $xsub = \&{$attach_name};

  {
    no strict 'refs';
    *{$perl_name} = sub { $wrapper->($xsub, @_) };
  }

  $self;
}

1;
