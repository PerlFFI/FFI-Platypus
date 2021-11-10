use Test2::V0 -no_srand => 1;
use FFI::Build::Plugin;
use File::Spec::Functions qw( catdir rel2abs );

{
  note "\@INC[]=$_" for @INC;

  is(
    FFI::Build::Plugin->new,
    object {
      call [isa => 'FFI::Build::Plugin'] => T();
    },
    'works with local config',
  );
}

{
  local @INC = @INC;
  push @INC, rel2abs(catdir(qw( corpus ffi_build_plugin lib2 )));
  note "\@INC[]=$_" for @INC;

  is(
    FFI::Build::Plugin->new,
    object {
      call [isa => 'FFI::Build::Plugin'] => T();
    },
    'works with local + empty dir',
  );
}

{
  local @INC = rel2abs(catdir(qw( corpus ffi_build_plugin lib2 )));
  note "\@INC[]=$_" for @INC;

  is(
    FFI::Build::Plugin->new,
    object {
      call [isa => 'FFI::Build::Plugin'] => T();
      call [call => 'bar', 'one', 'two','three'] => T();
      field Foo1 => object {
        call [isa => 'FFI::Build::Plugin::Foo1'] => T();
        field bar => [qw( one two three )];
      };
      field Foo2 => object {
        call [isa => 'FFI::Build::Plugin::Foo2'] => T();
      };
    },
  );
}

done_testing;
