package FFI::Platypus::Record::TieArray;

use strict;
use warnings;
use Carp qw( croak );

# ABSTRACT: Tied array interface for record array members
# VERSION

=head1 SYNOPSIS

 package Foo;
 
 use FFI::Platypus::Record;
 use FFI::Platypus::Record::TieArray;
 
 record_layout(qw(
   int[20]  _bar
 ));
 
 sub bar
 {
   my($self, $arg) = @_;
   $self->_bar($arg) if ref($arg) eq ' ARRAY';
   tie my @list, 'FFI::Platypus::Record::TieArray', 
     $self, '_bar', 20;
 }
 
 package main;
 
 my $foo = Foo->new;
 
 my $bar5 = $foo->bar->[5];  # get the 5th element of the bar array
 $foo->bar->[5] = 10;        # set the 5th element of the bar array
 @{ $foo->bar } = ();        # set all elements in bar to 0
 @{ $foo->bar } = (1..5);    # set the first five elements of the bar array
 
=head1 DESCRIPTION

B<WARNING>: This module is considered EXPERIMENTAL.  It may go away or 
be changed in incompatible ways, possibly without notice, but not 
without a good reason.

This class provides a tie interface for record array members.

In the future a short cut for using this with L<FFI::Platypus::Record> 
directly may be provided.

=cut

sub TIEARRAY
{
  my $class = shift;  
  bless [ @_ ], $class;
}

sub FETCH
{
  my($self, $key) = @_;
  my($obj, $member) = @$self;
  $obj->$member($key);
}

sub STORE
{
  my($self, $key, $value) = @_;
  my($obj, $member) = @$self;
  $obj->$member($key, $value);
}

sub FETCHSIZE
{
  my($self) = @_;
  $self->[2];
}

sub CLEAR
{
  my($self) = @_;
  my($obj, $member) = @$self;
  
  $obj->$member([]);
}

sub EXTEND
{
  my($self, $count) = @_;
  croak "tried to extend a fixed length array" if $count > $self->[2];
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The main Platypus documentation.

=item L<FFI::Platypus::Record>

Documentation on Platypus records.

=back

=cut
