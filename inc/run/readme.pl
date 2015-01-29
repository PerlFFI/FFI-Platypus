use strict;
use warnings;
use Pod::Abstract;
use Pod::Simple::Text;

my $root = Pod::Abstract->load_file("lib/FFI/Platypus.pm");

foreach my $name (qw( SUPPORT CONTRIBUTING ))
{
  my($pod) = $root->select("/head1[\@heading=~{$name}]");
  $_->detach for $pod->select('//#cut');
  my $parser = Pod::Simple::Text->new;
  my $text;
  $parser->output_string( \$text );  
  $parser->parse_string_document( $pod->pod );
  
  open my $fh, '>', $name;
  print $fh $text;
  close $fh;
}

