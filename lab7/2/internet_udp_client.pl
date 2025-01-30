use IO::Socket;
$remote_host = 'localhost';
$remote_port = 1028;
$client = IO::Socket::INET->new(
    PeerAddr => $remote_host,
    PeerPort => $remote_port,
    Proto    => 'udp'
) or die "Can't create UDP client";
$client->send("Inet socket UDP\n");
close($client);
