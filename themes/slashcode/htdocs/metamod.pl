#!/usr/bin/perl -w

###############################################################################
# metamod.pl - this code displays the page where users meta-moderate 
#
# Copyright (C) 1997 Rob "CmdrTaco" Malda
# malda@slashdot.org
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#
#  $Id$
###############################################################################
use strict;
use Slash;
use Slash::Display;
use Slash::Utility;

#################################################################
sub main {
	my $form = getCurrentForm();
	my $user = getCurrentUser();
	my $op = getCurrentForm('op');
	my $constants = getCurrentStatic();
	my $dbslash = getCurrentDB();

	header("Meta Moderation");

	my $id = isEligible($user, $dbslash, $constants);
	if (!$id) {
		slashDisplay('not-eligible');

	} elsif ($op eq "MetaModerate") {
		metaModerate($id, $form, $user, $dbslash, $constants);
	} else {
		displayTheComments($id, $user, $dbslash, $constants);
	}

	writeLog("metamod", $op);
	footer();
}

#################################################################
sub karmaBonus {
	my ($user, $constants) = @_;

	my $x = $constants->{m2_maxbonus} - $user->{karma};

	return 0 unless $x > 0;
	return 1 if rand($constants->{m2_maxbonus}) < $x;
	return 0;
}

#################################################################
sub metaModerate {
	my ($id, $form, $user, $dbslash, $constants) = @_;

	my $y = 0;								# Sum of elements from form.
	my (%metamod, @mmids);

	$metamod{unfair} = $metamod{fair} = 0;
	foreach (keys %{$form}) {
		# Meta mod form data can only be a '+' or a '-' so we apply some
		# protection from taint.
		next if $form->{$_} !~ /^[+-]$/; # bad input, bad!
		if (/^mm(\d+)$/) {
			push(@mmids, $1) if $form->{$_};
			$metamod{unfair}++ if $form->{$_} eq '-';
			$metamod{fair}++ if $form->{$_} eq '+';
		}
	}

	my %m2victims;
	foreach (@mmids) {
		if ($y < $constants->{m2_comments}) { 
			$y++;
			my $muid = $dbslash->getModeratorLog($_, 'uid');

			$m2victims{$_} = [$muid, $form->{"mm$_"}];
		}
	}

	# Perform M2 validity checks and set $flag accordingly. M2 is only recorded
	# if $flag is 0. Immediate and long term checks for M2 validity go here
	# (or in moderatord?).
	#
	# Also, it was probably unnecessary, but I want it to be understood that
	# an M2 session can be retrieved by:
	#		SELECT * from metamodlog WHERE uid=x and ts=y 
	# for a given x and y.
	my($flag, $ts) = (0, time);
	if ($y >= $constants->{m2_mincheck}) {
		# Test for excessive number of unfair votes (by percentage)
		# (Ignore M2 & penalize user)
		$flag = 2 if ($metamod{unfair}/$y >= $constants->{m2_maxunfair});
		# Test for questionable number of unfair votes (by percentage)
		# (Ignore M2).
		$flag = 1 if (!$flag && ($metamod{unfair}/$y >= $constants->{m2_toomanyunfair}));
	}

	my $changes = $dbslash->setMetaMod(\%m2victims, $flag, $ts);

	slashDisplay('results', {
		changes => $changes,
		count	=> $y,
		metamod => \%metamod,
	});

	$dbslash->setModeratorVotes($user->{uid}, \%metamod) unless $user->{is_anon};

	# Of course, I'm waiting for someone to make the eventual joke...
	my($change, $excon);
	if ($y > $constants->{m2_mincheck} && !$user->{is_anon}) {
		if (!$flag && karmaBonus($user, $constants)) {
			# Bonus Karma For Helping Out - the idea here, is to not 
			# let meta-moderators get the +1 posting bonus.
			($change, $excon) =
				("karma$constants->{m2_bonus}", "and karma<$constants->{m2_maxbonus}");
			$change = $constants->{m2_maxbonus}
				if $constants->{m2_maxbonus} < $user->{karma} + $constants->{m2_bonus};

		} elsif ($flag == 2) {
			# Penalty for Abuse
			($change, $excon) = ("karma$constants->{m2_penalty}", '');
		}

		# Update karma.
		# This is an abuse
		$dbslash->setUser($user->{uid}, { -karma => "karma$change" }) if $change;
	}
}


#################################################################
sub displayTheComments {
	my ($id, $user, $dbslash, $constants) = @_;

	$user->{points} = 0;
	my $comments = $dbslash->getMetamodComments($id, $user->{uid}, $constants->{m2_comments});

	slashDisplay('display', {
		comments 	=> $comments,
	});
}


#################################################################
# This is going to break under replication
sub isEligible {
	my ($user, $dbslash, $constants) = @_;

	my $tuid = $dbslash->countUsers();
	my $last = $dbslash->getModeratorLast($user->{uid});

	my $result = slashDisplay('eligibility-tests', {
		user_count	=> $tuid,
		'last'		=> $last,
	}, { Return => 1, Nocomm => 1 });

	if ($result ne 'Eligible') {
		print $result;
		return 0;
	}

	# Eligible for M2. Determine M2 comments by selecting random starting
	# point in moderatorlog.
	unless ($last->{'lastmmid'}) {
		$last->{'lastmmid'} = $dbslash->getModeratorLogRandom();
		$dbslash->setUser($user->{uid}, { lastmmid => $last->{'lastmmid'} });
	}

	return $last->{'lastmmid'}; # Hooray!
}

createEnvironment();
main();

