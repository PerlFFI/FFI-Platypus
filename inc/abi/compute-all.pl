use strict;
use warnings;
use feature qw( say );
use Path::Tiny qw( path );
use Git::Wrapper;
use File::chdir;
use JSON::PP ();

# Only intended for use by the Platypus maintainer!
# Sometimes detecting the ABIs from the C compiler pre-processor is unreliable
# so we can look in the libffi source for all possible ABIs for all possible
# platforms and just try them all.  This computes the list from the latest
# source (or libffi directory as specified by LIBFFI_ROOT).  This list will
# used by the config step to detect ABIs available on your platform.

my $libffi_root;

if(defined $ENV{LIBFFI_ROOT})
{
  die "no such directory: $ENV{LIBFFI_ROOT}" unless -d $ENV{LIBFFI_ROOT};
  $libffi_root = path($ENV{LIBFFI_ROOT});
}
else
{
  require Git::Wrapper;
  $libffi_root = Path::Tiny->tempdir;
  my $git = Git::Wrapper->new($libffi_root);
  $git->clone('--depth=2', 'https://github.com/libffi/libffi.git', $libffi_root);
}

say $libffi_root;

my %abis;

$libffi_root->visit(
  sub {
    my($path) = @_;
    return if $path->is_dir;
    return unless $path->basename eq 'ffitarget.h';
    say '  ' . $path->relative($libffi_root);

    my $c = $path->slurp;
    if($c =~ m/typedef\s+enum\s+ffi_abi\s+{(.*?)}/s)
    {
      my $c = $1;
      while($c =~ s/FFI_([A-Z_0-9]+)//)
      {
        my $abi = $1;
        next if $abi =~ /^(FIRST|LAST|DEFAULT)_ABI$/;
        say '    ', $abi;
        $abis{$abi}++;
      }
    }
    else
    {
      say '    no abis';
    }
  },
  { recurse => 1 },
);

path(__FILE__)->parent->child("abis-all.json")->spew_raw(JSON::PP->new->pretty(1)->encode([sort keys %abis]));
