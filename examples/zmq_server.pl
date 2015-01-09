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

my $zmq_bind = FFI::Raw -> new(
	$libzmq, 'zmq_bind',
	FFI::Raw::int,
	FFI::Raw::ptr, FFI::Raw::str
);

my $zmq_recv = FFI::Raw -> new(
	$libzmq, 'zmq_recv',
	FFI::Raw::int,
	FFI::Raw::ptr, FFI::Raw::ptr, FFI::Raw::int
);

my $zmq_msg_init = FFI::Raw -> new(
	$libzmq, 'zmq_msg_init',
	FFI::Raw::int,
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
my $sock = $zmq_socket -> call($ctx, 4); # 4 is ZMQ_REP
$zmq_bind -> call($sock, 'tcp://127.0.0.1:6666');

# receive message from client
my $msg = FFI::Raw::memptr(40); # 40 is sizeof(zmq_msg_t)
$zmq_msg_init -> call($msg);

$zmq_recv -> call($sock, $msg, 0);
say $zmq_msg_data -> call($msg);
