use strict;
use warnings;
use Test::More tests => 23;
use FFI::CheckLib;
use FFI::Platypus::Declare qw( opaque int void string );
use FFI::Platypus::Memory qw( malloc free strdup );

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

attach [pointer_null => 'null']           => []          => opaque;
attach [pointer_is_null => 'is_null']     => [opaque]    => int;
attach [pointer_set_my_pointer => 'setp'] => [opaque]    => void;
attach [pointer_get_my_pointer => 'getp'] => []          => opaque;
attach [pointer_get_my_pointer_arg => 'geta'] => ['opaque*'] => void;

is null(), undef, 'null = undef';
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

attach [pointer_arg_array_in  => 'aa_in']  => ['opaque[3]'] => int;
attach [pointer_arg_array_null_in  => 'aa_null_in']  => ['opaque[3]'] => int;
attach [pointer_arg_array_out => 'aa_out'] => ['opaque[3]'] => void;
attach [pointer_arg_array_null_out => 'aa_null_out'] => ['opaque[3]'] => void;

do {
  my @stuff = map { strdup $_ } qw( one two three );
  is aa_in([@stuff]), 1, "aa_in([one two three])";
  free $_ for @stuff;
};

is aa_null_in([undef,undef,undef]), 1, "aa_null_in([undef,undef,undef])";

do {
  my @list = (undef,undef,undef);
  aa_out(\@list);
  is_deeply [map { cast opaque => string, $_ } @list], [qw( four five six )], 'aa_out()';
};

do {
  my @list1 = (malloc 32, malloc 32, malloc 32);
  my @list2 = @list1;
  aa_null_out(\@list2);
  is_deeply [@list2], [undef,undef,undef], 'aa_null_out()';
  free $_ for @list1;
};

attach [pointer_ret_array_out => 'ra_out'] => [] => 'opaque[3]';
attach [pointer_ret_array_null_out => 'ra_null_out'] => [] => 'opaque[3]';

is_deeply [map { cast opaque => string, $_ } @{ ra_out() } ], [qw( seven eight nine )], "ra_out()";
is_deeply ra_null_out(), [undef,undef,undef], 'ra_null_out';


attach [pointer_pointer_pointer_to_pointer => 'pp2p'] => ['opaque*'] => opaque;
attach [pointer_pointer_to_pointer_pointer => 'p2pp'] => [opaque] => 'opaque*';

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

attach [pointer_set_closure => 'set_closure']   => ['(opaque)->opaque'] => void;
attach [pointer_call_closure => 'call_closure'] => [opaque] => opaque;

my $save = 1;
my $closure = closure { $save = $_[0] };

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
  plan tests => 2;
  custom_type type1 => { perl_to_native => sub { 
    is cast(opaque=>string,$_[0]), "abc";
    free $_[0];
    strdup "def";
  } };
  attach [pointer_set_my_pointer => 'custom1_setp'] => ['type1'] => void;
  
  custom1_setp(strdup("abc"));
  
  my $ptr = getp();
  is cast(opaque=>string,$ptr), "def";
  free $ptr;
};

subtest 'custom type output' => sub {
  plan tests => 2;

  setp(strdup("ABC"));
  
  custom_type type2 => { native_to_perl => sub {
    is cast(opaque=>string,$_[0]), "ABC";
    free $_[0];
    "DEF";
  } };
  
  attach [pointer_get_my_pointer => 'custom2_getp'] => [] => 'type2';
  
  is custom2_getp(), "DEF";
  
  setp(undef);
};
