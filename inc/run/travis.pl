use strict;
use warnings;
use File::Find;
use JSON::PP qw( encode_json decode_json );

my @list;

# worlds worst interface
find(sub {

  my $fn = $File::Find::name;
  return unless $fn =~ /\.pm/;
  push @list, $fn;

}, 'lib');

die "requires MYMETA.json" unless -f 'MYMETA.json';

my %meta = do {
  open my $fh, '<', 'MYMETA.json';
  my $meta = decode_json do { local $/; <$fh> };
  close $fh;
  %$meta;
};

foreach my $fn (@list)
{
  open my $in, '<', $fn;
  my @list = <$in>;
  close $in;
  
  @list = map { s/^(# VERSION.*)$/our \$VERSION = '$meta{version}'; $1/; $_ } @list;

  open my $out, '>', $fn;
  print $out @list;
  close $out;
}
