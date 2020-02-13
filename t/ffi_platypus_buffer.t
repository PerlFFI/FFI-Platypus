use strict;
use warnings;
use utf8;
use B;

# see https://github.com/Perl5-FFI/FFI-Platypus/issues/85
use if $^O ne 'MSWin32' || $] >= 5.018, 'open', ':std', ':encoding(utf8)';
use Test::More;
use Encode qw( decode );
use FFI::Platypus::Buffer;
use FFI::Platypus::Buffer qw( scalar_to_pointer grow set_used_length );

subtest simple => sub {
  my $orig = 'me grimlock king';
  my($ptr, $size) = scalar_to_buffer($orig);
  ok $ptr, "ptr = $ptr";
  my $ptr2 = scalar_to_pointer($orig);
  is $ptr2, $ptr, "scalar to pointer matches";
  is $size, 16, 'size = 16';
  my $scalar = buffer_to_scalar($ptr, $size);
  is $scalar, 'me grimlock king', "scalar = $scalar";
};

subtest unicode => sub {
  my $orig = 'привет';
  my($ptr, $size) = scalar_to_buffer($orig);
  ok $ptr, "ptr = $ptr";
  ok $size, "size = $size";
  my $scalar = decode('UTF-8', buffer_to_scalar($ptr, $size));
  is $scalar, 'привет', "scalar = $scalar";
};

subtest grow => sub {
    my $orig = 'me grimlock king';
    my($ptr, $size) = scalar_to_buffer($orig);
    my $sv = B::svref_2object( \$orig );
    is $sv->CUR, $size, "B::PV returns consistent string length";

    my $required = 100;
    ok $sv->LEN < $required, "initial buffer size is smaler than required";

  subtest clear => sub {
    my $str = $orig;

    # in my tests, you never get exactly what you ask for
    grow( $str, $required );
    my $sv = B::svref_2object( \$str );
    ok $sv->LEN >= $required, "buffer grew as expected";
    is $sv->CUR, 0,  "buffer contents cleared";
  };

  subtest "don't clear" => sub {
    my $str = $orig;

    # in my tests, you never get exactly what you ask for
    grow( $str, $required, 0 );
    my $sv = B::svref_2object( \$str );
    ok $sv->LEN >= $required, "buffer grew as expected";
    is $str, $orig,  "buffer contents remain";
  };

  subtest "fail on reference" => sub {
    my $ref = \$orig;
    eval { grow( $ref, 0 ); };
    my $err = $@;
    like ( $err, qr/argument error/, "croaked" );
  }


};

subtest set_used_length => sub {
    my $orig = 'me grimlock king';

   subtest 'length < max' => sub {
      my $str = $orig;
      my $len = set_used_length( $str, 3 );
      is( $len, 3, "requested length" );
      is( $str, "me ", "requested string" );
   };

   subtest 'length == max' => sub {
      my $str = $orig;
      my $sv = B::svref_2object( \$str );
      my $len = set_used_length( $str, $sv->LEN );
      is( $len, $sv->LEN, "requested length" );
   };

   subtest 'length > max' => sub {
      my $str = $orig;
      my $sv = B::svref_2object( \$str );
      my $len = set_used_length( $str, $sv->LEN + 10);
      is( $len, $sv->LEN, "maxed out length" );
   };

  subtest "fail on reference" => sub {
    my $ref = \$orig;
    eval { set_used_length( $ref, 0 ); };
    my $err = $@;
    like ( $err, qr/argument error/, "croaked" );
  }
};

done_testing;
