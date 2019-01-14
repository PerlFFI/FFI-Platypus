package FFI::Platypus::Function;

use strict;
use warnings;
use FFI::Platypus;

# ABSTRACT: An FFI function object
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus;

 my $ffi = FFI::Platypus->new;
 my $f = $ffi->function(puts => ['string'] => 'int');
 $f->call("hello there");

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

1;
