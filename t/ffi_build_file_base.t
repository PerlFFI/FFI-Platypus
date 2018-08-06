use strict;
use warnings;
use Test::More;
use FFI::Build::File::Base;

{
  package 
    FFI::Build::File::Foo;
  use base qw( FFI::Build::File::Base );
  use constant default_suffix    => '.foo';
  use constant default_encoding  => ':utf8';
}

subtest 'basic' => sub {

  subtest 'basic usage' => sub {
  
    eval { FFI::Build::File::Foo->new };
    my $error = $@;
    like $error, qr/content is required/;
    note "error = $error";
  
  };
  
  subtest 'array filename' => sub {
  
    my $file = FFI::Build::File::Foo->new(['corpus', 'basic.foo']);
    isa_ok $file, 'FFI::Build::File::Base';
    isa_ok $file, 'FFI::Build::File::Foo';
    is("$file", $file->path, "stringifies to path");
    is($file->slurp, "This is a basic foo.\n");
    ok(!$file->is_temp, "is_temp");
    is($file->basename, 'basic.foo', 'basename');
    ok(-d $file->dirname, 'dirname');
    note "dirname = @{[ $file->dirname ]}";
    unlike $file->path, qr/\\/, "No forward slashes!";

    if($^O eq 'MSWin32')
    {
      is($file->native, "corpus\\basic.foo", "native name");
    }
    else
    {
      is($file->native, $file->path, "native name");
    }
    note "native = @{[ $file->native ]}";
  };

  subtest 'string filename' => sub {
  
    my $file = FFI::Build::File::Foo->new("corpus/basic.foo");
    isa_ok $file, 'FFI::Build::File::Base';
    isa_ok $file, 'FFI::Build::File::Foo';
    is($file->slurp, "This is a basic foo.\n");
    ok(!$file->is_temp, "is_temp");
    unlike $file->path, qr/\\/, "No forward slashes!";

  };
  
  subtest 'string ref' => sub {
  
    my $file = FFI::Build::File::Foo->new(\"Something different!\n");
    isa_ok $file, 'FFI::Build::File::Base';
    isa_ok $file, 'FFI::Build::File::Foo';
    like($file->basename, qr/\.foo$/, 'has the correct extension');
    ok($file->is_temp, "is_temp");
    is($file->slurp, "Something different!\n");
    note "path: @{[ $file->path ]}";
    unlike $file->path, qr/\\/, "No forward slashes!";
    my $path = $file->path;
    ok(-f $path, "file exists");
    undef $file;
    ok(!-f $path, "file is removed after destroy");
  
  };
  
  subtest 'string ref keep' => sub {
  
    my $file = FFI::Build::File::Foo->new(\"Again\n");
    $file->keep;
    my $path = $file->path;
    is($file->slurp, "Again\n");
    ok(-f $path, "file exists");
    unlike $file->path, qr/\\/, "No forward slashes!";
    undef $file;
    ok(-f $path, "file exists after undef");
    unlink $path;

  };
  
};

done_testing;
