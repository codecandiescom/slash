package Slash::Utility;

=head1 NAME

Slash::Utility - Generic Perl routines for SlashCode

=head1 SYNOPSIS

  use Slash::Utility;

=head1 DESCRIPTION

Slash::Utility comprises methods that are safe
to call both within and without Apache. 

=head1 FUNCTIONS

Unless otherwise noted, they are publically available functions.

=over 4

=cut

use strict;
use Apache;
use Date::Manip;
use Digest::MD5 'md5_hex';
use HTML::Entities;
require Exporter;
use vars qw($REVISION $VERSION @ISA @EXPORT); # @EXPORT_OK %EXPORT_TAGS);

# $Id$
($REVISION)	= ' $Revision$ ' =~ /\$Revision:\s+([^\s]+)/;
($VERSION)	= $REVISION =~ /^(\d+\.\d+)/;

@ISA = qw(Exporter);
@EXPORT = qw(
	addToMenu
	errorLog	
	stackTrace
	changePassword
	getCurrentUser
	getCurrentForm
	getCurrentStatic
	getCurrentDB
	getCurrentMenu
	getCurrentAnonymousCoward
	createCurrentUser
	createCurrentForm
	createCurrentStatic
	createCurrentDB
	createCurrentAnonymousCoward
	createEnvironment
	formatDate
	timeCalc
	setCurrentUser
	setCurrentForm
	isAnon
	getAnonId
	getFormkey
	encryptPassword
	bakeUserCookie
	eatUserCookie
	setCookie
	writeLog
	fixparam
	fixurl
	chopEntity
	fixHref
	strip_mode
	strip_attribute
	strip_code
	strip_extrans
	strip_html
	strip_literal
	strip_nohtml
	strip_plaintext
	root2abs
	getCurrentSlashUser
);

# LEELA: We're going to deliver this crate like professionals.
# FRY: Aww, can't we just dump it in the sewer and say we delivered it?
# BENDER: Too much work!  I say we burn it, then *say* we dumped it in the sewer!

use constant ATTRIBUTE	=> -2;
use constant LITERAL	=> -1;
use constant NOHTML	=> 0;
use constant PLAINTEXT	=> 1;
use constant HTML	=> 2;
use constant EXTRANS	=> 3;
use constant CODE	=> 4;

# These are package variables that are used when you need to use the
# set methods when not running under mod_perl
my($static_user, $static_form, $static_constants, $static_db,
	$static_anonymous_coward);


sub root2abs {
	my($url) = @_;
	my $rootdir = getCurrentStatic('rootdir');
	if ($rootdir =~ m|^//|) {
		$rootdir = ($ENV{HTTPS} ? 'https:' : 'http:') . $rootdir;
	}
	return $rootdir;
}

#========================================================================

=item getAnonId()

Creates an anonymous ID that is used to set an AC cookie

Return value

  Returns a value generated by getFormkey() prepended with '-1-'.

=cut

sub getAnonId {
	return '-1-' . getFormkey();
}

#========================================================================

=item getFormkey()

Creates a random formkey (well, as random as random gets)

Return value

  Return a random value based on alphanumeric characters

=cut

sub getFormkey {
	my @rand_array = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 );
	return join("", map { $rand_array[rand @rand_array] }  0 .. 9);
}

#========================================================================

=item errorLog()

Generates an error that either goes to Apache's error log
or to STDERR. The error consists of the package and
and filename the error was generated and the same information
on the previous caller.

Return value

  Returns 0;

=cut

sub errorLog {
	my($package, $filename, $line) = caller(1);
	if ($ENV{GATEWAY_INTERFACE}) {
		my $r = Apache->request;
		if ($r) {
			$r->log_error("$ENV{SCRIPT_NAME}:$package:$filename:$line:@_");
			($package, $filename, $line) = caller(2);
			$r->log_error ("Which was called by:$package:$filename:$line:@_\n");

			return 0;
		}
	} 
	print STDERR ("Error in library:$package:$filename:$line:@_\n");
	($package, $filename, $line) = caller(2);
	print STDERR ("Which was called by:$package:$filename:$line:@_\n");
	
	return 0;
}


