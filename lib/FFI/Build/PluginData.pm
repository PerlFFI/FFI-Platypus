package FFI::Build::PluginData;

use strict;
use warnings;
use parent qw( Exporter );

our @EXPORT_OK = qw( plugin_data );

# ABSTRACT: Platform and local customizations of FFI::Build
# VERSION

=head1 SYNOPSIS

 perldoc FFI::Build

=head1 DESCRIPTION

This class is experimental, but may do something useful in the future.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

=item L<FFI::Build>

=back

=cut

sub plugin_data
{
  my($self) = @_;
  my $caller = caller;
  if($caller =~ /^FFI::Build::Plugin::(.*)$/)
  {
    return $self->{plugin_data}->{$1} ||= {};
  }
  else
  {
    require Carp;
    Carp::croak("plugin_data must be called by a plugin");
  }
}

1;
