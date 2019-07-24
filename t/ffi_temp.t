use strict;
use warnings;
use Test::More;
use FFI::Temp;

my $dir = FFI::Temp->newdir;
ok -d $dir;
note "dir = $dir";

my $fh = FFI::Temp->new;
close $fh;
note "file = @{[ $fh->filename ]}";

done_testing;