sub formatDate {
	my($data, $col, $as, $format) = @_;
	errorLog("Not arrayref"), return unless ref($data) eq 'ARRAY';

	if ($col && $col =~ /^\d+$/) {   # LoL
		$as = defined($as) ? $as : $col;
		for (@$data) {
			errorLog("Not arrayref"), return unless ref($_) eq 'ARRAY';
			$_->[$as] = timeCalc($_->[$col], $format);
		}
	} else {
		$col ||= 'date';
		$as  ||= 'time';
		for (@$data) {
			errorLog("Not hashref"), return unless ref($_) eq 'HASH';
			$_->{$as} = timeCalc($_->{$col}, $format);
		}
	}
}


#========================================================================

=item timeCalc(DATE)

Format time strings.

Parameters

	DATE
	Raw date from database.

Return value

	Formatted date string.

Dependencies

	The 'atonish' and 'aton' template blocks.

=cut

#######################################################################
# timeCalc 051100 PMG 
# Removed timeformats hash and updated table to have perl formats 092000 PMG 
# inputs: raw date from database
# returns: formatted date string from dateformats converted to
# time strings that Date::Manip can format
#######################################################################
sub timeCalc {
	# raw mysql date of story
	my($date, $format) = @_;
	my $user = getCurrentUser();
	my(@dateformats, $err);

	# I put this here because
	# when they select "6 ish" it
	# looks really stupid for it to
	# display "posted by xxx on 6 ish"
	# It looks better for it to read:
	# "posted by xxx around 6 ish"

	# this needs to be elsewhere, so it can be done once, and
	# access slashDisplay(); stay here for now -- pudge
	if ($user->{'format'} eq '%i ish') {
		$user->{aton} = 'around'; # getData('atonish');
	} else {
		$user->{aton} = 'on'; # getData('aton');
	}

	# find out the user's time based on personal offset
	# in seconds
	$date = DateCalc($date, "$user->{offset} SECONDS", \$err);

	# convert the raw date to pretty formatted date
	$date = UnixDate($date, $format || $user->{'format'});

	# return the new pretty date
	return $date;
}

#################################################################
# This may get moved
sub changePassword {
	my @chars = grep !/[0O1Iil]/, 0..9, 'A'..'Z', 'a'..'z';
	return join '', map { $chars[rand @chars] } 0 .. 7;
}

#################################################################
sub addToMenu {
	my($menu, $name, $data) = @_;
	my $user = getCurrentUser();

	return unless ref $data eq 'HASH';

	my $menus = getCurrentMenu($menu);
	$data->{menuorder} = @$menus;

	$user->{menus}{$menu}{$name} = $data;
}

#========================================================================

=item getCurrentMenu(NAME)

Returns the menu for the resource requested

Parameters

	NAME
	Name of the menu that you want to fetch.

Return value

	A reference to an array with the menu in it, is returned.

=cut

sub getCurrentMenu {
	my($menu) = @_;
	my $user = getCurrentUser();

	unless ($menu) {
		($menu = $ENV{SCRIPT_NAME}) =~ s/\.pl$//;
	}

	my $r = Apache->request;
	my $cfg = Apache::ModuleConfig->get($r, 'Slash::Apache');
	my @menus = @{$cfg->{menus}{$menu}};

	if (my $user_menu = $user->{menus}{$menu}) {
		push @menus, values %$user_menu;
	}

	return \@menus;
}

#========================================================================

=item getCurrentUser(MEMBER)

Returns the current authenicated user.

Parameters

	MEMBER
	A member from the users record to be returned.

Return value

	A hash reference with the user information is returned unless VALUE is passed. If 
	MEMBER is passed in then only its value will be returned.

