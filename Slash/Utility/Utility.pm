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
use Digest::MD5 'md5_hex';
require Exporter;

@Slash::Utility::ISA = qw(Exporter);
@Slash::Utility::EXPORT = qw(
	addToMenu
	errorLog	
	stackTrace
	changePassword
	getDateFormat
	getDateOffset
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
	setCurrentUser
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
	stripByMode
);
$Slash::Utility::VERSION = '0.01';

# LEELA: We're going to deliver this crate like professionals.
# FRY: Aww, can't we just dump it in the sewer and say we delivered it?
# BENDER: Too much work!  I say we burn it, then *say* we dumped it in the sewer!


# These are package variables that are used when you need to use the
# set methods when not running under mod_perl
my($static_user, $static_form, $static_constants, $static_db,
	$static_anonymous_coward);

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

################################################################################
# SQL Timezone things
sub getDateOffset {
	my($col) = @_;
	my $offset = getCurrentUser('offset');
	return $col unless $offset;
	return " DATE_ADD($col, INTERVAL $offset SECOND) ";
}

sub getDateFormat {
	my($col, $as) = @_;
	$as = 'time' unless $as;
	my $user = getCurrentUser();

	$user->{'format'} ||= '%A %B %d, @%I:%M%p ';
	unless ($user->{tzcode}) {
		$user->{tzcode} = 'EDT';
		$user->{offset} = '-14400';
	}

	$user->{offset} ||= '0';
	return ' CONCAT(DATE_FORMAT(' . getDateOffset($col) .
		qq!,"$user->{'format'}")," $user->{tzcode}") as $as !;
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

		exttrans
		Similarly to 'literal', converts everything
		to its HTML entity, but then formatting is
		preserved by converting spaces to HTML
		space entities, and multiple newlines into BR
		tags.

		code
		Just like 'exttrans' but wraps in CODE tags.

		attribute
		Attempts to format string to fit in as an HTML
		attribute, which means the same thing as 'literal',
		but " marks are also converted to their HTML entity.

		plaintext
		Similar to 'exttrans', but does not translate < and >
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
	$fmode ||= 'nohtml';

	if ($fmode eq 'literal' || $fmode eq 'exttrans' || $fmode eq 'attribute' || $fmode eq 'code') {
		$str =~ s/(\S{90})/$1 /g unless $no_white_fix;
		# Encode all HTML tags
		$str =~ s/&/&amp;/g;
		$str =~ s/</&lt;/g;
		$str =~ s/>/&gt;/g;
	} elsif ($fmode eq 'plaintext') {
		$str = stripBadHtml($str, $no_white_fix);
	}

	if ($fmode eq 'plaintext' || $fmode eq 'exttrans' || $fmode eq 'code') {
		$str =~ s/\n/<BR>/gi;  # pp breaks
		$str =~ s/(?:<BR>\s*){2,}<BR>/<BR><BR>/gi;
		# Preserve leading indents / spaces
		$str =~ s/\t/    /g;
		if ($fmode eq 'code') {
			$str =~ s/ /&nbsp;/g;
			$str = '<CODE>' . $str . '</CODE>';
		} else {
			$str =~ s/<BR>\n?( +)/"<BR>\n" . ("&nbsp; " x length($1))/ieg;
		}

	} elsif ($fmode eq 'nohtml') {
		$str =~ s/<.*?>//g;
		$str =~ s/<//g;
		$str =~ s/>//g;
		$str =~ s/&/&amp;/g;

	} elsif ($fmode eq 'attribute') {
		$str =~ s/"/&#34;/g;

	} else {
		$str = stripBadHtml($str, $no_white_fix);
	}

	return $str;
}

########################################################
sub stripBadHtml  {
	my($str, $no_white_fix) = @_;

	$str =~ s/<(?!.*?>)//gs;
	$str =~ s/<(.*?)>/approveTag($1)/sge;

	$str =~ s/></> </g;

	$str =~ s/([^<>\s]{90})/$1 /g unless $no_white_fix;

	return $str;
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

	# RFC 2396
	my $mark = quotemeta(q"-_.!~*'()");
	my $alphanum = 'a-zA-Z0-9';
	my $unreserved = $alphanum . $mark;
	my $reserved = quotemeta(';|/?:@&=+$,');
	my $extra = quotemeta('%#');

	if ($parameter) {
		$url =~ s/([^$unreserved])/sprintf "%%%02X", ord $1/ge;
		return $url;
	} else {
		$url =~ s/[" ]//g;
		$url =~ s/^'(.+?)'$/$1/g;
		$url =~ s/([^$unreserved$reserved$extra])/sprintf "%%%02X", ord $1/ge;
		$url = fixHref($url) || $url;
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
	my $op = shift;
	my $dat = join("\t", @_);

	my $r = Apache->request;

	$r->notes('SLASH_LOG_OPERATION', $op);
	$r->notes('SLASH_LOG_DATA', $dat);
}

1;

=head1 AUTHOR

Brian Aker, brian@tangent.org

=head1 SEE ALSO

Slash(3).

=cut
