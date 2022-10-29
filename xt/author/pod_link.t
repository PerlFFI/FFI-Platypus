use Test2::Require::Module 'Test::Pod::LinkCheck::Lite';
use Test2::Require::EnvVar 'POD_CHECK';
use Test2::V0;
use Test::Pod::LinkCheck::Lite;
use Path::Tiny qw( path );
use HTTP::Tiny::Mech;
use WWW::Mechanize::Cached;
use CHI;

my @checks;

if(-d 'blib/script')
{
  push @checks, 'blib/script';
}
elsif(-d 'bin')
{
  push @checks, 'bin';
}

if(-d 'blib')
{
  push @checks, 'blib';
}
else
{
  push @checks, 'lib';
  diag "checking lib instead of blib";
}

my $dir = path('~/.xor/cache');
$dir->mkpath;
$dir->chmod(0700);
my $ua = HTTP::Tiny::Mech->new(
  mechua => WWW::Mechanize::Cached->new(
    cache => CHI->new(
      # keep cache around for 24hrs
      expires_in => 60*60*24,
      driver     => 'File',
      root_dir   => $dir->stringify,
    ),
  ),
);

my $mock1 = mock 'Test::Pod::LinkCheck::Lite' => (
  override => [
    _user_agent => sub { $ua },
  ],
);

# WWW::Mechanize::Cached gets confused by HEAD
# requests and thinks they are invalid because
# content-length is non-zero (as it should be)
my $mock2 = mock 'HTTP::Tiny::Mech' => (
  override => [
    head => sub { shift->get(@_) },
  ],
);

Test::Pod::LinkCheck::Lite
  ->new
  ->all_pod_files_ok(@checks);

done_testing;