=cut

sub getCurrentUser {
	my($value) = @_;
	my $user;

	if ($ENV{GATEWAY_INTERFACE}) {
		my $r = Apache->request;
		$user = $r->pnotes('user');
	} else {
		$user = $static_user;
	}

	# i think we want to test defined($foo), not just $foo, right?
	if ($value) {
		return defined($user->{$value})
			? $user->{$value}
			: undef;
	} else {
		return $user;
	}
}

#========================================================================

=item setCurrentUser(MEMBER, VALUE)

Sets a value for the current user (it will not be permanently stored)

Parameters

	MEMBER
	The member to store VALUE in.

	VALUE
	VALUE to be stored in the current user hash. 

Return value

	A hash reference with the user information is returned unless VALUE is passed. If 
	MEMBER is passed in then only its value will be returned.

=cut

sub setCurrentUser {
	my($key, $value) = @_;
	my $user;

	if ($ENV{GATEWAY_INTERFACE}) {
		my $r = Apache->request;
		$user = $r->pnotes('user');
	} else {
		$user = $static_user;
	}

	$user->{$key} = $value;
}

#========================================================================

=item setCurrentForm(MEMBER, VALUE)

Sets a value for the current user (it will not be permanently stored)

Parameters

	MEMBER
	The member to store VALUE in.

	VALUE
	VALUE to be stored in the current user hash. 

Return value

	A hash reference with the user information is returned unless VALUE is passed. If 
	MEMBER is passed in then only its value will be returned.

=cut

sub setCurrentForm {
	my($key, $value) = @_;
	my $form;

	if ($ENV{GATEWAY_INTERFACE}) {
		my $r = Apache->request;
		$form = $r->pnotes('form');
	} else {
		$form = $static_form;
	}

	$form->{$key} = $value;
}

#========================================================================

=item createCurrentUser(USER)

Creates the current user.

Parameters

	USER
	USER to be inserted into current user.

Return value

	Returns no value.

=cut

sub createCurrentUser {
	my($user) = @_;

	if ($ENV{GATEWAY_INTERFACE}) {
		my $r = Apache->request;
		$r->pnotes('user', $user);
	} else {
		$static_user = $user;
	}
}

#========================================================================

=item getCurrentForm(MEMBER)

Returns the current form.

Parameters

	MEMBER
	A member from the forms record to be returned.

Return value

	A hash reference with the form information is returned unless VALUE is passed. If 
	MEMBER is passed in then only its value will be returned.

=cut


sub getCurrentForm {
	my($value) = @_;
	my $form;

	if ($ENV{GATEWAY_INTERFACE}) {
		my $r = Apache->request;
		$form = $r->pnotes('form');
	} else {
		$form = $static_form;
	}

	if ($value) {
		return defined($form->{$value})
			? $form->{$value}
			: undef;
	} else {
		return $form;
	}
}

#========================================================================

=item createCurrentForm(FORM)

Creates the current form.

Parameters

	FORM
	FORM to be inserted into current form.

Return value

	Returns no value.

=cut

sub createCurrentForm {
	my($form) = @_;

	if ($ENV{GATEWAY_INTERFACE}) {
		my $r = Apache->request;
		$r->pnotes('form', $form);
	} else {
		$static_form = $form;
	}
}

#========================================================================

=item getCurrentStatic(MEMBER)

Returns the current form.

Parameters

	MEMBER
	A member from the static record to be returned.

Return value

	A hash reference with the satic information is returned unless MEMBER is passed. If 
	MEMBER is passed in then only its value will be returned.

=cut

sub getCurrentStatic {
	my($value) = @_;
	my $constants;

	if ($ENV{GATEWAY_INTERFACE}) {
		my $r = Apache->request;
		my $const_cfg = Apache::ModuleConfig->get($r, 'Slash::Apache');
		$constants = $const_cfg->{'constants'};
	} else {
		$constants = $static_constants;
	}

	if ($value) {
		return defined($constants->{$value})
			? $constants->{$value}
			: undef;
	} else {
		return $constants;
	}
}

