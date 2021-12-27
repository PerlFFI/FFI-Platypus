package FFI::Build::Plugin;

use strict;
use warnings;
use autodie;
use File::Spec::Functions qw( catdir catfile );

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

sub new
{
  my($class) = @_;

  my %plugins;

  foreach my $inc (@INC)
  {
    # CAVEAT: won't work with an @INC hook.  Plugins must be in a "real" directory.
    my $path = catdir($inc, 'FFI', 'Build', 'Plugin');
    next unless -d $path;
    my $dh;
    opendir $dh, $path;
    my @list = readdir $dh;
    closedir $dh;

    foreach my $name (map { my $x = $_; $x =~ s/\.pm$//; $x } grep /\.pm$/, @list)
    {
      next if defined $plugins{$name};
      my $pm = catfile('FFI', 'Build', 'Plugin', "$name.pm");
      require $pm;
      my $class = "FFI::Build::Plugin::$name";
      if($class->can("api_version") && $class->api_version == 0)
      {
        $plugins{$name} = $class->new;
      }
      else
      {
        warn "$class is not the correct api version.  You may need to upgrade the plugin, platypus or uninstall the plugin";
      }
    }
  }

  bless \%plugins, $class;
}

sub call
{
  my($self, $method, @args) = @_;

  foreach my $name (sort keys %$self)
  {
    my $plugin = $self->{$name};
    $plugin->$method(@args) if $plugin->can($method);
  }

  1;
}

1;
