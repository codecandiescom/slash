# This code is a part of Slash, and is released under the GPL.
# Copyright 1997-2005 by Open Source Technology Group. See README
# and COPYING for more information, or see http://slashcode.com/.
# $Id$

package Slash::Journal;

use strict;
use DBIx::Password;
use Slash;
use Slash::Constants qw(:messages);
use Slash::Utility;

use vars qw($VERSION);
use base 'Exporter';
use base 'Slash::DB::Utility';
use base 'Slash::DB::MySQL';

($VERSION) = ' $Revision$ ' =~ /\$Revision:\s+([^\s]+)/;

# On a side note, I am not sure if I liked the way I named the methods either.
# -Brian
sub new {
	my($class, $user) = @_;
	my $self = {};

	my $plugin = getCurrentStatic('plugin');
	return unless $plugin->{'Journal'};

	bless($self, $class);
	$self->{virtual_user} = $user;
	$self->sqlConnect;

	return $self;
}

sub set {
	my($self, $id, $values) = @_;
	my $uid = $ENV{SLASH_USER};
	my $constants = getCurrentStatic();

	return unless $self->sqlSelect('id', 'journals', "uid=$uid AND id=$id");

	my(%j1, %j2);
	%j1 = %$values;

	# verify we're allowed to do this at some point, ie can't unset if it's already set
	if (defined $j1{submit} && $constants->{journal_allow_journal2submit} ) {
		my $cur_submit = $self->get($id, "submit");
		unless ($cur_submit eq "yes") {
			my $submit = "yes";
			$submit = "no" if $j1{submit} eq "no" || !$j1{submit};
			$j1{submit} = $submit;
		}
	}

	$j2{article}  = delete $j1{article};
	$j1{"-last_update"} = 'now()';

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
		'journals, journals_text',
		$where,
		$order
	);
	return $answer;
}

sub getsByUids {
	my($self, $uids, $start, $limit, $options) = @_;
	return unless @$uids;
	my $t_o = $options->{titles_only};
	my $uids_list = join(",", @$uids);
	my $order = "ORDER BY journals.date DESC";
	my $order_limit = $order;
	$order_limit .= " LIMIT $start, $limit" if $limit;

	# The list may be quite large, potentially hundreds or even
	# thousands of users, forming a significant portion of all the
	# journal-writing users on a site.  We're splitting this select
	# up into three separate ones.  The uid_date_id index lets this
	# first select succeed without even hitting the data (and yes
	# the ",id" component of that index is required for this to be
	# true, at least on the version of MySQL and the data set I
	# tested it on for Slashdot).

	# First, get the list of journal IDs for the UIDs given.
	my $journals_hr = $self->sqlSelectAllKeyValue(
		'id, uid',
		'journals',
		"uid IN ($uids_list)",
		$order_limit);
	return unless $journals_hr && %$journals_hr;

	# Second, pull nickname from users for the uids identified.
	my @uids_found = sort keys %{ { map { ($_, 1) } values %$journals_hr } };
	my $uids_found_list = join(',', @uids_found);
	my $uid_nick_hr = $self->sqlSelectAllKeyValue(
		'uid, nickname',
		'users',
		"uid IN ($uids_found_list)");

	# Third, pull the required data from journals, and if necessary
	# journals_text.  If in the last few moments any journals from
	# the first select have become unavailable, that's OK, we just
	# won't return any information about them.
	# Oh, and yes, it is _insane_ that this method returns an
	# arrayref of nine-element arrayrefs normally, but an arrayref
	# of hashrefs if called with the "titles_only" option.
	# That should be fixed someday.
	my @journal_ids_found = sort keys %$journals_hr;
	my $journal_ids_found_list = join(',', @journal_ids_found);
	my $columns =	$t_o	? 'id, description'
				: 'date, article, description, journals.id,
				   posttype, tid, discussion, journals.uid';
	my $tables =	$t_o	? 'journals'
				: 'journals, journals_text';
	my $where =	$t_o	? "journals.id IN ($journal_ids_found_list)"
				: "journals.id IN ($journal_ids_found_list)
				   AND journals_text.id = journals.id";
	my $retval;
	if ($t_o) {
		$retval = $self->sqlSelectAllHashrefArray(
			$columns, $tables, $where, $order);
		for my $hr (@$retval) {
			my $id = $hr->{id};
			my $uid = $journals_hr->{$id};
			$hr->{nickname} = $uid_nick_hr->{$uid};
		}
	} else {
		$retval = $self->sqlSelectAll(
			$columns, $tables, $where, $order);
		for my $ar (@$retval) {
			my $uid = $ar->[7];
			push @$ar, $uid_nick_hr->{$uid};
		}
	}
	return $retval;
}

