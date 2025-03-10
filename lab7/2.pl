#!/usr/bin/perl

use strict;
use warnings;
use IO::Socket;

sub client_inet_tcp {
    my $exitFlag = 1;
    while ($exitFlag) {
        my $client = IO::Socket::INET->new(
            PeerHost => '127.0.0.1',
            PeerPort => 8080,
            Proto    => 'tcp',
        ) or die "Could not create socket: $!";

        print "Message: ";
        my $line = <STDIN>;
        chomp $line;
        print $client $line;

        $client->close;

        if ($line eq "exit") {
            $exitFlag = 0;
        }
    }
}

sub client_inet_udp {
    my $client = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => 8080,
        Proto    => 'udp',
    ) or die "Could not create socket: $!";

    my $exitFlag = 1;
    while ($exitFlag) {
        print "Message: ";
        my $line = <STDIN>;
        chomp $line;
        $client->send($line, 0);

        if ($line eq "exit") {
            $exitFlag = 0;
        }
    }

    $client->close;
}

sub client_unix_tcp {
    my $socket_path = '/tmp/my_unix_socket';

    my $exitFlag = 1;
    while ($exitFlag) {
        my $client = IO::Socket::UNIX->new(
            Peer => $socket_path,
            Type => SOCK_STREAM,
            Timeout => 10
        ) or die "Couldn't create socket: $!";

        print "Message: ";
        my $line = <STDIN>;
        chomp $line;
        print $client $line;

        $client->close;

        if ($line eq "exit") {
            $exitFlag = 0;
        }
    }
}

sub client_unix_udp {
    my $socket_path = '/tmp/my_unix_socket';
    my $client = IO::Socket::UNIX->new(
        Peer => $socket_path,
        Type => SOCK_DGRAM,
        Timeout => 10
    ) or die "Couldn't create socket: $!";

    my $exitFlag = 1;
    while ($exitFlag) {
        print "Message: ";
        my $line = <STDIN>;
        chomp $line;
        $client->send($line, 0);

        if ($line eq "exit") {
            $exitFlag = 0;
        }
    }

    $client->close;
}

sub server_inet_tcp {
    my $server = IO::Socket::INET->new(
        LocalHost => '127.0.0.1',
        LocalPort => 8080,
        Proto     => 'tcp',
        Listen    => SOMAXCONN,
        Reuse     => 1
    ) or die "Could not create socket: $!";

    while (my $client = $server->accept) {
        while (my $request = <$client>) {
            chomp $request;
            if ($request eq "exit") {
                $client->close;
                $server->close;
                return;
            }
            print "Received: $request\n";
        }
        $client->close;
    }
    $server->close;
}

sub server_inet_udp {
    my $server = IO::Socket::INET->new(
        LocalPort => 8080,
        Proto     => 'udp',
        Reuse     => 1
    ) or die "Could not create socket: $!";

    while (1) {
        my $data = $server->recv(my $buffer, 1024, 0);
        if ($buffer eq "exit") {
            $server->close;
            return;
        }
        print "Received: $buffer\n";
    }

    $server->close;
}

sub server_unix_tcp {
    my $socket_path = '/tmp/my_unix_socket';
    unlink $socket_path;

    my $server = IO::Socket::UNIX->new(
        Local => $socket_path,
        Type => SOCK_STREAM,
        Listen => SOMAXCONN,
        Reuse => 1
    ) or die "Couldn't create socket: $!";

    while (my $client = $server->accept) {
        while (my $request = <$client>) {
            chomp $request;
            if ($request eq "exit") {
                $client->close;
                $server->close;
                return;
            }
            print "Received: $request\n";
        }
        $client->close;
    }
    $server->close;
}

sub server_unix_udp {
    my $socket_path = '/tmp/my_unix_socket';
    unlink $socket_path;

    my $server = IO::Socket::UNIX->new(
        Local => $socket_path,
        Type => SOCK_DGRAM,
        Listen => SOMAXCONN,
        Reuse => 1
    ) or die "Couldn't create socket: $!";

    while (1) {
        my $data = $server->recv(my $buffer, 1024, 0);
        if ($buffer eq "exit") {
            $server->close;
            return;
        }
        print "Received: $buffer\n";
    }

    $server->close;
}

if (@ARGV && ($ARGV[0] eq "client" || $ARGV[0] eq "server")) {
    my $domain = $ARGV[1] || "1";  # Default to INET
    my $proto = $ARGV[2] || "1";   # Default to TCP
    
    if ($ARGV[0] eq "client") {
        if ($domain eq "1") {
            if ($proto eq "1") {
                print "Client with TCP/INET has started\n\n";
                client_inet_tcp();
            } else {
                print "Client with UDP/INET has started\n\n";
                client_inet_udp();
            }
        } else {
            if ($proto eq "1") {
                print "Client with TCP/UNIX has started\n\n";
                client_unix_tcp();
            } else {
                print "Client with UDP/UNIX has started\n\n";
                client_unix_udp();
            }
        }
    } else {
        if ($domain eq "1") {
            if ($proto eq "1") {
                print "Server with TCP/INET has started\n\n";
                server_inet_tcp();
            } else {
                print "Server with UDP/INET has started\n\n";
                server_inet_udp();
            }
        } else {
            if ($proto eq "1") {
                print "Server with TCP/UNIX has started\n\n";
                server_unix_tcp();
            } else {
                print "Server with UDP/UNIX has started\n\n";
                server_unix_udp();
            }
        }
    }
    exit;
}

print "Enter the domain type: PF_INET (1) or PF_UNIX (2): ";
my $domain = <STDIN>;
chomp $domain;
print "Enter the protocol: tcp (1) or udp (2): ";
my $proto = <STDIN>;
chomp $proto;
print "\n\n";
print "Type \"exit\" to stop the program\n\n";

if ($domain && $proto) {
    if ($^O eq 'darwin') {  # macOS
        my $current_dir = `pwd`;
        chomp($current_dir);
        
        my $apple_script = <<APPLESCRIPT;
tell application "Terminal"
    do script "cd $current_dir && perl $0 server $domain $proto"
    delay 3
    do script "cd $current_dir && perl $0 client $domain $proto"
    activate
end tell
APPLESCRIPT

        open(my $fh, '>', '/tmp/terminal_script.scpt') or die "Could not open file: $!";
        print $fh $apple_script;
        close $fh;
        
        system("osascript /tmp/terminal_script.scpt");
        unlink('/tmp/terminal_script.scpt');  # Clean up
        
        print "Server and client windows should be open now.\n";
    } else {
        print "Separate terminal functionality is only implemented for macOS.\n";
        print "Please run the client and server manually:\n";
        print "perl $0 server\n";
        print "perl $0 client\n";
    }
}