use strict;
use warnings;
use Test::More;
use FFI::CheckLib;
use FFI::Platypus;
use FFI::Platypus::Memory qw( malloc free );

my @lib = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

foreach my $api (0, 1, 2)
{

  subtest "api = $api" => sub {

    local $SIG{__WARN__} = sub {
      my $message = shift;
      return if $message =~ /^Subroutine main::.* redefined/;
      warn $message;
    };

    my $ffi = FFI::Platypus->new( api => $api, experimental => ($api >= 2 ? $api : undef), lib => [@lib] );

    $ffi->attach( [pointer_null => 'null']           => []          => 'opaque');
    $ffi->attach( [pointer_is_null => 'is_null']     => ['opaque']    => 'int');
    $ffi->attach( [pointer_set_my_pointer => 'setp'] => ['opaque']    => 'void');
    $ffi->attach( [pointer_get_my_pointer => 'getp'] => []          => 'opaque');
    $ffi->attach( [pointer_get_my_pointer_arg => 'geta'] => ['opaque*'] => 'void');

    is_deeply [null()], [$api >= 2 ? (undef) : ()], 'null = ()/undef';
    is is_null(undef), 1, 'is_null(undef) == 1';
    is is_null(), 1, 'is_null() == 1';

    my $ptr = malloc 32;
    is is_null($ptr), 0, 'is_null($ptr) = 0';

    setp($ptr);
    is getp(), $ptr, "setp($ptr); getp() = $ptr";

    do {
      my $tmp;
      geta(\$tmp);
      is $tmp, $ptr, "get(\$tmp); tmp = $ptr";
    };

    do {
      my $tmp = malloc 32;
      my $tmp2 = $tmp;
      setp(undef);
      geta(\$tmp);
      is $tmp, undef, "get(\\\$tmp); \\\$tmp = undef";
      free $tmp2;
    };

    free $ptr;

    $ffi->attach( [pointer_arg_array_in  => 'aa_in']  => ['opaque[3]'] => 'int');
    $ffi->attach( [pointer_arg_array_null_in  => 'aa_null_in']  => ['opaque[3]'] => 'int');
    $ffi->attach( [pointer_arg_array_out => 'aa_out'] => ['opaque[3]'] => 'void');
    $ffi->attach( [pointer_arg_array_null_out => 'aa_null_out'] => ['opaque[3]'] => 'void');

    do {
      my @stuff = map { perl_to_c_string_copy($_) } qw( one two three );
      is aa_in([@stuff]), 1, "aa_in([one two three])";
      free $_ for @stuff;
    };

    is aa_null_in([undef,undef,undef]), 1, "aa_null_in([undef,undef,undef])";

    do {
      my @list = (undef,undef,undef);
      aa_out(\@list);
      is_deeply [map { $ffi->cast('opaque' => 'string', $_) } @list], [qw( four five six )], 'aa_out()';
    };

    do {
      my @list1 = (malloc 32, malloc 32, malloc 32);
      my @list2 = @list1;
      aa_null_out(\@list2);
      is_deeply [@list2], [undef,undef,undef], 'aa_null_out()';
      free $_ for @list1;
    };

    $ffi->attach( [pointer_ret_array_out => 'ra_out'] => [] => 'opaque[3]');
    $ffi->attach( [pointer_ret_array_out_null_terminated => 'ra_out_nt'] => [] => 'opaque[]');
    $ffi->attach( [pointer_ret_array_null_out => 'ra_null_out'] => [] => 'opaque[3]');

    is_deeply [map { $ffi->cast('opaque' => 'string', $_) } @{ ra_out() } ], [qw( seven eight nine )], "ra_out()";
    is_deeply [map { $ffi->cast('opaque' => 'string', $_) } @{ ra_out_nt() } ], [qw( seven eight nine )], "ra_out_nt()";
    is_deeply ra_null_out(), [undef,undef,undef], 'ra_null_out';


    $ffi->attach( [pointer_pointer_pointer_to_pointer => 'pp2p'] => ['opaque*'] => 'opaque');
    $ffi->attach( [pointer_pointer_to_pointer_pointer => 'p2pp'] => ['opaque'] => 'opaque*');

    is pp2p(\undef), undef, 'pp2p(\undef) = undef';

    do {
      my $ptr = malloc 32;
      is pp2p(\$ptr), $ptr, "pp2p(\\$ptr) = $ptr";
      free $ptr;
    };

    is p2pp(undef), \undef, 'p2pp(undef) = \undef';

    do {
      my $ptr = malloc 32;
      is ${p2pp($ptr)}, $ptr, "pp2p($ptr) = \\$ptr";
      free $ptr;
    };

    $ffi->attach( [pointer_set_closure => 'set_closure']   => ['(opaque)->opaque'] => 'void');
    $ffi->attach( [pointer_call_closure => 'call_closure'] => ['opaque'] => 'opaque');

    my $save = 1;
    my $closure = $ffi->closure(sub { $save = $_[0] });

    set_closure($closure);

    is call_closure(undef), undef, "call_closure(undef) = undef";
    is $save, undef, "save = undef";

    do {
      my $ptr = malloc 32;

      is call_closure($ptr), $ptr, "call_closure(\\$ptr) = $ptr";
      is $save, $ptr, "save = $ptr";

      free $ptr;
    };

    subtest 'custom type input' => sub {
      $ffi->custom_type(type1 => { perl_to_native => sub {
        is $ffi->cast('opaque'=>'string',$_[0]), "abc";
        free $_[0];
        perl_to_c_string_copy("def");
      } });
      $ffi->attach(['pointer_set_my_pointer' => 'custom1_setp'] => ['type1'] => 'void');

      custom1_setp(perl_to_c_string_copy("abc"));

      my $ptr = getp();
      is $ffi->cast('opaque'=>'string',$ptr), "def";
      free $ptr;
    };

    subtest 'custom type output' => sub {

      setp(perl_to_c_string_copy("ABC"));

      $ffi->custom_type(type2 => { native_to_perl => sub {
        is $ffi->cast('opaque'=>'string',$_[0]), "ABC";
        free $_[0];
        "DEF";
      } });

      $ffi->attach([pointer_get_my_pointer => 'custom2_getp'] => [] => 'type2');

      is custom2_getp(), "DEF";

      setp(undef);
    };
  };
}

