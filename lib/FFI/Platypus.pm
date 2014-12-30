package FFI::Platypus;

use strict;
use warnings;
use 5.008001;

# ABSTRACT: Glue a duckbill to an adorable aquatic mammal
# VERSION

require XSLoader;
XSLoader::load('FFI::Platypus', $VERSION);

=head1 CONSTRUCTORS

=head2 new

 my $ffi = FFI::Platypus->new;

Create a new instance of L<FFI::Platypus>.

=cut

sub new
{
  my($class) = @_;
  bless { lib => [], handles => {}, }, $class;
}

=head1 ATTRIBUTES

=head2 lib

 $ffi->lib($path1, $path2, ...);
 my @paths = $ffi->lib;

The list of libraries to search for symbols in.

=cut

sub lib
{
  my($self, @new) = @_;
  if(@new)
  {
    push @{ $self->{lib} }, @new;
  }
  
  @{ $self->{lib} };
}

=head1 METHODS

=head2 find_symbol

 my $address = $ffi->find_symbol($name);

Return the address of the given symbol (usually function).

=cut

sub find_symbol
{
  my($self, $name) = @_;

  foreach my $path (@{ $self->{lib} })
  {
    my $handle = $self->{handles}->{$path} || FFI::Platypus::dl::dlopen($path);
    next unless $handle;
    my $address = FFI::Platypus::dl::dlsym($handle, $name);
    if($address)
    {
      $self->{handles}->{$path} = $handle;
      return $address;
    }
    else
    {
      FFI::Platypus::dl::dlclose($handle);
    }
  }
  return;
}

sub DESTROY
{
  my($self) = @_;
  # TODO: Need to remember not to free these if they
  # have been perminently attached as an xsub
  # TODO: also need to be ABLE to attach as an xsub :P
  foreach my $handle (values %{ $self->{handles} })
  {
    next unless $handle;
    FFI::Platypus::dl::dlclose($handle);
  }
}

1;
