use strict;
use warnings;
use File::Temp qw( tempdir );

my $module = shift @ARGV;

my $skip;

unless($] > 5.010)
{
  $skip = "ZMQ::FFI requires Perl 5.10" if $module eq 'ZMQ::FFI';
}

if($skip)
{
  print $skip, "\n";
  exit;
}

my $lib = tempdir( CLEANUP => 1 );

my @cmd = ( 'cpanm', '-n', '-l' => $lib, '--installdeps', $module );

print "+@cmd\n";
system @cmd;
exit 2 if $?;


@cmd = ( 'cpanm', '-l' => $lib, '-v', '--reinstall', $module );
print "+@cmd\n";
system @cmd;

if($?)
{
  system 'tail', -f => '/home/travis/.cpanm/build.log';
  exit 2
}