#========================================================================

=item createCurrentStatic(HASH)

Creates the current static information for non Apache scripts.

Parameters

	HASH
	A hash that is to be used in scripts not running in Apache to simulate a 
	script running under Apache.

Return value

	Returns no value.

=cut

sub createCurrentStatic {
	($static_constants) = @_;
}

#################################################################
sub getCurrentAnonymousCoward {
	my($value) = @_;

	if ($ENV{GATEWAY_INTERFACE}) {
		my $r = Apache->request;
		my $const_cfg = Apache::ModuleConfig->get($r, 'Slash::Apache');
		if ($value) {
			return $const_cfg->{'anonymous_coward'}{$value};
		} else {
			my %coward = %{$const_cfg->{'anonymous_coward'}};
			return \%coward;
		}
	} else {
		if ($value) {
			return $static_anonymous_coward->{$value};
		} else {
			my %coward = %{$static_anonymous_coward};
			return \%coward;
		}
	}
}

#========================================================================

=item getCurrentSlashUser()

Returns the current slash user

Return value

	Returns the current slash user

=cut

sub getCurrentSlashUser {
	my $slashdb;

	my $r = Apache->request;
	my $const_cfg = Apache::ModuleConfig->get($r, 'Slash::Apache');
	my $user = $const_cfg->{VirtualUser};

	return $user;
}
#========================================================================

=item createCurrentAnonymousCoward(HASH)

Creates the current anonymous coward for non Apache scripts.

Parameters

	HASH
	A hash that is to be used in scripts not running in Apache to simulate a 
	script running under Apache.

Return value

	Returns no value.

=cut

sub createCurrentAnonymousCoward {
	($static_anonymous_coward) = @_;
}

#========================================================================

=item getCurrentDB()

Returns the current Slash::DB object

Return value

	Returns the current Slash::DB object

=cut

sub getCurrentDB {
	my $slashdb;

	if ($ENV{GATEWAY_INTERFACE}) {
		my $r = Apache->request;
		my $const_cfg = Apache::ModuleConfig->get($r, 'Slash::Apache');
		$slashdb = $const_cfg->{slashdb};
	} else {
		$slashdb = $static_db;
	}

	return $slashdb;
}

#========================================================================

=item createCurrentDB(SLASHDB)

Creates the current DB object for scripts not running under Apache.

Parameters

	SLASHDB
	Pass in a Slash::DB object to be used for scripts not running 
	in Apache.

Return value

	Returns no value.

=cut

sub createCurrentDB {
	($static_db) = @_;
}

#========================================================================

=item isAnon(UID)

Tests to see if the uid passed in is an anonymous coward.

Parameters

	UID
	Value UID.

Return value

	Returns true if the UID is an anonymous coward, otherwise false.

=cut

sub isAnon {
	my($uid) = @_;
	return $uid == getCurrentStatic('anonymous_coward_uid');
}

#################################################################
# do the MD5 thang (could use other method in the future)
sub encryptPassword {
	my($passwd) = @_;
	return md5_hex($passwd);
}

#################################################################
# create a user cookie from ingredients
sub bakeUserCookie {
	my($uid, $passwd) = @_;
	my $cookie = $uid . '::' . $passwd;
	$cookie =~ s/(.)/sprintf("%%%02x", ord($1))/ge;
	return $cookie;
}

#################################################################
# digest a user cookie, returning it back to its original ingredients
sub eatUserCookie {
	my($cookie) = @_;
	$cookie =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack('C', hex($1))/ge;
	my($uid, $passwd) = split(/::/, $cookie, 2);
	return($uid, $passwd);
}

#========================================================================

=item setCookie(NAME, VALUE, SESSION)

