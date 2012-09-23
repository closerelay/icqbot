#!/usr/bin/perl -w

use Net::OSCAR;
use IO::Select;
use IO::Socket::INET;
use Time::HiRes qw/clock_gettime CLOCK_MONOTONIC/;
use POSIX qw(setsid);
use strict;
use constant {
	LOGIN => '123456789',
	PASSW => 'topsecret',
	DELAY => 10,
	SIZE  => 1024
};

#####################################################################

chdir '/' or die "Can't chdir to /: $!";
umask 0;
open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
open STDOUT, '>/dev/null' or die "Can't write to /dev/null: $!";
open STDERR, '>/dev/null' or die "Can't write to /dev/null: $!";
defined(my $pid = fork)   or die "Can't fork: $!";
exit if $pid;
setsid or die "Can't start a new session: $!";

#####################################################################

my $online;
my $icq = Net::OSCAR->new();
$icq->set_callback_signon_done(
	sub {
		$online = 1;
	}
);
$icq->set_callback_error(
	sub {
		my ($error, $fatal) = @_[3,4];
		$fatal ? die $error : warn $error;
	}
);

$icq->signon(LOGIN, PASSW);
$icq->loglevel(0);

my $last = clock_gettime(CLOCK_MONOTONIC);

my $socket = IO::Socket::INET->new(LocalAddr => '192.168.0.3', LocalPort => 6666, Listen => 20, Proto => 'tcp', Reuse => 1) or die $!;
my $select = IO::Select->new($socket) or die $!;

while (1) {
	if ($online && clock_gettime(CLOCK_MONOTONIC) - $last >= DELAY) {
		my @r = $select->can_read;
		for my $handle (@r) {
			if($handle eq $socket) {
				my $connect = $socket->accept();
				$select->add($connect);
			}
			else {
				my $client_input;
				while(sysread $handle, $_, SIZE) {
					$client_input .= $_;
					last if $_ =~ /\x0A/ or length $client_input >= SIZE;
				}
				$client_input =~ s/[\x00-\x08\x0A-\x1F]//g;
				if(length $client_input > 0) {
					my ($sendto, $msg) = $client_input =~ /(\d+)(\s.*)/;
					$icq->send_im($sendto, $msg);
					$last = clock_gettime(CLOCK_MONOTONIC);
				}
			
			}
		}
	}
	$icq->do_one_loop();
}

