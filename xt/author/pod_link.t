use Test2::Require::Module 'Test::Pod::LinkCheck::Lite';
use Test2::Require::EnvVar 'POD_CHECK';
use Test2::V0;
use Test::Pod::LinkCheck::Lite;

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

Test::Pod::LinkCheck::Lite
  ->new
  ->all_pod_files_ok(@checks);

done_testing;
