#!/usr/bin/perl -w
# This code is a part of Slash, and is released under the GPL.
# Copyright 1997-2001 by Open Source Development Network. See README
# and COPYING for more information, or see http://slashcode.com/.
# $Id$

use strict;
use Slash;
use Slash::Display;
use Slash::Utility;
use Slash::XML;
use URI;

use constant MSG_CODE_NEW_SUBMISSION => 6;

#################################################################
sub main {
	my $slashdb = getCurrentDB();
	my $constants = getCurrentStatic();
	my $user = getCurrentUser();
	my $form = getCurrentForm();

	$form->{del}	||= 0;
	$form->{op}	||= '';

	if (($form->{content_type} eq 'rss') and ($form->{op} eq 'list') and $constants->{submiss_view}) {
		my $success = displayRSS($slashdb, $constants, $user, $form);
		return if $success;
	}

	my $id = getFormkeyId($user->{uid});
	my($section, $op) = (
		$form->{section}, $form->{op});
	$user->{submit_admin} = 1 if $user->{seclev} >= 100;

	# this really should not be done now, but later, it causes
	# a lot of problems -- pudge
	$form->{from}	= strip_attribute($form->{from})  if $form->{from};
	$form->{subj}	= strip_attribute($form->{subj})  if $form->{subj};
	$form->{email}	= strip_attribute($form->{email}) if $form->{email};

	# Show submission title on browser's titlebar.
	my($tbtitle) = $form->{title};
	if ($tbtitle) {
		$tbtitle =~ s/^"?(.+?)"?$/"$1"/;
		$tbtitle = "- $tbtitle";
	}

	$section = 'admin' if $user->{submit_admin};
	header(getData('header', { tbtitle => $tbtitle }), $section);

	if ($op eq 'list' && ($user->{submit_admin} || $constants->{submiss_view})) {
		submissionEd();

	} elsif ($op eq 'Update' && $user->{submit_admin}) {
		my @subids = $slashdb->deleteSubmission();
		submissionEd(getData('updatehead', { subids => \@subids }));

	} elsif ($op eq 'GenQuickies' && $user->{submit_admin}) {
		genQuickies();
		submissionEd(getData('quickieshead'));

	} elsif ($op eq 'PreviewStory') {
		$slashdb->createFormkey('submissions', $id, 'submission');
		displayForm($form->{from}, $form->{email}, $form->{section},
			$id, getData('previewhead'));

	} elsif ($op eq 'viewsub' && ($user->{submit_admin} || $constants->{submiss_view})) {
		previewForm($form->{subid});

	} elsif ($op eq 'SubmitStory') {
		saveSub($id);
		yourPendingSubmissions();

	} else {
		yourPendingSubmissions();
		displayForm($user->{nickname}, $user->{fakeemail}, $form->{section},
			$id, getData('defaulthead'));
	}

	footer();
}

#################################################################
sub yourPendingSubmissions {
	my $slashdb = getCurrentDB();
	my $user = getCurrentUser();

	return if $user->{is_anon};

	if (my $submissions = $slashdb->getSubmissionsPending()) {
		my $count = $slashdb->getSubmissionCount();
		slashDisplay('yourPendingSubs', {
			submissions	=> $submissions,
			title		=> "Your Recent Submissions (total:$count)",
			width		=> '100%',
			totalcount	=> $count,
		});
	}
}

#################################################################
sub previewForm {
	my($subid) = @_;
	my $slashdb = getCurrentDB();
	my $constants = getCurrentStatic();
	my $form = getCurrentForm();

	my $sub = $slashdb->getSubmission($subid,
		[qw(email name subj tid story time comment uid)]);

	$sub->{email} = processSub($sub->{email});

	$slashdb->setSession(getCurrentUser('uid'), { lasttitle => $sub->{subj} });

	slashDisplay('previewForm', {
		submission	=> $sub,
		submitter	=> $sub->{uid},
		subid		=> $subid,
		lockTest	=> lockTest($sub->{subj}),
		section		=> $form->{section} || $constants->{defaultsection},
	});
}

#################################################################
sub genQuickies {
	my $slashdb = getCurrentDB();
	my $submissions = $slashdb->getQuickies();
	my $stuff = slashDisplay('genQuickies', { submissions => $submissions },
		{ Return => 1, Nocomm => 1 });
	$slashdb->setQuickies($stuff);
}