sub list {
	my($self, $uid, $limit) = @_;
	$uid ||= 0;	# no SQL syntax error
	my $order = "ORDER BY date DESC";
	$order .= " LIMIT $limit" if $limit;
	my $answer = $self->sqlSelectAll('id, date, description', 'journals', "uid = $uid", $order);

	return $answer;
}

sub listFriends {
	my($self, $uids, $limit) = @_;
	my $list = join(",", @$uids);
	my $order = "ORDER BY date DESC";
	$order .= " LIMIT $limit" if $limit;
	my $answer = $self->sqlSelectAll('id, journals.date, description, journals.uid, users.nickname',
		'journals,users',
		"journals.uid in ($list) AND users.uid=journals.uid", $order);

	return $answer;
}

sub create {
	my($self, $description, $article, $posttype, $tid, $submit) = @_;

	return unless $description;
	return unless $article;
	return unless $tid;

	$submit = $submit ? "yes" : "no";

	my $uid = $ENV{SLASH_USER};
	$self->sqlInsert("journals", {
		uid		=> $uid,
		description	=> $description,
		tid		=> $tid,
		-date		=> 'now()',
		posttype	=> $posttype,
		submit		=> $submit,
	});

	my($id) = $self->getLastInsertId({ table => 'journals', prime => 'id' });
	return unless $id;

	$self->sqlInsert("journals_text", {
		id		=> $id,
		article 	=> $article,
	});

	my($date) = $self->sqlSelect('date', 'journals', "id=$id");
	my $slashdb = getCurrentDB();
	$slashdb->setUser($uid, { journal_last_entry_date => $date });

	return $id;
}

sub remove {
	my($self, $id) = @_;
	my $uid = $ENV{SLASH_USER};

	my $journal = $self->get($id);
	return unless $journal->{uid} == $uid;

	my $count = $self->sqlDelete("journals", "uid=$uid AND id=$id");
	if ($count == 0) {
		# Return value 0E0 means "no rows deleted" (i.e. this user owns
		# no such journal) and undef means "error."  Either way, abort.
		return;
	}
	$self->sqlDelete("journals_text", "id=$id");

	if ($journal->{discussion}) {
		my $slashdb = getCurrentDB();
		$slashdb->deleteDiscussion($journal->{discussion});
	}

	my $date = $self->sqlSelect('MAX(date)', 'journals', "uid=$uid");
	if ($date) {
		$date = $self->sqlQuote($date);
	} else {
		$date = "NULL";
	}
	my $slashdb = getCurrentDB();
	$slashdb->setUser($uid, { -journal_last_entry_date => $date });
	return $count;
}

sub top {
	my($self, $limit) = @_;
	$limit ||= getCurrentStatic('journal_top') || 10;
	$self->sqlConnect;

	my $sql = <<EOT;
SELECT count(j.uid) AS c, u.nickname, j.uid, MAX(date), MAX(id)
FROM journals AS j, users AS u
WHERE j.uid = u.uid
GROUP BY u.nickname ORDER BY c DESC
LIMIT $limit
EOT

	my $losers = $self->{_dbh}->selectall_arrayref($sql);

	my $sql2 = sprintf <<EOT, join (',', map { $_->[4] } @$losers);
SELECT id, description
FROM journals
WHERE id IN (%s)
EOT
	my $losers2 = $self->{_dbh}->selectall_hashref($sql2, 'id');

	for (@$losers) {
		$_->[5] = $losers2->{$_->[4]}{description};
	}

	return $losers;
}

