use IO::Socket;
$server_port = 1029;
$server = IO::Socket::INET->new(
    LocalPort => $server_port,
    Type      => SOCK_STREAM,
    Reuse     => 1,
    Listen    => 20
) or die "Can't use port: $server_port";

while ($client = $server->accept()) {
    print "Client connected\n";
    while (<$client>) {
        print "Received from client: $_";
        print $client "Server response: $_";
    }
    close($client);
}
close($server);
