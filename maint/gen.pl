#!/usr/bin/env perl

use strict;
use warnings;

my @list = sort map { chomp; s/\.pm$//; s/^lib\///; s/\//::/g; $_ } `find lib -name \*.pm`;

open my $fh, '>', 't/01_use.t';

print $fh <<'EOM';
use strict;
use warnings;
use Test::More;

EOM

foreach my $module (@list)
{
  print $fh "require_ok '$module';\n";
}

foreach my $module (@list)
{
  my $test = lc $module;
  $test =~ s/::/_/g;
  $test = "t/$test.t";
  printf $fh "ok -f %-55s %s\n", "'$test',", "'test for $module';";
}

print $fh <<'EOM';
done_testing;

EOM

close $fh;

