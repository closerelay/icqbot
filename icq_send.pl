#!/usr/bin/perl -w

use IO::Socket::INET;
use strict;

use constant {
	SERVER => '192.168.0.3',
	PORT => 6666
};

if($ARGV[0] =~ /\d+/ ) {
	my $socket = IO::Socket::INET->new(Proto => 'tcp', PeerPort => PORT, PeerAddr => SERVER);
	$socket->send(join(" ", @ARGV));
}
