use IO::Socket;
$client = IO::Socket::UNIX->new(
    Peer => 'tmp_udp.tmp',
    Type => SOCK_DGRAM
) or die "Can't create UNIX UDP client";
$client->send("UNIX socket UDP\n");
close($client);
