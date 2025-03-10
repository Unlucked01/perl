#!/usr/bin/perl

use IO::Socket;
use strict;
use warnings;

sub client {
    my $client = IO::Socket::INET->new(
            PeerHost => '127.0.0.1',
            PeerPort => 8080,
            Proto    => 'tcp',
        ) or die "Could not create socket: $!";

    print "Connected to server. Type 'exit' to quit.\n";
    
    while (1) {
        print "Enter the message: ";
        chomp(my $message = <STDIN>);
        
        if (!$client->connected()) {
            print "Connection to server lost.\n";
            return;
        }
        
        print $client $message . "\n";
        if ($message eq "exit") {
            print "Exiting client...\n";
            $client->close;
            return;
        }
        
        local $SIG{ALRM} = sub { die "Timeout waiting for server response\n" };
        alarm(10);
        my $response = <$client>;
        alarm(0);
        
        if (!defined $response) {
            print "Server disconnected\n";
            $client->close;
            return;
        }
        
        chomp $response;
        if ($response eq "exit") {
            print "Server requested to exit\n";
            $client->close;
            print "Client is shutting down...\n";
            return;
        }
        print "Received from server: $response\n";
    }
}

sub server {
    my $server = IO::Socket::INET->new(
        LocalHost => '127.0.0.1',
        LocalPort => 8080,
        Proto     => 'tcp',
        Listen    => SOMAXCONN,
        Reuse     => 1
    ) or die "Could not create socket: $!";

    print "Server started on 127.0.0.1:8080\n";
    print "Waiting for client connection...\n";
    
    while (my $client = $server->accept) {
        print "Client connected\n";
        
        while (my $request = <$client>) {
            chomp $request;
            if ($request eq "exit") {
                print "Client requested to exit\n";
                $client->close;
                last;  # close this client connection
            }
            print "Received: $request\n";
            print "Enter the message: ";
            chomp(my $message = <STDIN>);
            print $client "$message\n";
            if ($message eq "exit") {
                print "Closing connection with client...\n";
                $client->close;
                last;  # close this client connection, not the server
            }
        }
        print "Client disconnected\n";

        $client->close;
    }
    $server->close;
}

if (@ARGV && ($ARGV[0] eq "client" || $ARGV[0] eq "server")) {
    if ($ARGV[0] eq "client") {
        print "Client with TCP/INET has started\n\n";
        client();
    } else {
        print "Server with TCP/INET has started\n\n";
        server();
    }
    exit;
}

if ($^O eq 'darwin') {  # macOS
    my $current_dir = `pwd`;
    chomp($current_dir);
    
    my $apple_script = <<APPLESCRIPT;
tell application "Terminal"
    do script "cd $current_dir && perl $0 server"
    delay 3
    do script "cd $current_dir && perl $0 client"
    activate
end tell
APPLESCRIPT

    open(my $fh, '>', '/tmp/terminal_script.scpt') or die "Could not open file: $!";
    print $fh $apple_script;
    close $fh;
    
    system("osascript /tmp/terminal_script.scpt");
    unlink('/tmp/terminal_script.scpt');  # Clean up
}

print "Server and client windows should be open now.\n";