Creates a cookie and places it into the outbound headers.

Parameters

	NAME
	NAme of the cookie.

	VALUE
	Value to be placed in the cookie.

	SESSION
	Flag to determine if the cookie should be a session cookie.
	

Return value

	No value is returned.

=cut

# In the future a secure flag should be set on 
# the cookie for admin users. -- brian
# well, it should be an option, of course ... -- pudge
sub setCookie {
	# for some reason, we need to pass in $r, because Apache->request
	# was returning undef!  ack! -- pudge
	my($name, $val, $session) = @_;
	return unless $name;

	# no need to getCurrent*, only works under Apache anyway
	my $r = Apache->request;
	my $dbcfg = Apache::ModuleConfig->get($r, 'Slash::Apache');
	my $constants = $dbcfg->{constants};

	# We need to actually determine domain from preferences,
	# not from the server.  ask me why. -- pudge
	my $cookiedomain = $constants->{cookiedomain};
	my $cookiepath = $constants->{cookiepath};
	my $cookiesecure = 0;

	# domain must start with a '.' and have one more '.'
	# embedded in it, else we ignore it
 	my $domain = ($cookiedomain && $cookiedomain =~ /^\..+\./)
 		? $cookiedomain
 		: '';

	my %cookie = (
		-name	=> $name,
		-path	=> $cookiepath,
		-value	=> $val || '',
		-secure	=> $cookiesecure,
	);

	$cookie{-expires} = '+1y' unless $session;
 	$cookie{-domain}  = $domain if $domain;

	my $bakedcookie = CGI::Cookie->new(\%cookie);

	# we need to support multiple cookies, like my tummy does
	$r->err_headers_out->add('Set-Cookie' => $bakedcookie);
}

#========================================================================

=item stripByMode(STRING [, MODE, NO_WHITESPACE_FIX ])

Fixes up a string based on what the mode is.

[ Should this be somewhat templatized, so they can customize
the little HTML bits? Same goes with related functions. -- pudge ]

Parameters

	STRING
	The string to be manipulated.

	MODE
	May be one of:

		nohtml
		The default.  Just strips out HTML.

		literal
		Prints the text verbatim into HTML, which
		means just converting < and > and & to their
		HTML entities.

		extrans
		Similarly to 'literal', converts everything
		to its HTML entity, but then formatting is
		preserved by converting spaces to HTML
		space entities, and multiple newlines into BR
		tags.

		code
		Just like 'extrans' but wraps in CODE tags.

		attribute
		Attempts to format string to fit in as an HTML
		attribute, which means the same thing as 'literal',
		but " marks are also converted to their HTML entity.

		plaintext
		Similar to 'extrans', but does not translate < and >
		and & first (so C<stripBadHtml> is called first).

		html (or anything else)
		Just runs through C<stripBadHtml>.

		NO_WHITESPACE_FIX
		A boolean that, if true, disables fixing of whitespace
		problems.  A common exploit in these things is to
		run a lot of characters together so the page will
		stretch very wide.  If NO_WHITESPACE_FIX is false,
		then a space is inserted for every 90 consecutive
		non-whitespace characters.

Return value

	The manipulated string.


=cut

