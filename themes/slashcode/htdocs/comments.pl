#!/usr/bin/perl -w

###############################################################################
# comments.pl - this code displays comments for a particular story id 
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
use Date::Manip;
use Compress::Zlib;
use vars '%I';
use Slash;
use Slash::DB;
use Slash::Utility;
use CGI ();


##################################################################
sub main {
	*I = getSlashConf();
	getSlash();
	my $form = getCurrentForm();

	my $id = getFormkeyId($I{U}{uid});

	# Seek Section for Appropriate L&F
	my $stories;
	#This is here to save a function call, even though the
	# function can handle the situation itself
	if ($I{F}{sid}) {
		$stories = $I{dbobject}->getNewStory($I{F}{sid},
			['section', 'title', 'commentstatus']);
	} else {
		$stories->{'title'} = "Comments";
	}
	my $SECT = getSection($stories->{'section'});

	$I{F}{pid} ||= "0";
	
	header("$SECT->{title}: $stories->{'title'}", $SECT->{section});

	if ($I{U}{uid} < 1 && length($I{F}{upasswd}) > 1) {
		print "<P><B>Login for \"$I{F}{unickname}\" has failed</B>.  
			Please try again. $I{F}{op}<BR><P>";
		$I{F}{op} = "Preview";
	}

	$I{U}{karma} = $I{dbobject}->getUser($I{U}{uid}, 'karma')
		unless $I{U}{is_anon};
	$I{dbobject}->createDiscussions($I{F}{sid}) unless ($I{F}{sid});

	if ($I{F}{op} eq "Submit") {

		if (checkSubmission("comments", $I{post_limit}, $I{max_posts_allowed}, $id)) {
			submitComment();
		}

	} elsif ($I{F}{op} eq "Edit" || $I{F}{op} eq "post" 
			||
		$I{F}{op} eq "Preview" || $I{F}{op} eq "Reply") {

		if ($I{F}{op} eq 'Reply') {
			$I{F}{formkey} = getFormkey();
			$I{dbobject}->insertFormkey("comments", $id, $I{F}{sid});	
		} else {
			$I{dbobject}->updateFormkeyId("comments", $I{F}{formkey},
				getCurrentStatic('anonymous_coward_uid'), $I{U}{uid},
				$form->{'rlogin'}, $I{F}{upasswd}
			);
		}

		# find out their Karma
		editComment($id);


	} elsif ($I{F}{op} eq "delete" && $I{U}{aseclev}) {
		titlebar("99%", "Delete $I{F}{cid}");

		my $delCount = deleteThread($I{F}{sid}, $I{F}{cid});
		$I{dbobject}->setCommentCount($delCount);
		print "Deleted $delCount items from story $I{F}{sid}\n";

	} elsif ($I{F}{op} eq "moderate") {
		titlebar("99%", "Moderating $I{F}{sid}");
		moderate();
		printComments($I{F}{sid}, $I{F}{pid}, $I{F}{cid});

	} elsif ($I{F}{op} eq "Change") {
		if ($I{U}{is_anon} || defined $I{F}->{"savechanges"}) {
			$I{dbobject}->setUser($I{U}{uid}, {
					threshold	=> $I{U}{threshold}, 
					mode		=> $I{U}{mode},
					commentsort	=> $I{U}{commentsort}
			}) unless $I{U}{is_anon};
		}
		printComments($I{F}{sid}, $I{F}{cid}, $I{F}{cid});

	} elsif ($I{F}{cid}) {
		printComments($I{F}{sid}, $I{F}{cid}, $I{F}{cid});

	} elsif ($I{F}{sid}) {
		printComments($I{F}{sid}, $I{F}{pid});

	} else {
		commentIndex();
	}

	writeLog("comments", $I{F}{sid}) unless $I{F}{ssi};

	footer();
}


