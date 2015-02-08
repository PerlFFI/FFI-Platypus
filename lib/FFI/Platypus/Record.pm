package FFI::Platypus::Record;

use strict;
use warnings;
use Carp qw( croak );
use FFI::Platypus;
use base qw( Exporter );

our @EXPORT = qw( record_layout );

# ABSTRACT: FFI support for structured records data
# VERSION

=head1 SYNOPSIS

 package MyRecord;
 
 use FFI::Platypus::Record;
 
 record_layout(
   int => 'my_int_member',
   short => 'my_short_member',
 );
 
 package main;
 
 my $record = MyRecord->new(
   my_int_member => 42,
   my_short_member => -2,
 );
 
 print "my_int_member = ", $record->my_int_member, "\n";
 print "my_short_member = ", $record->my_short_member, "\n";
 
 $record->my_int_member(100);
 $record->my_short_member(400);

=head1 DESCRIPTION

[version 0.21]

This module provides an interface for creating accessors to
record members.  A record is a series of bytes that have a
structure understood by the C library that you are interfacing
with.  In C structured data records are known simply as
a C<struct>.

=head1 FUNCTIONS

=head2 record_layout

 record_layout($ffi, $type => $name, ... );
 record_layout($type => $name, ... );

Define the layout of the record.  You may optionally provide
an instance of L<FFI::Platypus> as the first argument in order
to use its type aliases.  Then you provide members as type/name
pairs.

This function will also generate a constructor C<new> and a
size accessor C<_ffi_record_size> so that it can be used as a
Platypus type.

=cut

sub record_layout
{
  my $ffi = ref($_[0]) ? shift : FFI::Platypus->new;
  my $offset = 0;
  my $record_align = 0;
  
  croak "uneven number of arguments!" if scalar(@_) % 2;
  
  my($caller, $filename, $line) = caller;

  if($caller->can("_ffi_record_size")
  || $caller->can("ffi_record_size"))
  {
    croak "record already defined for the class $caller";
  }
  
  while(@_)
  {
    my $type = shift;
    my $name = shift;
    
    croak "illegal name $name"
      unless $name =~ /^[A-Za-z_][A-Za-z_0-9]*$/
      ||     $name eq ':';
    croak "accessor/method $name already exists"
      if $caller->can($name);
    
    my $size  = $ffi->sizeof($type);
    my $align = $ffi->alignof($type);
    $record_align = $align if $align > $record_align;
    #my $meta  = $ffi->type_meta($type);
    
    $offset++ while $offset % $align;    

    if($name ne ':')
    {
      $name = join '::', $caller, $name;
      my $error_str =_accessor
        $name,
        "$filename:$line",
        $ffi->_type_lookup($type),
        $offset;
      croak($error_str) if $error_str;
    };
    
    $offset += $size;
  }
  
  my $size = $offset;
  
  no strict 'refs';
  *{join '::', $caller, "_ffi_record_size"}  = sub () { $size         };
  *{join '::', $caller, "_ffi_record_align"} = sub () { $record_align };
  *{join '::', $caller, "new"} = sub {
    my $class = shift;
    croak "uneven number of arguments to record constructor"
      if @_ % 2;
    my $record = "\0" x $size;
    my $self = bless \$record, $class;
    
    while(@_)
    {
      my $key = shift;
      my $value = shift;
      
      $self->$key($value);
    }
    
    $self;
  };
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The main platypus documentation.

=back

=cut