sub stripByMode {
	my($str, $fmode, $no_white_fix) = @_;
	$fmode ||= NOHTML;
	$no_white_fix = defined($no_white_fix) ? $no_white_fix : $fmode == LITERAL;

	# insert whitespace into long words, convert <>& to HTML entities
	if ($fmode == LITERAL || $fmode == EXTRANS || $fmode == ATTRIBUTE || $fmode == CODE) {
		$str = breakHtml($str) unless $no_white_fix;
		# Encode all HTML tags
		$str =~ s/&/&amp;/g;
		$str =~ s/</&lt;/g;
		$str =~ s/>/&gt;/g;
	} elsif ($fmode == PLAINTEXT) {
		$str = stripBadHtml($str);
		$str = breakHtml($str) unless $no_white_fix;
	}

	# convert regular text to HTML-ized text, insert P, etc.
	if ($fmode == PLAINTEXT || $fmode == EXTRANS || $fmode == CODE) {
		$str =~ s/\n/<BR>/gi;  # pp breaks
		$str =~ s/(?:<BR>\s*){2,}<BR>/<BR><BR>/gi;
		# Preserve leading indents / spaces
		$str =~ s/\t/    /g;
		if ($fmode == CODE) {
			$str =~ s/ /&nbsp;/g;
			$str = '<CODE>' . $str . '</CODE>';
		} else {
			$str =~ s/<BR>\n?( +)/"<BR>\n" . ("&nbsp; " x length($1))/ieg;
		}

	# strip out all HTML
	} elsif ($fmode == NOHTML) {
		$str =~ s/<.*?>//g;
		$str =~ s/<//g;
		$str =~ s/>//g;
		$str =~ s/&/&amp;/g;

	# convert HTML attribute to allowed text (just convert ")
	} elsif ($fmode == ATTRIBUTE) {
		$str =~ s/"/&#34;/g;

	# probably 'html'
	} else {
		$str = stripBadHtml($str);
		$str = breakHtml($str) unless $no_white_fix;
	}

	return $str;
}

sub strip_mode {
	my($string, $mode, @args) = @_;

	# note that user-supplied modes are all > 0, so
	# we only allow modes to use this function that are
	# greater than 0, all others must be called via their
	# function names directly (literal, attribute, nohtml)

	$mode ||= 0;
	return if $mode < 1;	# user-supplied modes > 0
	return stripByMode($string, $mode, @args);
}

