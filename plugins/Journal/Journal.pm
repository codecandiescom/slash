# This code is a part of Slash, and is released under the GPL.
# Copyright 1997-2001 by Open Source Development Network. See README
# and COPYING for more information, or see http://slashcode.com/.
# $Id$

package Slash::Journal;

use strict;
use DBIx::Password;
use Slash;
use Slash::Utility;
use Slash::DB::Utility;

use vars qw($VERSION @EXPORT);
use base 'Exporter';
use base 'Slash::DB::Utility';
use base 'Slash::DB::MySQL';

($VERSION) = ' $Revision$ ' =~ /\$Revision:\s+([^\s]+)/;

@EXPORT = qw(
	MSG_CODE_JOURNAL_FRIEND
);

use constant MSG_CODE_JOURNAL_FRIEND => 5;

# On a side note, I am not sure if I liked the way I named the methods either.
# -Brian
sub new {
	my($class, $user) = @_;
	my $self = {};
	bless($self, $class);
	$self->{virtual_user} = $user;
	$self->sqlConnect;

	return $self;
}

sub set {
	my($self, $id, $values) = @_;
	my $uid = $ENV{SLASH_USER};

	return unless $self->sqlSelect('id', 'journals', "uid=$uid AND id=$id");

	my(%j1, %j2);
	%j1 = %$values;
	$j2{article}  = delete $j1{article};

	$self->sqlUpdate('journals', \%j1, "id=$id") if keys %j1;
	$self->sqlUpdate('journals_text', \%j2, "id=$id") if $j2{article};
}

sub getsByUid {
	my($self, $uid, $start, $limit, $id) = @_;
	my $order = "ORDER BY date DESC";
	$order .= " LIMIT $start, $limit" if $limit;
	my $where = "uid = $uid AND journals.id = journals_text.id";
	$where .= " AND journals.id = $id" if $id;

	my $answer = $self->sqlSelectAll(
		'date, article, description, journals.id, posttype, tid, discussion',
		'journals, journals_text', $where, $order
	);
	return $answer;
}

sub list {
	my($self, $uid, $limit) = @_;

	my $order = "ORDER BY date DESC";
	$order .= " LIMIT $limit" if $limit;
	my $answer = $self->sqlSelectAll('id, date, description', 'journals', "uid = $uid", $order);

	return $answer;
}

sub create {
	my($self, $description, $article, $posttype, $tid) = @_;

	return unless $description;
	return unless $article;
	return unless $tid;

	my $uid = $ENV{SLASH_USER};
	$self->sqlInsert("journals", {
		uid		=> $uid,
		description	=> $description,
		tid		=> $tid,
		-date		=> 'now()',
		posttype	=> $posttype,
	});

	my($id) = $self->getLastInsertId('journals', 'id');
	return unless $id;

	$self->sqlInsert("journals_text", {
		id		=> $id,
		article 	=> $article,
	});

	my($date) = $self->sqlSelect('date', 'journals', "id=$id");
	$self->setUser($uid, { journal_last_entry_date	=> $date });

	return $id;
}

sub remove {
	my($self, $id) = @_;
	my $uid = $ENV{SLASH_USER};
	$self->sqlDo("DELETE FROM journals WHERE uid=$uid AND id=$id");
}

sub friends {
	my($self) = @_;
	my $uid = $ENV{SLASH_USER};

# old style that ALMOST worked ...
# 	my $friends = $self->sqlSelectAll(
# 		'u.nickname, j.friend, MAX(jo.date) as date, jo.description',
# 		'journals as jo, journal_friends as j,users as u',
# 		"j.uid = $uid AND j.friend = u.uid AND j.friend = jo.uid",
# 		'GROUP BY u.nickname ORDER BY date DESC'
# 	);

	my($friends, $journals, $ids, %data);
	$friends = $self->sqlSelectAll(
		'u.nickname, j.friend, MAX(jo.id) as id',
		'journals as jo, journal_friends as j, users as u',
		"j.uid = $uid AND j.friend = u.uid AND j.friend = jo.uid",
		'GROUP BY u.nickname'
	);
	return [] unless @$friends;

	for my $friend (@$friends) {
		$ids .= "id = $friend->[2] OR ";
		$data{$friend->[2]} = [ @$friend[0, 1] ];
	}
	$ids =~ s/ OR $//;

	$journals = $self->sqlSelectAll(
		'date, description, id', 'journals', $ids
	);

	for my $journal (@$journals) {
		# tack on the extra data
		@{$data{$journal->[2]}}[2 .. 4] = @{$journal}[0 .. 2];
	}

	# pull it all back together
	return [ map { $data{$_} } sort { $b <=> $a } keys %data ];
}

sub message_friends {
	my($self) = @_;
	my $code  = MSG_CODE_JOURNAL_FRIEND;
	my $uid   = $ENV{SLASH_USER};
	my $cols  = "jf.uid";
	my $table = "journal_friends AS jf, users_param AS up1, users_param AS up2";
	my $where = "jf.friend=$uid
		AND  jf.uid=up1.uid AND jf.uid=up2.uid
		AND  up1.name = 'deliverymodes'      AND up1.value >= 0
		AND  up2.name = 'messagecodes_$code' AND up2.value  = 1";

	my $friends  = $self->sqlSelectArrayRef($cols, $table, $where);
	return $friends;
}

