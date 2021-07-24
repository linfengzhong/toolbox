#!/usr/local/bin/perl
#
# Author: Damian Myerscough
# Date: 25/08/2012
#
# Description: This script is used to check the network interface speed
# 	       on Linux and Solaris hosts
#

use strict;
use warnings;
use Getopt::Long;

my ($nicID, $nic, $speed, $networkSpeed, $host, $community, $version, @snmpwalk, $snmp_arg);

GetOptions(
	'H=s'	=> \$host,			'hostname'	=> \$host,
	'C=s'	=> \$community,	'community'	=> \$community,
	'n=s'	=> \$nic,			'nic'			=> \$nic,
	's=i'	=> \$speed,			'speed'		=> \$speed,
);

if (!defined($host) || !defined($nic) || !defined($speed))
{
	&usage;
}

if (defined($community))
{
	$snmp_arg = "-v2c -c $community";
}

sub usage
{
	print <<USAGE; 

Usage: $0 <-H hostname> <-n network card> <-s network speed Mb>

-H, --hostname=HOST
        name or IP address of host to check
-C, --community=COMMUNITY NAME
        community name for the host's SNMP agent
-n, --nic=NETWORK INTERFACE
	name of the network interface to check
-s, --speed=NETWORK SPEED
	network speed in Mb


USAGE

        exit 0;
}


my $OID_networkInterfaces = '.1.3.6.1.2.1.2.2.1.2';
my $OID_networkSpeed = '.1.3.6.1.2.1.2.2.1.5';

if(defined($snmp_arg))
{
	@snmpwalk = `snmpwalk -On $snmp_arg $host $OID_networkInterfaces`;
}
else
{
	@snmpwalk = `snmpwalk -On $host $OID_networkInterfaces`;
}

foreach my $line (@snmpwalk) 
{
	if ( $line =~ m/$OID_networkInterfaces\.([0-9]{1,10}) = STRING: (.*)/ ) 
	{
		if ( $2 eq $nic )
		{
			$nicID = $1;
		}
	}
}

if(!defined($nicID))
{
	print "Cannot identify the $nic network interface\n";
	exit 3;
}

if (defined($snmp_arg))
{
	$networkSpeed = `snmpget -On $snmp_arg $host .1.3.6.1.2.1.2.2.1.5.$nicID`;
}
else
{
	$networkSpeed = `snmpget -On $host .1.3.6.1.2.1.2.2.1.5.$nicID`;
}

if ( $networkSpeed =~ m/.1.3.6.1.2.1.2.2.1.5.$nicID = Gauge32: ([0-9]+)/ )
{
	$speed *= 1000000;

	if ( defined($speed) && defined($1) )
	{
		if ( $speed != $1 )
		{
			print "$nic speed is " . ($1 / 1000000) . " Mb and should be " . ($speed / 1000000) . " Mb\n";
			exit 2;
		}
		else
		{
			print "OK: $nic speed is " . ($speed / 1000000) . " Mb\n";
			exit 0;
		}
	}
	else
	{
		print "Unable to find $nic speed\n";
		exit 3;
	}
}