##################################################################
# Index of recent discussions: Used if comments.pl is called w/ no
# parameters
sub commentIndex {
	titlebar("90%", "Several Active Discussions");
	print qq!<MULTICOL COLS="2">\n!;

	my $discussions = $I{dbobject}->getDiscussions();
	for(@$discussions) {
		my($sid, $title, $url) = @$_;
		$title ||= "untitled";
		print <<EOT;
	<LI><A HREF="$I{rootdir}/comments.pl?sid=$sid">$title</A>
	(<A HREF="$url">referer</A>)

EOT

	}

	print "</MULTICOL>\n\n";
}


##################################################################
# Welcome to one of the ancient beast functions.  The comment editor
# is the form in which you edit a comment.
sub editComment {
	my($id) = @_;
	$I{U}{points} = 0;

	my $formkey_earliest = time() - $I{formkey_timeframe};

	my $reply = $I{dbobject}->getCommentReply(
		getDateFormat("date", "time"),
		$I{F}{sid}, $I{F}{pid}
	);

	# Display parent comment if we got one
	if ($I{F}{pid}) {
		titlebar("95%", " $reply->{subject}");
		print <<EOT;
<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="95%" ALIGN="CENTER">
EOT
		dispComment($reply);
		print "\n</TABLE><P>\n\n";
	}

	if (!$I{dbobject}->checkTimesPosted("comments", $I{max_posts_allowed}, $id, $formkey_earliest)) {
		my $max_posts_warn =<<EOT;
<P><B>Warning! you've exceeded max allowed submissions for the day :
$I{max_submissions_allowed}</B></P>
EOT
		errorMessage($max_posts_warn);
	}

	if (!$I{allow_anonymous} && (!$I{U}{uid} || $I{U}{uid} < 1)) {
	    print <<EOT;
Sorry, anonymous posting has been turned off.
Please <A HREF="$I{rootdir}/users.pl">register and log in</A>.
EOT
	    return;
	}

	
	if ($I{F}{postercomment}) {
		titlebar("95%", "Preview Comment"); 
		previewForm();
		print "<P>\n";
	}

	titlebar("95%", "Post Comment");
	print <<EOT;

<FORM ACTION="$ENV{SCRIPT_NAME}" METHOD="POST">

	<INPUT TYPE="HIDDEN" NAME="sid" VALUE="$I{F}{sid}">
	<INPUT TYPE="HIDDEN" NAME="pid" VALUE="$I{F}{pid}">
	<INPUT TYPE="HIDDEN" NAME="mode" VALUE="$I{U}{mode}">
	<INPUT TYPE="HIDDEN" NAME="startat" VALUE="$I{U}{startat}">
	<INPUT TYPE="HIDDEN" NAME="threshold" VALUE="$I{U}{threshold}">
	<INPUT TYPE="HIDDEN" NAME="commentsort" VALUE="$I{U}{commentsort}">

	<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="1">

EOT

	 # put in hidden field if there's a formkey
        print qq(<INPUT type="hidden" name="formkey" value="$I{F}{formkey}">\n);

	print <<EOT if $I{U}{uid} < 1;
	<TR><TD> </TD><TD>
		You are not logged in.  You can login now using the
		convenient form below, or
		<A HREF="$I{rootdir}/users.pl">Create an Account</A>.
		Posts without proper registration are posted as
		<B>$I{U}{nickname}</B>
	</TD></TR>

	<INPUT TYPE="HIDDEN" NAME="rlogin" VALUE="userlogin">

	<TR><TD ALIGN="RIGHT">Nick</TD><TD>
		<INPUT TYPE="TEXT" NAME="unickname" VALUE="$I{F}{unickname}">

	</TD></TR><TR><TD ALIGN="RIGHT">Passwd</TD><TD>
		<INPUT TYPE="PASSWORD" NAME="upasswd">

	</TD></TR>

EOT

	print <<EOT;
	<TR><TD WIDTH="130" ALIGN="RIGHT">Name</TD><TD WIDTH="500">
		<A HREF="$I{rootdir}/users.pl">$I{U}{nickname}</A> [
EOT

	print !$I{U}{is_anon} ? <<EOT1 : <<EOT2;
		<A HREF="$I{rootdir}/users.pl?op=userclose">Log Out</A> 
EOT1
		<A HREF="$I{rootdir}/users.pl">Create Account</A> 
EOT2
			
	print " ] </TD></TR>\n\n";

	print <<EOT if $I{U}{fakeemail};
	<TR><TD ALIGN="RIGHT">Email</TD>
		<TD>$I{U}{fakeemail}</TD></TR>

EOT

	print <<EOT if $I{U}{homepage};
	<TR><TD ALIGN="RIGHT">URL</TD>
		<TD><A HREF="$I{U}{homepage}">$I{U}{homepage}</A></TD></TR>

EOT

	print qq!\t<TR><TD ALIGN="RIGHT">Subject</TD>\n\n!;

	if ($I{F}{pid} && !$I{F}{postersubj}) { 
		$I{F}{postersubj} = $reply->{subject};
		$I{F}{postersubj} =~ s/^Re://i;
		$I{F}{postersubj} =~ s/\s\s/ /g;
		$I{F}{postersubj} = "Re:$I{F}{postersubj}";
	} 

	print "\t\t<TD>", CGI::textfield(
		-name		=> 'postersubj', 
		-default	=> $I{F}{postersubj}, 
		-size		=> 50,
		-maxlength	=> 50
	), "</TD></TR>\n\n";

	printf <<EOT, stripByMode($I{F}{postercomment}, 'literal');
	<TR>
		<TD ALIGN="RIGHT" VALIGN="TOP">Comment</TD>
		<TD><TEXTAREA WRAP="VIRTUAL" NAME="postercomment" ROWS="10"
		COLS="50">%s</TEXTAREA>
		<BR>(Use the Preview Button! Check those URLs!
		Don't forget the http://!)
	</TD></TR>

	<TR><TD> </TD><TD>
EOT

	my $checked = $I{F}{nobonus} ? ' CHECKED' : '';
	print qq!\t\t<INPUT TYPE="CHECKBOX"$checked NAME="nobonus"> No Score +1 Bonus\n!
		if $I{U}{karma} > $I{goodkarma} && !$I{U}{is_anon};

        if ($I{allow_anonymous}) {
	    $checked = $I{F}{postanon} ? ' CHECKED' : '';
	    print qq!\t\t<INPUT TYPE="CHECKBOX"$checked NAME="postanon"> Post Anonymously<BR>\n!
		if $I{U}{karma} > -1 && !$I{U}{is_anon};
        }

	print <<EOT;
		<INPUT TYPE="SUBMIT" NAME="op" VALUE="Submit">
		<INPUT TYPE="SUBMIT" NAME="op" VALUE="Preview">

EOT

	my $formats = $I{dbobject}->getDescriptions('postmodes');
	if ($I{F}{posttype}) {
		createSelect('posttype', $formats, $I{F}{posttype});
	} else {
		createSelect('posttype', $formats, $I{U}{posttype});
	}

	printf <<EOT, join "\n", map { "\t\t\t&lt;$_&gt;" } @{$I{approvedtags}};
	</TD></TR><TR>
		<TD VALIGN="TOP" ALIGN="RIGHT">Allowed HTML</TD><TD><FONT SIZE="1">
%s
		</FONT>
	</TD></TR>
</TABLE>


</FORM>

<B>Important Stuff:</B>
	<LI>Please try to keep posts on topic.
	<LI>Try to reply to other people comments instead of starting
		new threads.
	<LI>Read other people's messages before posting your own to
		avoid simply duplicating what has already been said.
	<LI>Use a clear subject that describes what your message is about.
	<LI>Offtopic, Inflammatory, Inappropriate, Illegal,
		or Offensive comments might be moderated.  (You can read
		everything, even moderated posts, by adjusting your 
		threshold on the User Preferences Page)

<P><FONT SIZE="2">Problems regarding accounts or comment posting 
	should be sent to
	<A HREF="mailto:$I{adminmail}">$I{siteadmin_name}</A>.</FONT>
EOT

}

##################################################################
# Validate comment, looking for errors
sub validateComment {
	my($comm, $subj, $preview) = @_;
	my $slashdb = getCurrentDB();
	my $constants = getCurrentStatic();
	my $user = getCurrentUser();
	my $form = getCurrentForm();

	if (isTroll()) {
		print <<EOT;
This account or IP has been temporarily disabled. This means that either
this IP or user account has been moderated down more than 5 times in the
last 24 hours.  If you think this is unfair, you should contact
$constants->{adminmail}.  If you are being a troll, now is the time for you to
either grow up, or change your IP.
EOT

		return;
	}

	if (!$constants->{allow_anonymous} && ($user->{uid} < 1 || $form->{postanon})) { 
		print <<EOT;
Sorry, anonymous posting has been turned off.
Please <A HREF="$constants->{rootdir}/users.pl">register and log in</A>.
EOT

		return;
	}

	unless ($comm && $subj) {
		print <<EOT;
Cat got your tongue? (something important seems to be missing from your
comment ... like the body or the subject!)
EOT
		return;
	}

	$subj =~ s/\(Score(.*)//i;
	$subj =~ s/Score:(.*)//i;

	{  # fix unclosed tags
		my(%tags, @stack, $match, %lone, $tag, $close, $whole);

		# set up / get preferences
		if ($constants->{lonetags}) {
			$match = join '|', @{$constants->{approvedtags}};
		} else {
			$constants->{lonetags} = [qw(BR P LI)];
			$match = join '|', grep !/^(?:BR|P|LI)$/,
				@{$constants->{approvedtags}};
		}
		%lone = map { ($_, 1) } @{$constants->{lonetags}};

		while ($comm =~ m|(<(/?)($match)\b[^>]*>)|igo) { # loop over tags
			($tag, $close, $whole) = ($3, $2, $1);

			if ($close) {
				if (@stack && $tags{$tag}) {
					# Close the tag on the top of the stack
					if ($stack[-1] eq $tag) {
						$tags{$tag}--;
						pop @stack;

					# Close tag somewhere else in stack
					} else {
						my $p = pos($comm) - length($whole);
						if (exists $lone{$stack[-1]}) {
							pop @stack;
						} else {
							substr($comm, $p, 0) = "</$stack[-1]>";
						}
						pos($comm) = $p;  # don't remove this from stack, go again
					}

				} else {
					# Close tag not on stack; just delete it
					my $p = pos($comm) - length($whole);
					$comm =~ s|^(.{$p})\Q$whole\E|$1|si;
					pos($comm) = $p;
				}


			} else {
				$tags{$tag}++;
				push @stack, $tag;

				if (($tags{UL} + $tags{OL} + $tags{BLOCKQUOTE}) > 4) {
					print <<EOT;
You can only post nested lists and blockquotes four levels deep.
Please fix your UL, OL, and BLOCKQUOTE tags.
EOT

					return;
				}
			}

		}

		$comm =~ s/\s+$//;

		# add on any unclosed tags still on stack
		$comm .= join '', map { "</$_>" } grep {! exists $lone{$_}} reverse @stack;

	}

	my $dupRows = $slashdb->countComments($form->{sid}, '', '', $form->{postercomment});

	if ($dupRows || !$form->{sid}) { 
		editComment(), return unless $preview;
		print <<EOT;
Something is wrong: parent=$form->{pid} dups=$dupRows discussion=$form->{sid}
<UL>
EOT

		print "<LI>Didja forget a subject?</LI>\n" unless $form->{postersubj};
		print "<LI>Duplicate.  Did you submit twice?</LI>\n" if $dupRows;
		print "<LI>Space aliens have eaten your data.</LI>\n" unless $form->{sid};
		print <<EOT;
<LI>Let us know if anything exceptionally strange happens</LI>
</UL>
EOT
		return;
	}

	if (length($form->{postercomment}) > 100) {
		local $_ = $form->{postercomment};
		my($w, $br); # Whitespace & BRs
		$w++ while m/\w/g;
		$br++ while m/<BR>/gi;

		if (($w / ($br + 1)) < 7) {
			editComment(), return unless $preview;
			return;
		}
	}

	# here begins the troll detection code - PMG 160200
	# hash ref from db containing regex, modifier (gi,g,..),field to be tested,
	# ratio of field (this makes up the {x,} in the regex, minimum match (hard minimum), 
	# minimum length (minimum length of that comment has to be to be tested), err_message 
	# message displayed upon failure to post if regex matches contents.
	# make sure that we don't select new filters without any regex data
	my $filters = $slashdb->getContentFilters();

	for (@$filters) {
		my($number_match, $regex);
		my $raw_regex		= $_->[1];
		my $modifier		= 'g' if $_->[2] =~ /g/;
		my $case		= 'i' if $_->[2] =~ /i/;
		my $field		= $_->[3];
		my $ratio		= $_->[4];
		my $minimum_match	= $_->[5];
		my $minimum_length	= $_->[6];
		my $err_message		= $_->[7];
		my $maximum_length	= $_->[8];
		my $isTrollish		= 0;
		
		next if ($minimum_length && length($form->{$field}) < $minimum_length);
		next if ($maximum_length && length($form->{$field}) > $maximum_length);

		if ($minimum_match) {
			$number_match = "{$minimum_match,}";
		} elsif ($ratio > 0) {
			$number_match = "{" . int(length($form->{$field}) * $ratio) . ",}";
		}

		$regex = $raw_regex . $number_match;
		my $tmp_regex = $regex;


		$regex = $case eq 'i' ? qr/$regex/i : qr/$regex/;

		if ($modifier eq 'g') {
			$isTrollish = 1 if $form->{$field} =~ /$regex/g;
		} else {
			$isTrollish = 1 if $form->{$field} =~ /$regex/;
		}

		if ((length($form->{$field}) >= $minimum_length)
			&& $minimum_length && $isTrollish) {

			if (((length($form->{$field}) <= $maximum_length)
				&& $maximum_length) || $isTrollish) {

				editComment(), return unless $preview;
				print <<EOT;
<BR>Lameness filter encountered.  Post aborted.<BR><BR><B>$err_message</B><BR>
EOT
				return;
			}

		} elsif ($isTrollish) {
			editComment(), return unless $preview;
			print <<EOT;
<BR>Lameness filter encountered.  Post aborted.<BR><BR><B>$err_message</B><BR>
EOT
			return;
		}
	}

	# interpolative hash ref. Got these figures by testing out
	# several paragraphs of text and saw how each compressed
	# the key is the ratio it should compress, the array lower,upper
	# for the ratio. These ratios are _very_ conservative
	# a comment has to be absolute shit to trip this off
	my $limits = {
		1.3 => [10,19],
		1.1 => [20,29],
		.8 => [30,44],
		.5 => [45,99],
		.4 => [100,199],
		.3 => [200,299],
		.2 => [300,399],
		.1 => [400,1000000],
	};

	# Ok, one list ditch effort to skew out the trolls!
	if (length($form->{postercomment}) >= 10) {
		for (keys %$limits) {
			# DEBUG
			# print "ratio $_ lower $limits->{$_}->[0] upper $limits->{$_}->[1]<br>\n";
			# if it's within lower to upper
			if (length($form->{postercomment}) >= $limits->{$_}->[0]
				&& length($form->{postercomment}) <= $limits->{$_}->[1]) {

				# if is >= the ratio, then it's most likely a troll comment
				if ((length(compress($form->{postercomment})) /
					length($form->{postercomment})) <= $_) {

					editComment(), return unless $preview;
					# blammo luser
					print <<EOT;


<BR>Lameness filter encountered.  Post aborted.<BR><BR>
EOT
				}

			}
		}
	}

	return($comm, $subj);
}

##################################################################
# Previews a comment for submission
sub previewForm {
	$I{U}{sig} = "" if $I{F}{postanon};

	my $tempComment = stripByMode($I{F}{postercomment}, $I{F}{posttype});
	my $tempSubject = stripByMode(
		$I{F}{postersubj}, 'nohtml', $I{U}{aseclev}, 'B'
	);

	($tempComment, $tempSubject) = validateComment($tempComment, $tempSubject, 1);

	$tempComment .= '<BR>' . $I{U}{sig};

	my $preview = {
		nickname  => $I{F}{postanon} ? getCurrentAnonymousCoward('nickname') : $I{U}{nickname},
		pid	  => $I{F}{pid},
		homepage  => $I{F}{postanon} ? '' : $I{U}{homepage},
		fakeemail => $I{F}{postanon} ? '' : $I{U}{fakeemail},
		'time'	  => 'soon',
		subject	  => $tempSubject,
		comment	  => $tempComment
	};

	print <<EOT;
<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="95%" ALIGN="CENTER">
EOT

	my $tm = $I{U}{mode};
	$I{U}{mode} = 'archive';
	dispComment($preview);       
	$I{U}{mode} = $tm;

	print "</TABLE>\n";
}


##################################################################
# Saves the Comment
sub submitComment {
	$I{F}{postersubj} = stripByMode(
		$I{F}{postersubj}, 'nohtml', $I{U}{aseclev}, ''
	);
	$I{F}{postercomment} = stripByMode($I{F}{postercomment}, $I{F}{posttype});

	($I{F}{postercomment}, $I{F}{postersubj}) =
		validateComment($I{F}{postercomment}, $I{F}{postersubj})
		or return;

	titlebar("95%", "Submitted Comment");

	my $pts = 0;

	if (!$I{U}{is_anon} && !$I{F}{postanon} ) {
		$pts = $I{U}{defaultpoints};
		$pts-- if $I{U}{karma} < $I{badkarma};
		$pts++ if $I{U}{karma} > $I{goodkarma} && !$I{F}{nobonus};
		# Enforce proper ranges on comment points.
		$pts = $I{comment_minscore} if $pts < $I{comment_minscore};
		$pts = $I{comment_maxscore} if $pts > $I{comment_maxscore};
	}

	# It would be nice to have an arithmatic if right here
	my $maxCid = $I{dbobject}->setComment($I{F}, $I{U}, $pts, getCurrentStatic('anonymous_coward_uid'));
	if ($maxCid == -1) {
		print "<P>There was an unknown error in the submission.<BR>";
	} elsif (!$maxCid) {
		print "Don't you have anything better to do with your life? $maxCid";	
	} else {
		print "Comment Submitted. There will be a delay before the comment becomes part
			of the static page.  What you submitted appears below.  If there is a
			mistake, well, you should have used the Preview button!<P>";
		undoModeration($I{F}{sid});
		printComments($I{F}{sid}, $maxCid, $maxCid);
	}
}

##################################################################
# Handles moderation
# gotta be a way to simplify this -Brian
sub moderate {
	my $totalDel = 0;
	my $hasPosted;
	unless($I{U}{aseclev} > 99 && $I{authors_unlimited}) {
		$hasPosted = $I{dbobject}->commentCount($I{F}{sid},'','', $I{U}{uid});
	}

	print "\n<UL>\n";

	# Handle Deletions, Points & Reparenting
	for (sort keys %{$I{F}}) {
		if (/^del_(\d+)$/) { # && $I{U}{points}) {
			my $delCount = deleteThread($I{F}{sid}, $1);
			$totalDel += $delCount;
			$I{dbobject}->setStoriesCount($I{F}{sid}, $delCount);

			print <<EOT if $totalDel;
	<LI>Deleted $delCount items from story $I{F}{sid} under comment $I{F}{$_}</LI>
EOT

		} elsif (!$hasPosted && /^reason_(\d+)$/) {
			moderateCid($I{F}{sid}, $1, $I{F}{"reason_$1"});
		}
	}

	print "\n</UL>\n";

	if ($hasPosted && !$totalDel) {
		print "You've already posted something in this discussion<BR>";
	} elsif ($I{U}{aseclev} && $totalDel) {
		my $count = $I{dbobject}->setCommentCount($I{F}{sid});
		print "$totalDel comments deleted.  Comment count set to $count<BR>\n";
	}
}

##################################################################
# Handles moderation
# Moderates a specific comment
sub moderateCid {
	my($sid, $cid, $reason) = @_;
	# Check if $uid has seclev and Credits
	return unless $reason;
	
	if ($I{U}{points} < 1) {
		unless ($I{U}{aseclev} > 99 && $I{authors_unlimited}) {
			print "You don't have any moderator points.";
			return;
		}
	}

	my($cuid, $ppid, $subj, $points, $oldreason) = $I{dbobject}->getComments($sid, $cid);
	
	unless ($I{U}{aseclev} > 99 && $I{authors_unlimited}) {
		my $mid = $I{dbobject}->getModeratorLogID($cid, $sid, $I{U}{uid});
		if ($mid) {
			print "<LI>$subj ($sid-$cid, <B>Already moderated</B>)</LI>";
			return;
		}	
	}

	my $modreason = $reason;
	my $val = "-1";
	if ($reason == 9) { # Overrated
		$val = "-1";
		$val = "+0" if $points < 0;
		$reason = $oldreason;
	} elsif ($reason == 10) { # Underrated
		$val = "+1";
		$val = "+0" if $points > 1;
		$reason = $oldreason;
	} elsif ($reason > $I{badreasons}) {
		$val = "+1";
	}

	my $scorecheck = $points + $val;
	# If the resulting score is out of comment score range, no further actions 
	# need be performed.
	if ($scorecheck < $I{comment_minscore} || $scorecheck > $I{comment_maxscore}) {
		# We should still log the attempt for M2, but marked as inactive so
		# we don't mistakenly undo it.
		$I{dbobject}->setModeratorLog($cid, $sid, $I{U}{uid}, $modreason, $val);

		print "<LI>$subj ($sid-$cid, <B>Comment already at limit</B>)</LI>";
		return;
	}

	if($I{dbobject}->setCommentCleanup($val, $sid, $reason, $modreason, $cid)) {
		print <<EOT;
	<LI>$val ($I{reasons}[$reason]) $subj
		($sid-$cid, <B>$I{U}{points}</B> points left)</LI>
EOT
	}
}

##################################################################
# Given an SID & A CID this will delete a comment, and all its replies
sub deleteThread {
	my($sid, $cid) = @_;
	my $delCount = 1;

	return unless $I{U}{aseclev} > 100;

	print "Deleting $cid from $sid, ";

	my $delkids = $I{dbobject}->getCommentCid($sid,$cid);

	for (@$delkids) {
		$delCount += deleteThread($sid, $_);
	}

	$I{dbobject}->deleteComment($sid, $cid);

	print "<BR>";
	return $delCount;
}


##################################################################
# If you moderate, and then post, all your moderation is undone.
sub undoModeration {
	my($sid) = @_;
	return if !$I{U}{is_anon}
		|| ($I{U}{aseclev} > 99 && $I{authors_unlimited});
	my $removed = $I{dbobject}->unsetModeratorlog($I{U}{uid}, $sid, $I{comment_maxscore},$I{comment_minscore});

	for my $cid (@$removed) {
		print "Undoing moderation to Comment #$cid<BR>";
	}	
}

##################################################################
# Troll Detection: essentially checks to see if this IP or UID has been abusing
# the system in the last 24 hours.
# 1=Troll 0=Good Little Goober
# This maybe should go into DB package -Brian
sub isTroll {
	return if $I{U}{aseclev} > 99;
	my($badIP, $badUID) = (0, 0);
	return 0 if !$I{U}{is_anon} && $I{U}{karma} > -1;
	# Anonymous only checks HOST
	$badIP = $I{dbobject}->getTrollAddress();
	return 1 if $badIP < $I{down_moderations}; 

	unless ($I{U}{is_anon}) {
		$badUID = $I{dbobject}->getTrollUID();
	}

	return 1 if $badUID < $I{down_moderations};
	return 0;
}

main();
0;
