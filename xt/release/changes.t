use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::CPAN::Changes' 
    unless eval q{ use Test::CPAN::Changes; 1 };
};
use Test::CPAN::Changes;
use FindBin;
use File::Spec;

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

do {
  my $old = \&Test::Builder::carp;
  my $new = sub {
    my($self, @messages) = @_;
    return if $messages[0] =~ /^Date ".*" is not in the recommend format/;
    $old->($self, @messages);
  };
  no warnings 'redefine';
  *Test::Builder::carp = $new;
};

changes_file_ok;

done_testing;
