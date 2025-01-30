use IO::Socket;
$server_port = 1028;
$server = IO::Socket::INET->new(
    LocalPort => $server_port,
    Proto     => 'udp'
) or die "Can't create UDP server";
while ($server->recv(my $message, 1024)) {
    print "Received: $message\n";
}
close($server);
