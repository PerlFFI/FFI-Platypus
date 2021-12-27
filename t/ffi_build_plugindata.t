use Test2::V0 -no_srand => 1;

{ package Foo;

  use FFI::Build::PluginData 'plugin_data';

  sub new { bless {}, __PACKAGE__ }
}

{ package FFI::Build::Plugin::Bar;

  sub new { bless {}, __PACKAGE__ }

  sub call_plugin_data
  {
    my($self, $foo) = @_;
    $foo->plugin_data;
  }

}

my $foo = Foo->new;

is(
  dies { $foo->plugin_data },
  match qr/^plugin_data must be called by a plugin/,
);

is(
  FFI::Build::Plugin::Bar->new,
  object {
    call [call_plugin_data => $foo] => {};
    call sub {
      my $plugin = shift;
      $plugin->call_plugin_data($foo)->{baz} = 1;
      1;
    } => 1;
    call [call_plugin_data => $foo] => { baz => 1 };
  },
);

is(
  $foo,
  { plugin_data => { Bar => { baz => 1 } } },
);

done_testing;

1;
