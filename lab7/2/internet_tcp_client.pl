use IO::Socket;
$remote_host = 'localhost';
$remote_port = 1027;
$client = IO::Socket::INET->new(
    PeerAddr => $remote_host,
    PeerPort => $remote_port,
    Proto    => 'tcp',
    Type     => SOCK_STREAM
) or die "Can't connect to $remote_host";
print $client "Inet socket TCP\n";
close($client);
