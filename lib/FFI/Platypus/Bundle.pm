package FFI::Platypus::Bundle;

use strict;
use warnings;

# ABSTRACT: Platypus Bundle code
# VERSION

=head1 DESCRIPTION

This class is private to L<FFI::Platypus>.

=cut

package FFI::Platypus;

sub _bundle
{
  my($self, $package) = @_;
  $package = caller unless defined $package;

  require List::Util;

  my($pm) = do {
    my $pm = "$package.pm";
    $pm =~ s{::}{/}g;
    # if the module is already loaded, we can use %INC
    # otherwise we can go through @INC and find the first .pm
    # this doesn't handle all edge cases, but probably enough
    List::Util::first(sub { (defined $_) && (-f $_) }, ($INC{$pm}, map { "$_/$pm" } @INC));
  };

  croak "unable to find module $package" unless $pm;

  my @parts = split /::/, $package;
  my $incroot = $pm;
  {
    my $c = @parts;
    $incroot =~ s![\\/][^\\/]+$!! while $c--;
  }

  my $txtfn = List::Util::first(sub { -f $_ }, do {
    my $dir  = join '/', @parts;
    my $file = $parts[-1] . ".txt";
    (
      "$incroot/auto/$dir/$file",
      "$incroot/../arch/auto/$dir/$file",
    );
  });

  my $lib;

  if($txtfn)
  {
    $lib = do {
      my $fh;
      open($fh, '<', $txtfn) or die "unable to read $txtfn $!";
      my $line = <$fh>;
      close $fh;
      $line =~ /^FFI::Build\@(.*)$/
        ? "$incroot/$1"
        : croak "bad format $txtfn";
    };
    croak "bundle code is missing: $lib" unless -f $lib;
  }
  elsif(-d "$incroot/../ffi")
  {
    require FFI::Build::MM;
    require Capture::Tiny;
    require Cwd;
    require File::Spec;
    my $save = Cwd::getcwd();
    chdir "$incroot/..";
    my($output, $error) = Capture::Tiny::capture_merged(sub {
      $lib = eval {
        my $dist_name = $package;
        $dist_name =~ s/::/-/;
        my $fbmm = FFI::Build::MM->new;
        $fbmm->mm_args( DISTNAME => $dist_name );
        my $build = $fbmm->load_build('ffi', undef, 'ffi/_build');
        $build->build;
      };
      $@;
    });
    if($error)
    {
      chdir $save;
      print STDERR $output;
      die $error;
    }
    else
    {
      $lib = File::Spec->rel2abs($lib);
      chdir $save;
    }
  }
  else
  {
    croak "unable to find bundle code for $package";
  }

  my $handle = FFI::Platypus::DL::dlopen($lib, FFI::Platypus::DL::RTLD_PLATYPUS_DEFAULT())
    or croak "error loading bundle code: $lib @{[ FFI::Platypus::DL::dlerror() ]}";

  $self->{handles}->{$lib} =  $handle;

  $self->lib($lib);

  my $init = eval { $self->function( 'ffi_pl_bundle_init' => 'opaque' ) };
  if($init)
  {
    require FFI::Platypus::Bundle::API;
    my $api = FFI::Platypus::Bundle::API->new($package);
    $init->call($api->ptr);
  }

  # TODO: fini

  $self;
}

1;