#################################################################
sub submissionEd {
	# mmmm, code comments in here sure would be nice
	my($title) = @_;
	my $slashdb = getCurrentDB();
	my $constants = getCurrentStatic();
	my $user = getCurrentUser();
	my $form = getCurrentForm();
	my($def_section, $cur_section, $def_note, $cur_note,
		$sections, @sections, @notes,
		%all_sections, %all_notes, %sn);

	$form->{del} = 0 if $user->{submit_admin};

	$def_section	= getData('defaultsection');
	$def_note	= getData('defaultnote');
	$cur_section	= $form->{section} || $def_section;
	$cur_note	= $form->{note} || $def_note;
	$sections = $slashdb->getSubmissionsSections();

	for (@$sections) {
		my($section, $note, $cnt) = @$_;
		$all_sections{$section} = 1;
		$note ||= $def_note;
		$all_notes{$note} = 1;
		$sn{$section}{$note} = $cnt;
	}

	for my $note_str (keys %all_notes) {
		$sn{$def_section}{$note_str} = 0;
		for (grep { $_ ne $def_section } keys %sn) {
			$sn{$def_section}{$note_str} += $sn{$_}{$note_str};
		}
	}

	$all_sections{$def_section} = 1;

	# self documentation, right?
	@sections =	map  { [$_->[0], ($_->[0] eq $def_section ? '' : $_->[0])] }
			sort { $a->[1] cmp $b->[1] }
			map  { [$_, ($_ eq $def_section ? '' : $_)] }
			keys %all_sections;

	@notes =	map  { [$_->[0], ($_->[0] eq $def_note ? '' : $_->[0])] }
			sort { $a->[1] cmp $b->[1] }
			map  { [$_, ($_ eq $def_note ? '' : $_)] }
			keys %all_notes;

	slashDisplay('subEdTable', {
		cur_section	=> $cur_section,
		cur_note	=> $cur_note,
		def_section	=> $def_section,
		def_note	=> $def_note,
		sections	=> \@sections,
		notes		=> \@notes,
		sn		=> \%sn,
		title		=> $title || ('Submissions ' . ($user->{submit_admin} ? 'Admin' : 'List')),
		width		=> '100%',
	});

	my(@submissions, $submissions, %selection);
	$submissions = $slashdb->getSubmissionForUser();

	for (@$submissions) {
		my $sub = $submissions[@submissions] = {};
		@{$sub}{qw(
			subid subj time tid note email
			name section comment uid karma
		)} = @$_;
		$sub->{name}  =~ s/<(.*)>//g;
		$sub->{email} =~ s/<(.*)>//g;
		$sub->{is_anon} = isAnon($sub->{uid});

		my @strs = (
			substr($sub->{subj}, 0, 35),
			substr($sub->{name}, 0, 20),
			substr($sub->{email}, 0, 20)
		);
		$strs[0] .= '...' if length($sub->{subj}) > 35;
		$sub->{strs} = \@strs;

		$sub->{ssection} = $sub->{section} ne $constants->{defaultsection}
			? "&section=$sub->{section}" : '';
		$sub->{stitle}   = '&title=' . fixparam($sub->{subj});
		$sub->{section} = ucfirst($sub->{section}) unless $user->{submit_admin};
	}

	%selection = map { ($_, $_) }
		(qw(Hold Quik), '',	# '' is special
		(ref $constants->{submit_categories}
			? @{$constants->{submit_categories}} : ())
	);

	my $template = $user->{submit_admin} ? 'Admin' : 'User';
	slashDisplay('subEd' . $template, {
		submissions	=> \@submissions,
		selection	=> \%selection,
	});
}

#################################################################
sub displayRSS {
	my($slashdb, $constants, $user, $form) = @_;
	my($submissions, @items);
	$submissions = $slashdb->getSubmissionForUser();

	for (@$submissions) {
		my($subid, $subj, $time, $tid, $note, $email, $name,
			$section, $comment, $uid, $karma) = @$_;

		# title should be cleaned up
		push(@items, {
			title	=> $subj,
			'link'	=> "$constants->{absolutedir}/submit.pl?op=viewsub&subid=$subid",
		});
	}

	xmlDisplay('rss', {
		channel	=> {
			title	=> "$constants->{sitename} Submissions",
			'link'	=> "$constants->{absolutedir}/submit.pl?op=list",
		},
		image	=> 1,
		items	=> \@items,
	});
}


