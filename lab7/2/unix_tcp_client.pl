use IO::Socket;
$client = IO::Socket::UNIX->new(
    Peer => 'tmp.tmp'
) or die "Can't connect to UNIX socket";
print $client "UNIX socket TCP\n";
close($client);
