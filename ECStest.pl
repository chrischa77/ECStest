#!/usr/bin/perl
###############################################
# Perl Script to talk with  EMC ECS
# via REST GET-Calls...
# just add the  GET-call-details as parameter to this script
# eg: perl ECS_get_dev.pl /object/capacity
#
###############################################

use strict;
use warnings;

use Data::Dumper; # DEBUG
use MIME::Base64;

use Encode;     # UTF8 encoding
use URI::Escape;

#########
# Force Net::HTTPS to use Net::SSL instead of IO::Socket::SSL
use Env;
$ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS}="Net::SSL";
#########
### alternatively, use this after use Net::HTTPS
###$Net::HTTPS::SSL_SOCKET_CLASS = "Net::SSL"; # Force use of Net::SSL
#########
use Net::SSL;
use Net::HTTPS;

use JSON;


my ($ip, $port, $user, $pwd, $cmd, $arg) = @ARGV;

#chomp $type;
chomp $cmd ;
chomp $arg if (defined $arg);
my $conn;

my $xsdsauthtoken;
my $rc;
my $headers ={};
my $uri;
my $rcode;
my $msg;
my %rheaders;
my $responsebody_jason;
my $buf;

my $auth;


# START of programm


# new connection....define connection with the ECS
$conn = Net::HTTPS->new(Host => "$ip:$port") || die $@;
$auth = encode_base64("chris:Passw0rd");

    $headers->{'Authorization'}="Basic $auth";
    $headers->{'Accept'}='application/json';
    $headers->{'Content-Type'}='application/json';
    $headers->{'Connection'}='close';
    

# LOGIN to ECS
  ($rc, $xsdsauthtoken)=ECSlogin($conn, $auth, $headers);

# save received token, we use it for re-authentication in next call
if ($rc == 0){
  print "Running GET $cmd\n";
  #$headers={};
  $headers->{'X-SDS-AUTH-TOKEN'}=$xsdsauthtoken;
#  undef $headers->{'Authorization'};

# Run user specified Comand
  $conn = Net::HTTPS->new(Host => "$ip:$port") || die $@;
  $uri="https://$ip:$port" . $cmd;
  #print $conn->format_request(GET => $uri, %$headers); # DEBUG
  $conn->write_request(GET => $uri, %$headers);

  ($rcode, $msg, %rheaders) = $conn->read_response_headers;

  #print "\n$rcode - $msg\n";
  #foreach (keys %rheaders){
  #  print "key $_ value " . $rheaders{$_} . "\n";
  #}

  if ($rcode == 200) {
      # print "RESTAPI command successful.\n";
  } else {
      die("RESTAPI command failed with RCode $rcode.\n");
  }


  #$buf;
  #$responsebody_jason;
  # Reading Response Body
  while ( $conn->read_entity_body($buf,1024) ) {
      chomp $buf ;
      $responsebody_jason .= $buf;
  }

  #print $responsebody_jason;
  
  # Convert JSON Response to PERL
    my $json_object = new JSON;
    my $responsebody = $json_object->decode($responsebody_jason);
    #print Dumper $responsebody;

    print "\nAnswer is:\n";
    foreach (keys %$responsebody){
    
        print "key $_\n";
        print Dumper $responsebody->{$_};

    }
    
}



    


sub ECSlogin {
    my ( $conn, $auth, $headers ) = @_ ;	# pick parameters
    my $rc=-1;
    my $uri;
    my $buf;
    my $responsebody_jason;
    my $token;

    $uri="https://$ip:$port/login";
    #print $conn->format_request(GET => $uri, %$headers); # DEBUG
    $conn->write_request(GET => $uri, %$headers);

    my ($rcode, $msg, %rheaders) = $conn->read_response_headers;
    #print "\n$rcode - $msg\n";

    if ($rcode == 200) {
        #print "RESTAPI command successful.\n";


        # find and save login-Token
        if (defined $rheaders{'X-SDS-AUTH-TOKEN'} && $rheaders{'X-SDS-AUTH-TOKEN'} ne ""){
          $token=$rheaders{'X-SDS-AUTH-TOKEN'};
          #chomp($token);
          #print "authentication token is $token\n\n";
          $rc=0;
        } else {
          print "No authentication token received.\n";
          $rc=1;
        }
    } else {
        print "RESTAPI command failed with RCode $rcode.\n";
        $rc=1;
    }

    # Reading Response Body
    while ( $conn->read_entity_body($buf,1024) ) {
        chomp $buf ;
        $responsebody_jason .= $buf;
    }
    #print "Login-End: RC $rc\n\n";
    return($rc, $token);
}
