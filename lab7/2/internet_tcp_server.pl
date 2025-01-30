use IO::Socket;
$server_port = 1027;
$server = IO::Socket::INET->new(
    LocalPort => $server_port,
    Type      => SOCK_STREAM,
    Reuse     => 1,
    Listen    => 20
) or die "Can't use port: $server_port";
while ($client = $server->accept()) {
    print <$client>;
    close($client);
}
close($server);
