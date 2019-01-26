use strict;
use warnings;
use lib 'inc';
use My::Config;

my($key, @value) = @ARGV;
my @key = split /\./, $key;

my $config = My::Config->new;
$config->probe->set(@key, \@value);
