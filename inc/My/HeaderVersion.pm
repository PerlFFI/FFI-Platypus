package inc::My::HeaderVersion;

use Moose;

with 'Dist::Zilla::Role::FileMunger';

sub munge_files
{
  my($self) = @_;
  my $name = 'share/include/ffi_util.h';
  my($header) = grep { $_->name eq $name } @{ $self->zilla->files };
  $self->log_fatal("unable to find $name!") unless defined $header;
  my $content = $header->content;
  
  my $version = $self->zilla->version;
  $version =~ s{_.*$}{}; # trim off the trial portion of the version number
  $version = int( $version * 100 );
  $version = sprintf "%03s", $version;
  
  if($content =~ s{%%FFI_UTIL_VERSION%%}{$version})
  {
    $header->content($content);
    $self->log("set version in $name");
  }
  else
  {
    $self->log_fatal("unable to find %%FFI_UTIL_VERSION%% in header");
  }
}