sub add {
	my($self, $friend) = @_;
	my $uid = $ENV{SLASH_USER};
	$self->sqlDo("INSERT INTO journal_friends (uid,friend) VALUES ($uid, $friend)");
}

sub delete {
	my($self, $friend) = @_;
	my $uid = $ENV{SLASH_USER};
	$self->sqlDo("DELETE FROM  journal_friends WHERE uid=$uid AND friend=$friend");
}

sub top {
	my($self, $limit) = @_;
	$limit ||= getCurrentStatic('journal_top') || 10;
	my $sql;
	$sql .= "SELECT count(j.uid) as c, u.nickname, j.uid, max(date)";
	$sql .= " FROM journals as j,users as u WHERE ";
	$sql .= " j.uid = u.uid";
	$sql .= " GROUP BY u.nickname ORDER BY c DESC";
	$sql .= " LIMIT $limit";
	$self->sqlConnect;
	my $losers = $self->{_dbh}->selectall_arrayref($sql);

	return $losers;
}

sub topFriends {
	my($self, $limit) = @_;
	$limit ||= getCurrentStatic('journal_top') || 10;
	my $sql;
	$sql .= " SELECT count(friend) as c, nickname, friend ";
	$sql .= " FROM journal_friends, users ";
	$sql .= " WHERE friend=users.uid ";
	$sql .= " GROUP BY nickname ";
	$sql .= " ORDER BY c DESC ";
	$self->sqlConnect;
	my $losers = $self->{_dbh}->selectall_arrayref($sql);
	$sql = "SELECT max(date) FROM journals WHERE uid=";
	for (@$losers) {
		my $date = $self->{_dbh}->selectrow_array($sql . $_->[2]);
		push @$_, $date;
	}

	return $losers;
}

sub topRecent {
	my($self, $limit) = @_;
	$limit ||= getCurrentStatic('journal_top') || 10;
	my $sql;
	$sql .= " SELECT count(jo.id), u.nickname, u.uid, MAX(jo.date) as date ";
	$sql .= " FROM journals as jo ,users as u ";
	$sql .= " WHERE jo.uid=u.uid ";
	$sql .= " GROUP BY u.nickname ";
	$sql .= " ORDER BY date DESC ";
	$sql .= " LIMIT $limit";
	$self->sqlConnect;
	my $losers = $self->{_dbh}->selectall_arrayref($sql);

	return $losers;
}

sub themes {
	my($self) = @_;
	my $uid = $ENV{SLASH_USER};
	my $sql;
	$sql .= "SELECT name from journal_themes";
	$self->sqlConnect;
	my $themes = $self->{_dbh}->selectcol_arrayref($sql);

	return $themes;
}

sub searchUsers {
	my($self, $nickname) = @_;
	my($data, @users);

	if (my $uid = $self->getUserUID($nickname)) {
		$data = [[ '', '', $uid ]];
	}

	if (!$data) {
		my $search = getObject("Slash::Search");
		$data  = $search->findUsers(
			{query => $nickname}, 0,
			getCurrentStatic('search_default_display') + 1
		);
	}

	for my $user (sort { lc $a->[1] cmp lc $b->[1] } @$data) {
		my $id = $self->sqlSelectArrayRef(
			'nickname, users.uid, date, description, id', 'journals, users',
			"users.uid=$user->[2] AND journals.uid=users.uid",
			'ORDER BY date DESC LIMIT 1'
		);
		push @users, $id if $id;
	}

	return \@users;
}

sub get {
	my($self, $id, $val) = @_;
	my $answer;

	if ((ref($val) eq 'ARRAY')) {
		# the grep was failing before, is this right?
		my @articles = grep /^comment$/, @$val;
		my @other = grep !/^comment$/, @$val;
		if (@other) {
			my $values = join ',', @other;
			$answer = $self->sqlSelectHashref($values, 'journals', "id=$id");
		}
		if (@articles) {
			$answer->{comment} = $self->sqlSelect('article', 'journals', "id=$id");
		}
	} elsif ($val) {
		if ($val eq 'article') {
			($answer) = $self->sqlSelect('article', 'journals', "id=$id");
		} else {
			($answer) = $self->sqlSelect($val, 'journals', "id=$id");
		}
	} else {
		$answer = $self->sqlSelectHashref('*', 'journals', "id=$id");
		($answer->{article}) = $self->sqlSelect('article', 'journals_text', "id=$id");
	}

	return $answer;
}

sub DESTROY {
	my($self) = @_;
	$self->{_dbh}->disconnect unless ($ENV{GATEWAY_INTERFACE});
}


1;

__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Slash::Journal - Journal system splace

=head1 SYNOPSIS

	use Slash::Journal;

=head1 DESCRIPTION

This is a port of Tangent's journal system.

Blah blah blah.

=head1 AUTHOR

Brian Aker, brian@tangent.org

=head1 SEE ALSO

perl(1).

=cut
