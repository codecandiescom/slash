# This code is a part of Slash, and is released under the GPL.
# Copyright 1997-2001 by Open Source Development Network. See README
# and COPYING for more information, or see http://slashcode.com/.
# $Id$

package Slash::Messages::DB::MySQL;

=head1 NAME

Slash::Messages - Send messages for Slash


=head1 SYNOPSIS

	# basic example of usage

=head1 DESCRIPTION

LONG DESCRIPTION.

=cut

use strict;
use Slash::DB;
use Slash::DB::Utility;
use Slash::Utility;
use Storable qw(freeze thaw);

use vars '$VERSION';
use base 'Slash::DB::Utility';
use base 'Slash::DB::MySQL';

($VERSION) = ' $Revision$ ' =~ /\$Revision:\s+([^\s]+)/;

my %descriptions = (
	'deliverymodes'
		=> sub { $_[0]->sqlSelectMany('code,name', 'code_param', "type='deliverymodes'") },
	'messagecodes'
		=> sub { $_[0]->sqlSelectMany('code,name', 'code_param', "type='messagecodes'") },
);

sub getDescriptions {
	my($self, $codetype, $optional, $flag) =  @_;
	# handle in Slash::DB::MySQL (or whatever)
	return $self->SUPER::getDescriptions($codetype, $optional, $flag, \%descriptions);
}

sub init {
	my($self, @args) = @_;
	$self->{_drop_table} = 'message_drop';
	$self->{_drop_cols}  = 'id,user,code,message,fuser,altto,date';
	$self->{_drop_prime} = 'id';
	$self->{_drop_store} = 'message';

	$self->{_web_table}  = 'message_web, message_web_text';
	$self->{_web_table1} = 'message_web';
	$self->{_web_table2} = 'message_web_text';
	$self->{_web_cols}   = 'message_web.id,user,code,message,fuser,readed,date,subject';
	$self->{_web_prime}  = 'message_web.id=message_web_text.id AND message_web.id';
	$self->{_web_prime1} = 'id';
	$self->{_web_prime2} = 'id';
}

sub _create_web {
	my($self, $user, $code, $message, $fuser, $id, $subject, $date) = @_;
	my $table1 = $self->{_web_table1};
	my $table2 = $self->{_web_table2};

	# fix scalar to be a ref for freezing
	$self->sqlInsert($table1, {
		id	=> $id,
		user	=> $user,
		fuser	=> $fuser,
		code	=> $code,
		date	=> $date,
	});

	$self->sqlInsert($table2, {
		id	=> $id,
		subject	=> $subject,
		message	=> $message,
	});

	return $id;
}

sub _create {
	my($self, $user, $code, $message, $fuser, $altto) = @_;
	my $table = $self->{_drop_table};
	my $prime = $self->{_drop_prime};

	# fix scalar to be a ref for freezing
	my $frozen = freeze(ref $message ? $message : \$message);
	$self->sqlInsert($table, {
		user	=> $user,
		fuser	=> $fuser,
		altto	=> $altto || '',
		code	=> $code,
		message	=> $frozen,
	});

	my($msg_id) = $self->getLastInsertId($table, $prime);
	return $msg_id;
}

sub _get_web {
	my($self, $msg_id) = @_;
	my $table = $self->{_web_table};
	my $cols  = $self->{_web_cols};
	my $prime = $self->{_web_prime};

	my $id_db = $self->sqlQuote($msg_id);
	my $data  = $self->sqlSelectHashref($cols, $table, "$prime=$id_db");

	$table    = $self->{_web_table1};
	$prime    = $self->{_web_prime1};
	$self->sqlUpdate($table, { readed => 1 }, "$prime=$id_db");

	return $data;
}

sub _get_web_by_uid {
	my($self, $uid) = @_;
	my $table = $self->{_web_table};
	my $cols  = $self->{_web_cols};
	my $prime = "message_web.id=message_web_text.id AND user";
	my $other = "ORDER BY date ASC";

	my $id_db = $self->sqlQuote($uid);
	my $data = $self->sqlSelectAllHashrefArray(
		$cols, $table, "$prime=$id_db", $other
	);
	return $data;
}

sub _get {
	my($self, $msg_id) = @_;
	my $table = $self->{_drop_table};
	my $cols  = $self->{_drop_cols};
	my $prime = $self->{_drop_prime};

	my $id_db = $self->sqlQuote($msg_id);

	my $data = $self->sqlSelectHashref($cols, $table, "$prime=$id_db");

	$self->_thaw($data);
	return $data;
}

sub _gets {
	my($self, $count, $delete) = @_;
	my $table = $self->{_drop_table};
	my $cols  = $self->{_drop_cols};

	$count = 1 if $count =~ /\D/;
	my $other = "ORDER BY date ASC";
	$other .= " LIMIT $count" if $count;

	my $all = $self->sqlSelectAllHashrefArray(
		$cols, $table, '', $other
	);

	for my $data (@$all) {
		$self->_thaw($data);
	}

	return $all;
}

sub _thaw {
	my($self, $data) = @_;
	my $store = $self->{_drop_store};
	$data->{$store} = thaw($data->{$store});
	# return scalar as scalar, not ref
	$data->{$store} = ${$data->{$store}} if ref($data->{$store}) eq 'SCALAR';
}

sub _delete_web {
	my($self, $id, $uid, $override) = @_;
	my $table1 = $self->{_web_table1};
	my $prime1 = $self->{_web_prime1};
	my $table2 = $self->{_web_table2};
	my $prime2 = $self->{_web_prime2};

	my $id_db = $self->sqlQuote($id);
	my $where1 = "$prime1=$id_db";
	my $where2 = "$prime1=$id_db";

	unless ($override) {
		$uid ||= $ENV{SLASH_USER};
		return 0 unless $uid;
		my $uid_db = $self->sqlQuote($uid);
		my $where  = $where1 . " AND user=$uid_db";
		my($check) = $self->sqlSelect('user', $table1, $where);
		return 0 unless $check eq $uid;
	}

	$self->sqlDo("DELETE FROM $table1 WHERE $where1");
	$self->sqlDo("DELETE FROM $table2 WHERE $where2");
	return 1;
}

sub _delete {
	my($self, $id) = @_;
	my $table = $self->{_drop_table};
	my $prime = $self->{_drop_prime};
	my $id_db = $self->sqlQuote($id);
	my $where = "$prime=$id_db";

	$self->sqlDo("DELETE FROM $table WHERE $where");
}

sub _delete_all {
	my($self) = @_;
	my $table = $self->{_drop_table};

	# this will preserve auto_increment count
	$self->sqlDo("DELETE FROM $table WHERE 1=1");
}

sub _getMailingUsers {
	my($self, $code) = @_;
	return unless $code =~ /^-?\d+$/;
	my $cols  = "nickname,users.uid";
	my $table = "users,users_comments,users_info,users_param";
	my $where = "users.uid=users_comments.uid AND users.uid=users_info.uid AND " .
		"users.uid=users_param.uid AND users_param.name='messagecodes_$code' AND " .
		"users_param.value=1";

	my $users = $self->sqlSelectAll($cols, $table, $where);
	return $users;
}

1;

__END__

