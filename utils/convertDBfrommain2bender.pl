#!/usr/bin/perl -w
use strict;
use DBIx::Password;

usage() unless $ARGV[0];
my $dbh = DBIx::Password->connect($ARGV[0]);

my $users_param = qq|
CREATE TABLE users_param (
	param_id int(11) NOT NULL auto_increment,
	uid int(11) DEFAULT '1' NOT NULL,
	name varchar(32) DEFAULT '' NOT NULL,
	value text,
	UNIQUE uid_key (uid,name),
	PRIMARY KEY (param_id)
)
|;

$dbh->do('ALTER TABLE stories add uid int(11)');
$dbh->do('ALTER TABLE newstories add uid int(11)');
$dbh->do($users_param);
$dbh->do('DELETE FROM users WHERE UID < 1');
my %story_authors;

my $authors = $dbh->selectall_arrayref("SELECT aid,seclev,lasttitle,section,deletedsubmissions from authors WHERE name != 'All Authors'");
for(@$authors) {
	my $uid;
	if($uid = $dbh->selectrow_array("SELECT BINARY uid from users WHERE nickname='$_->[0]'")) {
		print "Found $uid for $_->[0]\n";
		$story_authors{$_->[0]} = $uid; 
		$dbh->do("UPDATE users SET seclev='$_->[1]' WHERE uid=$uid");
		$dbh->do("INSERT INTO users_param (uid,name,value) VALUES ($uid, 'author', '1')");
		$dbh->do("INSERT INTO users_param (uid,name,value) VALUES ($uid, 'lasttitle', '$_->[2]')") if $_->[2];
		$dbh->do("INSERT INTO users_param (uid,name,value) VALUES ($uid, 'section', '$_->[3]')") if $_->[3];
		$dbh->do("INSERT INTO users_param (uid,name,value) VALUES ($uid, 'deletedsubmissions', '$_->[4]')") if $_->[4];
	}
}

my $users = $dbh->selectall_arrayref("SELECT uid,pubkey from users_key");
for(@$users) {
	my $string = $dbh->quote($_->[1]);
	$dbh->do("INSERT INTO users_param (uid,name,value) VALUES ($_->[0], 'pubkey', $string)");
}

for my $author (keys %story_authors) {
	print "Doing $author stories \n";
	my $sids = $dbh->selectcol_arrayref("SELECT sid FROM stories WHERE aid='$author'");
	for my $sid (@$sids) {
		$dbh->do("UPDATE stories SET uid=$story_authors{$author} WHERE sid='$sid'");	
	}
}
for my $author (keys %story_authors) {
	print "Doing $author newstories \n";
	my $sids = $dbh->selectcol_arrayref("SELECT sid FROM newstories WHERE aid='$author'");
	for my $sid (@$sids) {
		$dbh->do("UPDATE newstories SET uid=$story_authors{$author} WHERE sid='$sid'");	
	}
}
$dbh->do('UPDATE users_prefs SET tzcode=UCASE(tzcode)');

# This is what pudge will probably want to change :) 		-Brian
$dbh->do('ALTER TABLE users change passwd passwd varchar(32)');
$dbh->do('UPDATE users SET passwd=MD5(passwd)');
$dbh->do('CREATE TABLE newcomments SELECT * from comments');

#cleanup time
$dbh->do('ALTER TABLE stories drop aid');
$dbh->do('ALTER TABLE newstories drop aid');
#Tables to just drop
my @tables = qw |
	authors         
	blocks          
	commentcodes    
	commentkey      
	commentmodes    
	dateformats     
	displaycodes    
	isolatemodes    
	issuemodes      
	maillist        
	postmodes
	sectionblocks   
	sessions        
	sortcodes       
	statuscodes     
	threshcodes     
	tzcodes         
	users_key
	vars
|;

for(@tables) {
	$dbh->do("DROP TABLE $_");
}

$dbh->disconnect;

sub usage {
	print "Usage:convert <DBIx:Password Virtual User>\n";
	print "\n\tIf no virtual user is given the coverter will not run\n\n";
	exit();
}

=head1 NAME

convert.pl - Convert from 1.0.9 to 2.0 data

=head1 What does this do?

This converts the data from your slash sites
to format you can then use to populate a new
slash site.

=head1 What does this not do?

If you have customized your perl scripts this
will not help you. This does not save look and
feel from blocks. This basically handles stories
and users (which are the two large schema changes).

=head1 Ok, how should I use this.

This is what I would suggest:

First, make sure that your author accounts and
user accounts match. AKA for every aid you
have, you must have a username of the same.

Use mysqldump to make a copy of your data. Example:

mysqldump -u slash -p slash > datadump.sql

Now, use the database you are going to load your
slashsite in. This will save you the step of
setting up an additional virtual user.

Now, dump the data into the database. Example:

mysq -u -p slash < datadump.sql

Now, run the convert script with the proper
virtual user name.

Now, dump the data out. Example:

mysqldump -u slash -p slash --complete-insert --no-create-info > datadump

Now, install a slashsite and then dump this data into the site.

mysqldump -u slash -p slash < datadump


=head1 What am I likely to mess up?

Keep in mind that your install did create a user. You may
want to delete that user before dumping.

I would bet a fiver that someone does this on their live
database.

=head1 What is the warranty?

YMMV. There is none. Worked for me (I think).
Keep in mind that most people are accidents.

=cut
