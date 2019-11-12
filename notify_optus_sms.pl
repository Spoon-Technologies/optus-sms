#!/usr/bin/perl
#
# ============================== SUMMARY =====================================
#
# Program: notify_optus_sms.pl
# Version: 1.0
# Date: November 04, 2019
# Author: Adam Nye / Spoon Technologies
# Summary: This plugin sends SMS alerts with Optus RESTful API
# License: GPLv3
#
# ============================= SETUP ==========================================
#
# Copy this file to your Nagios plugin folder, then add command definitions as per below.
#
# Optus Setup
#
# Firstly, this is for the Optus REST API only. You could use the concepts below to
# create something to use with other APIs, but thats out of scope of this script :)
#
# Nagios setup
#
# 1. Create the SMS notification commands (commonly found in commands.cfg).
#    Replace APIURL with URL of Optus REST API (probably the same URL TBH).
#    Replace USER and PASS with your user/password to the API.
#
# Define two commands:
#
#       define command {
#               command_name notify-by-sms
#               command_line $USER1$/notify_optus_sms.pl -a 'APIURL' -u 'USER' -p 'PASS' -d '$CONTACTPAGER$' -m "$NOTIFICATIONTYPE$ $SERVICESTATE$ $SERVICEDESC$ Host($HOSTNAME$) Info($SERVICEOUTPUT$) Date($SHORTDATETIME$)"
#       }
#
#       define command {
#               command_name host-notify-by-sms
#               command_line $USER1$/notify_optus_sms.pl -a 'APIURL' -u 'USER' -p 'PASS' -d '$CONTACTPAGER$' -m "$NOTIFICATIONTYPE$ $HOSTSTATE$ Host($HOSTALIAS$) Info($HOSTOUTPUT$) Time($SHORTDATETIME$)"
#       }
#
#
# 2. In your nagios contacts (Commonly found on contacts.cfg) add
#     the contact. Field "pager" should contain a mobile number for sms alerts in
#       full international format e.g. +61xxxxxxxxx
#
#
#       define contact{
#               contact_name                    engineer
#               alias                           Support Engineer
#               service_notification_period     24x7
#               host_notification_period        24x7
#               service_notification_options    w,u,c,r
#               host_notification_options       d,u,r
#               service_notification_commands   notify-by-email,notify-by-sms
#               host_notification_commands      host-notify-by-email,host-notify-by-sms
#               email                           engineer@somedomain.com
#               pager                           +61xxxxxxxxx
#       }
#
#
# ============================= SCRIPT ==========================================
#
# Script params description:
#
# apiurl = URL of the Optus API gateway (https://api.sms.optus.com.au/rest/gateway/messages)
# user = API user
# password = API password
# dstnumber = Destination mobile number (the number to send SMS to)
# msg = The text message body

use strict;
use warnings;
use LWP::UserAgent;
use Getopt::Long;

# Variables
my $userAgent = LWP::UserAgent->new;
my $apiContentType = 'application/vnd.modica.gateway.v1+json';
my %args;

GetOptions(
    'help'        => \$args{help},
    'apiurl=s'    => \$args{apiURL},
    'user=s'      => \$args{apiUser},
    'password=s'  => \$args{apiPass},
    'dstnumber=s' => \$args{dstNumber},
    'msg=s'       => \$args{msgBody}
    )
or die("Error in command line arguments\n");

if(defined($args{help}) || !defined($args{apiURL}) || !defined($args{apiUser}) || !defined($args{apiPass}) || !defined($args{dstNumber}) || !defined($args{msgBody}) ) {
    print "usage: optus_sms.pl --apiurl <URL of API> --user <API username> --password <API password> --dstnumber <destination mobile number> --msg <message> \n";
    exit(0);
}

# Define our user agent
$userAgent->agent("pernixOptusSMS/0.1");

# Create the request
my $req = HTTP::Request->new(POST => $args{apiURL});
$req->content_type($apiContentType);
$req->authorization_basic($args{apiUser}, $args{apiPass});
$req->content('{"destination":"' . $args{dstNumber} . '","content":"' . $args{msgBody} . '"}');

# Pass request to the user agent and get a response back
my $res = $userAgent->request($req);

# Check the outcome of the response
if ($res->is_success) {
  print $res->content;
} else {
  print $res->status_line, "n";
}
