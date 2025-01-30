use IO::Socket;
unlink 'tmp_udp.tmp';
$server = IO::Socket::UNIX->new(
    Local => 'tmp_udp.tmp',
    Type  => SOCK_DGRAM
) or die "Can't create UNIX UDP server";
while ($server->recv(my $message, 1024)) {
    print "Received: $message\n";
}
close($server);
