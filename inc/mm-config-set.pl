use strict;
use warnings;
use lib 'inc';
use My::Config;

my($key, @value) = @ARGV;
my @key = split /\./, $key;

my $config = My::Config->new;

use YAML ();
warn YAML::Dump(\@key);

my $probe;

if($key[0] && $key[0] eq 'eumm')
{ warn "1"; $probe = $config->probe2 }
else
{ warn "2"; $probe = $config->probe }

$probe->set(@key, \@value);
$probe->save;
