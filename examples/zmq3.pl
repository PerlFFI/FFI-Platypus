use strict;
use warnings;
use constant ZMQ_IO_THREADS  => 1;
use constant ZMQ_MAX_SOCKETS => 2;
use constant ZMQ_REQ => 3;
use constant ZMQ_REP => 4;
use FFI::CheckLib qw( find_lib_or_exit );
use FFI::Platypus;
use FFI::Platypus::Memory qw( malloc );
use FFI::Platypus::Buffer qw( scalar_to_buffer buffer_to_scalar );

my $endpoint = "ipc://zmq-ffi-$$";
my $ffi = FFI::Platypus->new( api => 1 );

$ffi->lib(undef); # for puts
$ffi->attach(puts => ['string'] => 'int');

$ffi->lib(find_lib_or_exit lib => 'zmq');
$ffi->attach(zmq_version => ['int*', 'int*', 'int*'] => 'void');

my($major,$minor,$patch);
zmq_version(\$major, \$minor, \$patch);
puts("libzmq version $major.$minor.$patch");
die "this script only works with libzmq 3 or better" unless $major >= 3;

$ffi->type('opaque'       => 'zmq_context');
$ffi->type('opaque'       => 'zmq_socket');
$ffi->type('opaque'       => 'zmq_msg_t');
$ffi->attach(zmq_ctx_new  => [] => 'zmq_context');
$ffi->attach(zmq_ctx_set  => ['zmq_context', 'int', 'int'] => 'int');
$ffi->attach(zmq_socket   => ['zmq_context', 'int'] => 'zmq_socket');
$ffi->attach(zmq_connect  => ['opaque', 'string'] => 'int');
$ffi->attach(zmq_bind     => ['zmq_socket', 'string'] => 'int');
$ffi->attach(zmq_send     => ['zmq_socket', 'opaque', 'size_t', 'int'] => 'int');
$ffi->attach(zmq_msg_init => ['zmq_msg_t'] => 'int');
$ffi->attach(zmq_msg_recv => ['zmq_msg_t', 'zmq_socket', 'int'] => 'int');
$ffi->attach(zmq_msg_data => ['zmq_msg_t'] => 'opaque');
$ffi->attach(zmq_errno    => [] => 'int');
$ffi->attach(zmq_strerror => ['int'] => 'string');

my $context = zmq_ctx_new();
zmq_ctx_set($context, ZMQ_IO_THREADS, 1);

my $socket1 = zmq_socket($context, ZMQ_REQ);
zmq_connect($socket1, $endpoint);

my $socket2 = zmq_socket($context, ZMQ_REP);
zmq_bind($socket2, $endpoint);

do { # send
  our $sent_message = "hello there";
  my($pointer, $size) = scalar_to_buffer $sent_message;
  my $r = zmq_send($socket1, $pointer, $size, 0);
  die zmq_strerror(zmq_errno()) if $r == -1;
};

do { # recv
  my $msg_ptr  = malloc 100;
  zmq_msg_init($msg_ptr);
  my $size     = zmq_msg_recv($msg_ptr, $socket2, 0);
  die zmq_strerror(zmq_errno()) if $size == -1;
  my $data_ptr = zmq_msg_data($msg_ptr);
  my $recv_message = buffer_to_scalar $data_ptr, $size;
  print "recv_message = $recv_message\n";
};