sub strip_attribute	{ stripByMode($_[0], ATTRIBUTE,	@_[1 .. $#_]) }
sub strip_code		{ stripByMode($_[0], CODE,	@_[1 .. $#_]) }
sub strip_extrans	{ stripByMode($_[0], EXTRANS,	@_[1 .. $#_]) }
sub strip_html		{ stripByMode($_[0], HTML,	@_[1 .. $#_]) }
sub strip_literal	{ stripByMode($_[0], LITERAL,	@_[1 .. $#_]) }
sub strip_nohtml	{ stripByMode($_[0], NOHTML,	@_[1 .. $#_]) }
sub strip_plaintext	{ stripByMode($_[0], PLAINTEXT,	@_[1 .. $#_]) }


########################################################
sub stripBadHtml  {
	my($str, $no_white_fix) = @_;

	$str =~ s/<(?!.*?>)//gs;
	$str =~ s/<(.*?)>/approveTag($1)/sge;
	$str =~ s/></> </g;

	return $str;
}

########################################################
{
	my %is_break_tag;

	sub breakHtml {
		my($comment, $mwl) = @_;
		my($new, $l, $c, $in_tag, $this_tag, $cwl);

		$mwl = $mwl || 50;
		$l = length($comment);

		%is_break_tag = map { uc, 1 } qw(HR BR LI P OL UL BLOCKQUOTE DIV)
			unless scalar keys %is_break_tag;

		for (my $i = 0; $i < $l; $new .= $c, ++$i) {
			$c = substr($comment, $i, 1);
			if ($c eq '<')		{ $in_tag = 1 }
			elsif ($c eq '>')	{
				$in_tag = 0;
				$this_tag =~ s{^/?(\S+).*}{\U$1};
				$cwl = 0 if $is_break_tag{$this_tag};
				$this_tag = '';
			}
			elsif ($in_tag)		{ $this_tag .= $c }
			elsif ($c =~ /\s/)	{ $cwl = 0 }
			elsif (++$cwl > $mwl)	{ $new .= ' '; $cwl = 1 }
		}

		return $new;
	}
}

########################################################
sub fixHref {  # I don't like this.  we need to change it. -- pudge
	my($rel_url, $print_errs) = @_;
	my $abs_url; # the "fixed" URL
	my $errnum; # the errnum for 404.pl

	my $fixhrefs = getCurrentStatic('fixhrefs');
	for my $qr (@{$fixhrefs}) {
		if ($rel_url =~ $qr->[0]) {
			my @ret = $qr->[1]->($rel_url);
			return $print_errs ? @ret : $ret[0];
		}
	}

	my $rootdir = getCurrentStatic('rootdir');
	if ($rel_url =~ /^www\.\w+/) {
		# errnum 1
		$abs_url = "http://$rel_url";
		return($abs_url, 1) if $print_errs;
		return $abs_url;

	} elsif ($rel_url =~ /^ftp\.\w+/) {
		# errnum 2
		$abs_url = "ftp://$rel_url";
		return ($abs_url, 2) if $print_errs;
		return $abs_url;

	} elsif ($rel_url =~ /^[\w\-\$\.]+\@\S+/) {
		# errnum 3
		$abs_url = "mailto:$rel_url";
		return ($abs_url, 3) if $print_errs;
		return $abs_url;

	} elsif ($rel_url =~ /^articles/ && $rel_url =~ /\.shtml$/) {
		# errnum 6
		my @chunks = split m|/|, $rel_url;
		my $file = pop @chunks;

		if ($file =~ /^98/ || $file =~ /^0000/) {
			$rel_url = "$rootdir/articles/older/$file";
			return ($rel_url, 6) if $print_errs;
			return $rel_url;
		} else {
			return;
		}

	} elsif ($rel_url =~ /^features/ && $rel_url =~ /\.shtml$/) {
		# errnum 7
		my @chunks = split m|/|, $rel_url;
		my $file = pop @chunks;

		if ($file =~ /^98/ || $file =~ /~00000/) {
			$rel_url = "$rootdir/features/older/$file";
			return ($rel_url, 7) if $print_errs;
			return $rel_url;
		} else {
			return;
		}

	} elsif ($rel_url =~ /^books/ && $rel_url =~ /\.shtml$/) {
		# errnum 8
		my @chunks = split m|/|, $rel_url;
		my $file = pop @chunks;

		if ($file =~ /^98/ || $file =~ /^00000/) {
			$rel_url = "$rootdir/books/older/$file";
			return ($rel_url, 8) if $print_errs;
			return $rel_url;
		} else {
			return;
		}

	} elsif ($rel_url =~ /^askslashdot/ && $rel_url =~ /\.shtml$/) {
		# errnum 9
		my @chunks = split m|/|, $rel_url;
		my $file = pop @chunks;

		if ($file =~ /^98/ || $file =~ /^00000/) {
			$rel_url = "$rootdir/askslashdot/older/$file";
			return ($rel_url, 9) if $print_errs;
			return $rel_url;
		} else {
			return;
		}

	} else {
		# if we get here, we don't know what to
		# $abs_url = $rel_url;
		return;
	}

	# just in case
	return $abs_url;
}

########################################################
sub approveTag {
	my($tag) = @_;

	$tag =~ s/^\s*?(.*)\s*?$/$1/; # trim leading and trailing spaces
	$tag =~ s/\bstyle\s*=(.*)$//i; # go away please

	# Take care of URL:foo and other HREFs
	if ($tag =~ /^URL:(.+)$/i) {
		my $url = fixurl($1);
		return qq!<A HREF="$url">$url</A>!;
	} elsif ($tag =~ /href\s*=(.+)$/i) {
		my $url = fixurl($1);
		return qq!<A HREF="$url">!;
	}

	# Validate all other tags
	my $approvedtags = getCurrentStatic('approvedtags');
	$tag =~ s|^(/?\w+)|\U$1|;
	foreach my $goodtag (@$approvedtags) {
		return "<$tag>" if $tag =~ /^$goodtag$/ || $tag =~ m|^/$goodtag$|;
	}
}

#========================================================================

=item fixparam(DATA)

Prepares data to be a parameter in a URL.  Such as:

	my $url = 'http://example.com/foo.pl?bar=' . fixparam($data);

Function actually calls C<fixurl(DATA, 1)>.

Parameters

	DATA
	The data to be escaped.

Return value

	The escaped data.

=cut

sub fixparam {
	fixurl($_[0], 1);
}

#========================================================================

=item fixurl(DATA [, PARAM])

Prepares data to be a URL.  Such as:

	my $url = fixparam($someurl);

Parameters

	DATA
	The data to be escaped.

	PARAM
	Boolean for whether DATA is a whole URL, or just parameter
	data for a URL, for use like:

		my $url = 'http://example.com/foo.pl?bar=' . fixurl($data, 1);

	It is normally best to, instead of calling fixurl(DATA, 1), call
	fixparam(DATA).

Return value

	The escaped data.

=cut

sub fixurl {
	my($url, $parameter) = @_;

	if ($parameter) {
		$url =~ s/([^$URI::unreserved])/$URI::Escape::escapes{$1}/oge;
		return $url;
	} else {
		$url =~ s/[" ]//g;
		# strip surrounding ' if exists
		$url =~ s/^'(.+?)'$/$1/g;
		# add '#' to allowed characters
		$url =~ s/([^$URI::uric#])/$URI::Escape::escapes{$1}/oge;
		$url = fixHref($url) || $url;

		# we don't like SCRIPT a the beginning of a URL
		my $decoded_url = decode_entities($url);
		return $decoded_url =~ s|^\s*\w+script\b.*$||i ? undef : $url;
	}
}

########################################################
sub chopEntity {
	my($text, $length) = @_;
	$text = substr($text, 0, $length) if $length;
	$text =~ s/&#?[a-zA-Z0-9]*$//;
	return $text;
}

#========================================================================

=item writeLog(OP, LIST)

Places data into the request records notes table. The two keys
it uses are SLASH_LOG_OPERATION and SLASH_LOG_DATA. 

Parameters

	OP
	The operation code for this entry (is stored in SLASH_LOG_OPERATION).

	LIST
	Strings that are concatenated together to be used in the SLASH_LOG_DATA field.

Return value

	No value is returned.

=cut

sub writeLog {
	return unless $ENV{GATEWAY_INTERFACE};
	my $op = shift;
	my $dat = join("\t", @_);

	my $r = Apache->request;

	$r->notes('SLASH_LOG_OPERATION', $op);
	$r->notes('SLASH_LOG_DATA', $dat);
}

#========================================================================

=item createEnvironment(LIST|DBIx::Password_virtual_user)

Places data into the request records notes table. The two keys
it uses are SLASH_LOG_OPERATION and SLASH_LOG_DATA. 

Parameters

	DBIx::Password_virtual_user
	You can pass in a virtual user that will be used instead of ARGV[0]

Return value

	No value is returned.

=cut

sub createEnvironment {
	return if ($ENV{GATEWAY_INTERFACE});
	my ($virtual_user) = @_;
	my %form;
	unless($virtual_user) {
		for(@ARGV) {
			my ($key, $val) = split /=/;
			$form{$key} = $val;
		}
		$virtual_user = $form{'virtual_user'};
	}
	createCurrentForm(\%form);

	my $slashdb = Slash::DB->new($virtual_user);
	my $constants = $slashdb->getSlashConf();

	# We assume that the user for scripts is the anonymous user
	my $user = $slashdb->getUser($constants->{anonymous_coward_uid});
	createCurrentDB($slashdb);
	createCurrentStatic($constants);
	createCurrentUser($user);
	createCurrentAnonymousCoward($user);
}

1;

=head1 AUTHOR

Brian Aker, brian@tangent.org

=head1 SEE ALSO

Slash(3).

=cut