sub topRecent {
	my($self, $limit) = @_;
	$limit ||= getCurrentStatic('journal_top') || 10;
	$self->sqlConnect;

	my $sql = <<EOT;
SELECT count(j.id), u.nickname, u.uid, MAX(j.date) AS date, MAX(id)
FROM journals AS j, users AS u
WHERE j.uid = u.uid
GROUP BY u.nickname
ORDER BY date DESC
LIMIT $limit
EOT

	my $losers = $self->{_dbh}->selectall_arrayref($sql);
	return [ ] if !$losers || !@$losers;

	my $id_list = join(", ", map { $_->[4] } @$losers);
	my $loserid_hr = $self->sqlSelectAllHashref(
		"id",
		"id, description",
		"journals",
		"id IN ($id_list)");

	for my $loser (@$losers) {
		$loser->[5] = $loserid_hr->{$loser->[4]}{description};
	}

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
	my $slashdb = getCurrentDB();
	my $constants = getCurrentStatic();

	if (my $uid = $slashdb->getUserUID($nickname)) {
		if ($self->sqlSelect('uid', 'journals', "uid=$uid")) {
			return $uid;
		} else {
			return $slashdb->getUser($uid);
		}
	}

	my($search, $find, $uids, $jusers, $ids, $journals, @users);
	# This is only important if it exists, aka calling the search db user -Brian
	$search	= getObject("Slash::Search", $constants->{search_db_user}) or return;
	$find	= $search->findUsers(
		{query => $nickname}, 0,
		getCurrentStatic('search_default_display') + 1
	);
	return unless @$find;

	$uids   = join(" OR ", map { "uid=$_->{uid}" } @$find);
	$jusers = $self->sqlSelectAllHashref(
		'uid', 'uid, MAX(id) as id', 'journals', $uids, 'GROUP BY uid'
	);

	$ids      = join(" OR ", map { "id=$_->{id}" } values %$jusers);
	$journals = $self->sqlSelectAllHashref(
		'uid', 'uid, id, date, description', 'journals', $ids
	);

	for my $user (sort { lc $a->{nickname} cmp lc $b->{nickname} } @$find) {
		my $uid  = $user->{uid};
		my $nick = $user->{nickname};
		if (exists $journals->{$uid}) {
			push @users, [
				$nick, $uid, $journals->{$uid}{date},
				$journals->{$uid}{description},
				$journals->{$uid}{id},
			];
		} else {
			push @users, [$nick, $uid];
		}
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

sub updateStoryFromJournal {
	my($self, $src_journal) = @_;
	my $slashdb = getCurrentDB();

	my $stoid = $slashdb->sqlSelect("stoid", "journal_transfer", "id=$src_journal->{id}");
	return unless $stoid;

	my $data = {};
	$data->{title} = $src_journal->{description};
	my $text = balanceTags(strip_mode($src_journal->{article}, $src_journal->{posttype}));
	($data->{introtext}, $data->{bodytext}) = $self->splitJournalTextForStory($text);

	$slashdb->updateStory($stoid, $data);
}

sub createSubmissionFromJournal {
	my($self, $src_journal) = @_;
	my $slashdb   = getCurrentDB();
	my $constants = getCurrentStatic();

	my $journal_user = $slashdb->getUser($src_journal->{uid});

	my $story = $src_journal->{article};
	
	$story =~ s/^$Slash::Utility::Data::WS_RE+//io;
	$story =~ s/$Slash::Utility::Data::WS_RE+$//io;
	
	$story = balanceTags(strip_mode($story, $src_journal->{posttype}));
	#perhaps need more string cleanup from submit.pl's findStory here

	my $primaryskid = $constants->{journal2submit_skid} || $constants->{mainpage_skid};

	my $submission = {
		email		=> $journal_user->{fakeemail},
		uid		=> $journal_user->{uid},
		name		=> $journal_user->{nickname},
		story		=> $story,
		subj		=> $src_journal->{description},
		tid		=> $src_journal->{tid},
		primaryskid 	=> $primaryskid,
		journal_id 	=> $src_journal->{id},
		journal_disc 	=> $src_journal->{discussion},
		by		=> $journal_user->{nickname},
		by_url 		=> $journal_user->{fakeemail},
	};

	my $subid = $slashdb->createSubmission($submission);
	if ($subid) {
		$self->logJournalTransfer($src_journal->{id}, $subid);
	} else {
		print STDERR ("Failed attempting to transfer journal id: $src_journal->{id}\n");
	}
	return $subid;
}

sub createStoryFromJournal { 
	my($self, $src_journal, $options) = @_;
	$options ||= {};

	my $slashdb = getCurrentDB();
	my $constants = getCurrentStatic();

	my $journal_user = $slashdb->getUser($src_journal->{uid});

	my $text = balanceTags(strip_mode($src_journal->{article}, $src_journal->{posttype}));
	my ($intro, $body) = $self->splitJournalTextForStory($text);
	
	my $skid = $options->{skid} || $constants->{journal2submit_skid} || $constants->{mainpage_skid};

	my %story = (
		title		=> $src_journal->{description},
		uid		=> $journal_user->{uid},
		introtext	=> $intro,
		bodytext	=> $body,
		'time'		=> $slashdb->getTime(), 
		commentstatus	=> 'enabled',  # ?
	#	discussion_id	=> $src_journal->{discussion}, # journal's discussion ID
		journal_id 	=> $src_journal->{id},
		journal_disc	=> $src_journal->{discussion},
		by		=> $journal_user->{nickname},
		by_url 		=> $journal_user->{fakeemail},
		discussion	=> $src_journal->{discussion},
	);

	$story{neverdisplay} = $options->{neverdisplay} if $options->{neverdisplay};
													       
													       
	# XXX: we need to update, in the discussion:
	# stoid, sid, title, url, topic, ts (story's timestamp), type (open), uid?,
	# flags (ok), primaryskid, commentstatus (enabled), archivable?
	# this sets weight (front page, etc.) ... not sure which weight to use;
	# 20/10 is for section-only, 40/30 is for mainpage


	my $skin = $slashdb->getSkin($skid);
	my $skin_nexus = $skin->{nexus};
 	
	# May need to change
	$story{topics_chosen} = { $src_journal->{tid} => 10, $skin_nexus => 20 };
 
 	
	my $topiclist = $slashdb->getTopiclistFromChosen(
 		$story{topics_chosen}
	);

	my $admindb = getObject('Slash::Admin');
 	$story{relatedtext} = $admindb->relatedLinks(
		"$story{title} $story{introtext} $story{bodytext}",
 	       $topiclist,
 	       '', # user's nickname
 	       '', # user's uid
        );

	my $sid = $slashdb->createStory(\%story);
	my $stoid = $slashdb->getStoidFromSidOrStoid($sid);
	$self->logJournalTransfer($src_journal->{id}, 0, $stoid);
}

sub splitJournalTextForStory {
	my ($self, $text) = @_;
	my ($intro, $body) = split (/<br>|<\/p>/i, $text, 2);

	$intro =~ s/^$Slash::Utility::Data::WS_RE+//io;
	$intro =~ s/$Slash::Utility::Data::WS_RE+$//io;
	
	$body =~ s/^$Slash::Utility::Data::WS_RE+//io;
	$body =~ s/$Slash::Utility::Data::WS_RE+$//io;

	$intro = balanceTags($intro);
	$body = balanceTags($body);
	return ($intro, $body);
}

sub logJournalTransfer {
	my($self, $id, $subid, $stoid) = @_;
	my $slashdb = getCurrentDB();
	$stoid ||=0;
	$subid ||=0;
	return if !$id;

	$slashdb->sqlInsert("journal_transfer", { id => $id, subid => $subid, stoid => $stoid });
}

sub hasJournalTransferred {
	my($self, $id) = @_;
	return $self->sqlCount("journal_transfer", "id=$id")
}

sub promoteJournal {
	my($data) = @_;
	my $constants = getCurrentStatic();
	my $user      = getCurrentUser();
	my $journal = getObject('Slash::Journal'); 

	return unless $constants->{journal_allow_journal2submit};
	return unless $data && $data->{id};
	my $src_journal = $journal->get($data->{id});
	if ($src_journal->{submit} eq "yes") {
		my $transferred = $journal->hasJournalTransferred($data->{id});
		if ($user->{acl}{journal_to_story}) {
			unless ($transferred) {
				$journal->createStoryFromJournal($src_journal, { neverdisplay => 1} );
			} else {
				$journal->updateStoryFromJournal($src_journal);	
			}
		} else {
			unless ($transferred) {
				$journal->createSubmissionFromJournal($src_journal);
			} else {
				# Apply edit?
			}
		}
	}
}


sub DESTROY {
	my($self) = @_;
	$self->{_dbh}->disconnect if !$ENV{GATEWAY_INTERFACE} && $self->{_dbh};
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
