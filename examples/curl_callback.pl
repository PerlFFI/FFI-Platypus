use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use FFI::Platypus::Buffer qw( window );
use constant CURLOPT_URL           => 10002;
use constant CURLOPT_WRITEFUNCTION => 20011;

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => find_lib_or_die(lib => 'curl'),
);

my $curl_handle = $ffi->function( 'curl_easy_init' => [] => 'opaque' )
                      ->call;

$ffi->function( 'curl_easy_setopt' => [ 'opaque', 'enum' ] => ['string'] )
    ->call($curl_handle, CURLOPT_URL, "https://pl.atypus.org" );

my $html;

my $closure = $ffi->closure(sub {
  my($ptr, $len, $num, $user) = @_;
  window(my $buf, $ptr, $len*$num);
  $html .= $buf;
  return $len*$num;
});

$ffi->function( 'curl_easy_setopt' => [ 'opaque', 'enum' ] => ['(opaque,size_t,size_t,opaque)->size_t'] => 'enum' )
    ->call($curl_handle, CURLOPT_WRITEFUNCTION, $closure);

$ffi->function( 'curl_easy_perform' => [ 'opaque' ] => 'enum' )
    ->call($curl_handle);

$ffi->function( 'curl_easy_cleanup' => [ 'opaque' ] )
    ->call($curl_handle);

if($html =~ /<title>(.*?)<\/title>/) {
  print "$1\n";
}
