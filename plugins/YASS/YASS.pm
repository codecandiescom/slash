# This code is a part of Slash, and is released under the GPL.
# Copyright 1997-2002 by Open Source Development Network. See README
# and COPYING for more information, or see http://slashcode.com/.
# $Id$

package Slash::YASS;

use strict;
use Slash;
use Slash::Utility;
use Slash::DB::Utility;

use vars qw($VERSION @EXPORT);
use base 'Slash::DB::Utility';
use base 'Slash::DB::MySQL';

($VERSION) = ' $Revision$ ' =~ /\$Revision:\s+([^\s]+)/;

sub new {
	my($class, $user) = @_;
	my $self = {};

	my $slashdb = getCurrentDB();
	my $plugins = $slashdb->getDescriptions('plugins');
	return unless $plugins->{'YASS'};

	bless($self, $class);
	$self->{virtual_user} = $user;
	$self->sqlConnect;

	return $self;
}

sub getActive {
	my ($self, $limit) = @_;

	my $all;

	unless($limit) {
		$all = $self->sqlSelectAllHashrefArray(
			"story_param.sid as sid, story_param.url as url, title", 
			"story_param, stories", 
			"name = 'active' AND value = 'yes' AND stories.sid = story_param.sid",
			"ORDER BY title");
	} else {
		$all = $self->sqlSelectAllHashrefArray(
			"story_param.sid as sid, story_param.url as url, title", 
			"story_param, stories", 
			"name = 'active' AND value = 'yes' AND stories.sid = story_param.sid",
			"ORDER BY date DESC DESC LIMIT $limit");
	}

	return $all;
}

sub DESTROY {
	my($self) = @_;
	$self->{_dbh}->disconnect if !$ENV{GATEWAY_INTERFACE} && $self->{_dbh};
}


1;

__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Slash::YASS - YASS system splace

=head1 SYNOPSIS

	use Slash::YASS;

=head1 DESCRIPTION

This is YASS, and just how useful is this to you? Its 
a site link system.

Blah blah blah.

=head1 AUTHOR

Brian Aker, brian@tangent.org

=head1 SEE ALSO

perl(1).

=cut