foreach my $api (1,2) {

  subtest 'object' => sub {

    { package Roger }

    my $ffi = FFI::Platypus->new( api => $api, experimental => ($api >= 2 ? $api : undef), lib => [@lib] );
    $ffi->type('object(Roger)', 'roger_t');
    $ffi->type('object(Roger,opaque)', 'roger2_t');

    my $ptr = malloc 200;

    subtest 'argument' => sub {

      is $ffi->cast('roger_t' => 'opaque', bless(\$ptr, 'Roger')), $ptr;
      is $ffi->cast('roger2_t' => 'opaque', bless(\$ptr, 'Roger')), $ptr;

    };

    subtest 'return value' => sub {

      is $ffi->cast('opaque' => 'roger_t', undef), undef;

      my $obj1 = $ffi->cast('opaque' => 'roger_t', $ptr);
      isa_ok $obj1, 'Roger';
      is $$obj1, $ptr;

      my $obj2 = $ffi->cast('opaque' => 'roger2_t', $ptr);
      isa_ok $obj2, 'Roger';
      is $$obj2, $ptr;

    };

    is_deeply
      [$ffi->function( pointer_null => [] => 'roger_t' )->call],
      [$api >= 2 ? (undef) : ()],
    ;

    free $ptr;
  };
};

done_testing;

package
  MyPerlStrDup;

use FFI::Platypus::Memory qw( malloc memcpy );

sub main::perl_to_c_string_copy
{
  my($string) = @_;
  my $ptr = malloc(length($string)+1);
  memcpy($ptr, FFI::Platypus->new->cast('string' => 'opaque', $string), length($string)+1);
  $ptr;
};

