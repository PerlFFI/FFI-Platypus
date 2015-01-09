# FIXME
use feature 'say';

use strict;
use warnings;

use FFI::Raw;

my $libzmq = 'libzmq.so.1';

my $zmq_init = FFI::Raw -> new(
	$libzmq, 'zmq_init',
	FFI::Raw::ptr,
	FFI::Raw::int
);

my $zmq_socket = FFI::Raw -> new(
	$libzmq, 'zmq_socket',
	FFI::Raw::ptr,
	FFI::Raw::ptr, FFI::Raw::int
);

my $zmq_connect = FFI::Raw -> new(
	$libzmq, 'zmq_connect',
	FFI::Raw::int,
	FFI::Raw::ptr, FFI::Raw::str
);

my $zmq_send = FFI::Raw -> new(
	$libzmq, 'zmq_send',
	FFI::Raw::int,
	FFI::Raw::ptr, FFI::Raw::ptr, FFI::Raw::int
);

my $zmq_msg_init_data = FFI::Raw -> new(
	$libzmq, 'zmq_msg_init_data',
	FFI::Raw::int,
	FFI::Raw::ptr, FFI::Raw::str, FFI::Raw::int, FFI::Raw::ptr,
	FFI::Raw::ptr
);

my $zmq_msg_data = FFI::Raw -> new(
	$libzmq, 'zmq_msg_data',
	FFI::Raw::str,
	FFI::Raw::ptr
);

# init zmq context
my $ctx = $zmq_init -> call(1);

# init zmq socket and bind
my $sock = $zmq_socket -> call($ctx, 3); # 3 is ZMQ_REQ
$zmq_connect -> call($sock, 'tcp://127.0.0.1:6666');

# send message to server
my $msg = FFI::Raw::memptr(40); # 40 is sizeof(zmq_msg_t)
$zmq_msg_init_data -> call($msg, 'some message', 4, 0, 0);

$zmq_send -> call($sock, $msg, 0);