#################################################################
sub displayForm {
	my($username, $fakeemail, $section, $id, $title, $error_message) = @_;
	my $slashdb = getCurrentDB();
	my $constants = getCurrentStatic();
	my $form = getCurrentForm();
	my $formkey_earliest = time() - $constants->{formkey_timeframe};

	if (!$slashdb->checkTimesPosted('submissions',
		$constants->{max_submissions_allowed}, $id, $formkey_earliest)
	) {
		print getData('maxallowed');
	}

	if ($error_message ne '') {
		titlebar('100%', getData('filtererror', { err_message => $error_message}));
		print getData('filtererror', { err_message => $error_message });
	} else {
		for (keys %$form) {
			my $message = "";
			# run through filters
			if (! filterOk('submissions', $_, $form->{$_}, \$message)) {
				my $err = getData('filtererror', { err_message => $message});
				titlebar('100%', $err);
				print $err;
				last;
			}
			# run through compress test
			if (! compressOk('submissions', $_, $form->{$_})) {
				# blammo luser
				my $err = getData('compresserror');
				titlebar('100%', $err);
				print $err;
				last;
			}
		}
	}


	$form->{tid} ||= $constants->{defaulttopic};
	slashDisplay('displayForm', {
		fixedstory	=> strip_html(url2html($form->{story})),
		savestory	=> $form->{story} && $form->{subj},
		username	=> $form->{from} || $username,
		fakeemail	=> processSub($form->{email} || $fakeemail),
		section		=> $form->{section} || $section || $constants->{defaultsection},
		topic		=> $slashdb->getTopic($form->{tid}),
		width		=> '100%',
		title		=> $title,
	});
}

#################################################################
sub saveSub {
	my($id) = @_;
	my $slashdb = getCurrentDB();
	my $constants = getCurrentStatic();
	my $form = getCurrentForm();

	my $err_message = '';
	if (checkFormPost('submissions', $constants->{submission_speed_limit},
		$constants->{max_submissions_allowed}, $id, \$err_message)
	) {
		if (length($form->{subj}) < 2) {
			titlebar('100%', getData('error'));
			my $error_message = getData('badsubject');
			displayForm($form->{from}, $form->{email}, $form->{section}, '', '', $error_message);
			return;
		}

		for (keys %$form) {
			my $message = "";
			# run through filters
			if (! filterOk('submissions', $_, $form->{$_}, \$message)) {
				displayForm($form->{from}, $form->{email}, $form->{section}, '', '', $message);
				return;
			}
			# run through compress test
			if (! compressOk($form->{$_})) {
				my $err = getData('compresserror');
				displayForm($form->{from}, $form->{email}, $form->{section}, '', '');
				return;
			}
		}

		$form->{story} = strip_html(url2html($form->{story}));

		my $uid ||= $form->{from}
			? getCurrentUser('uid')
			: getCurrentStatic('anonymous_coward_uid');

		my $submission = {
			email	=> $form->{email},
			uid	=> $uid,
			name	=> $form->{from},
			story	=> $form->{story},
			subj	=> $form->{subj},
			tid	=> $form->{tid},
			section	=> $form->{section}
		};
		$submission->{subid} = $slashdb->createSubmission($submission);
		$slashdb->formSuccess($form->{formkey}, 0, length($form->{subj}));

		my $messages = getObject('Slash::Messages');
		if ($messages) {
			my $users = $messages->getMessageUsers(MSG_CODE_NEW_SUBMISSION);
			my $data  = {
				template_name	=> 'messagenew',
				subject		=> { template_name => 'messagenew_subj' },
				submission	=> $submission,
			};

			for (@$users) {
				$messages->create($_, MSG_CODE_NEW_SUBMISSION, $data);
			}
		}

		slashDisplay('saveSub', {
			title		=> 'Saving',
			width		=> '100%',
			missingemail	=> length($form->{email}) < 3,
			anonsubmit	=> length($form->{from}) < 3,
			submissioncount	=> $slashdb->getSubmissionCount(),
		});
	} else {
		print $err_message;
	}
}

#################################################################
sub processSub {
	my($home) = @_;

	my $proto = qr[^(?:mailto|http|https|ftp|gopher|telnet):];

	if ($home =~ /\@/ && $home !~ $proto) {
		$home = "mailto:$home";
	} elsif ($home ne '' && $home !~ $proto) {
		$home = "http://$home";
	}

	return $home;
}

#################################################################
sub url2html {
	my($introtext) = @_;
	$introtext =~ s/\n\n/\n<P>/gi;
	$introtext .= " ";

	# this is kinda experimental ... esp. the $extra line
	# we know it can break real URLs, but probably will preserve
	# real URLs more often than it will break them
	$introtext =~  s{(?<!["=>])(http|https|ftp|gopher|telnet)://([$URI::uric#]+)}{
		my($proto, $url) = ($1, $2);
		my $extra = '';
		$extra = $1 if $url =~ s/([?!;:.,']+)$//;
		$extra = ')' . $extra if $url !~ /\(/ && $url =~ s/\)$//;
		qq[<A HREF="$proto://$url">$proto://$url</A>$extra];
	}ogie;
	$introtext =~ s/\s+$//;
	return $introtext;
}

#################################################################
createEnvironment();
main();

1;
