CREATE TABLE abusers (
  abuser_id SERIAL,
  host_name varchar(25) DEFAULT '' NOT NULL,
  pagename varchar(20) DEFAULT '' NOT NULL,
  ts datetime  DEFAULT '1970-01-01 00:00:00' NOT NULL,
  reason varchar(120) DEFAULT '' NOT NULL,
  querystring varchar(60) DEFAULT '' NOT NULL,
  PRIMARY KEY (abuser_id),
  UNIQUE (host_name),
  UNIQUE (reason)
);




CREATE TABLE accesslog (
  id SERIAL,
  host_addr varchar(16) DEFAULT '' NOT NULL,
  op varchar(8),
  dat varchar(32),
  uid int NOT NULL,
  ts datetime DEFAULT '1970-01-01 00:00:00' NOT NULL,
  query_string varchar(50),
  user_agent varchar(50),
  PRIMARY KEY (id)
);




CREATE TABLE authors (
  aid char(30) DEFAULT '' NOT NULL,
  name char(50),
  url char(50),
  email char(50),
  quote char(50),
  description char(255),
  pwd char(8),
  seclev int4,
  lasttitle char(20),
  section char(20),
  deletedsubmissions int4 DEFAULT '0',
  matchname char(30),
  PRIMARY KEY (aid)
);




CREATE TABLE blocks (
  bid varchar(30) DEFAULT '' NOT NULL,
  block text,
  aid varchar(20),
  seclev int2,
  type varchar(20) DEFAULT '' NOT NULL,
  description text,
  blockbak text,
  section varchar(30) DEFAULT '' NOT NULL,
  ordernum int2 DEFAULT '0',
  title varchar(128),
  portal int2 DEFAULT '0',
  url varchar(128),
  rdf varchar(255),
  retrieve int2 DEFAULT '0',
  PRIMARY KEY (bid),
  UNIQUE (type),
  UNIQUE (section)
);




CREATE TABLE commentcodes (
  code int2 DEFAULT '0' NOT NULL,
  name char(32),
  PRIMARY KEY (code)
);




CREATE TABLE commentmodes (
  mode varchar(16) DEFAULT '' NOT NULL,
  name varchar(32),
  description varchar(64),
  PRIMARY KEY (mode)
);




CREATE TABLE comments (
  sid varchar(30) DEFAULT '' NOT NULL,
  cid int4 DEFAULT '0' NOT NULL,
  pid int4 DEFAULT '0' NOT NULL,
  date datetime DEFAULT '1970-01-01 00:00:00' NOT NULL,
  host_name varchar(30) DEFAULT '0.0.0.0' NOT NULL,
  subject varchar(50) DEFAULT '' NOT NULL,
  comment text NOT NULL,
  uid int2 NOT NULL,
  points int2 DEFAULT '0' NOT NULL,
  lastmod int2,
  reason int2 DEFAULT '0',
  PRIMARY KEY (sid,cid),
  UNIQUE (sid,points,uid),
  UNIQUE (uid,points),
  UNIQUE (sid,uid,points,cid),
  UNIQUE (sid,pid)
);




CREATE TABLE content_filters (
  filter_id int2 DEFAULT '0' NOT NULL auto_increment,
  regex varchar(100) DEFAULT '' NOT NULL,
  modifier varchar(5) DEFAULT '' NOT NULL,
  field varchar(20) DEFAULT '' NOT NULL,
  ratio float(6,4) DEFAULT '0.0000' NOT NULL,
  minimum_match int4 DEFAULT '0' NOT NULL,
  minimum_length int4 DEFAULT '0' NOT NULL,
  err_message varchar(150) DEFAULT '',
  maximum_length int4 DEFAULT '0' NOT NULL,
  PRIMARY KEY (filter_id),
  UNIQUE (regex),
  UNIQUE (field)
);




CREATE TABLE dateformats (
  id int2 DEFAULT '0' NOT NULL,
  format varchar(32),
  description varchar(64),
  PRIMARY KEY (id)
);




CREATE TABLE discussions (
  sid varchar(20) DEFAULT '' NOT NULL,
  title varchar(128),
  url varchar(128),
  ts datetime DEFAULT '1970-01-01 00:00:00' NOT NULL,
  PRIMARY KEY (sid)
);




CREATE TABLE displaycodes (
  code int2 DEFAULT '0' NOT NULL,
  name char(32),
  PRIMARY KEY (code)
);




CREATE TABLE formkeys (
  formkey varchar(20) DEFAULT '' NOT NULL,
  formname varchar(20) DEFAULT '' NOT NULL,
  id varchar(30) DEFAULT '' NOT NULL,
  sid varchar(30) DEFAULT '' NOT NULL,
  uid int4 NOT NULL,
  host_name varchar(30) DEFAULT '0.0.0.0' NOT NULL,
  value int4 DEFAULT '0' NOT NULL,
  cid int4 DEFAULT '0' NOT NULL,
  ts int4 DEFAULT '0' NOT NULL,
  submit_ts int4 DEFAULT '0' NOT NULL,
  content_length int2 DEFAULT '0' NOT NULL,
  PRIMARY KEY (formkey),
  UNIQUE (formname),
  UNIQUE (id),
  UNIQUE (ts),
  UNIQUE (submit_ts)
);




CREATE TABLE hitters (
  id SERIAL,
  host_addr varchar(15) DEFAULT '' NOT NULL,
  hits int4 DEFAULT '0' NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (host_addr),
  UNIQUE (hits)
);




CREATE TABLE isolatemodes (
  code int2 DEFAULT '0' NOT NULL,
  name char(32),
  PRIMARY KEY (code)
);




CREATE TABLE issuemodes (
  code int2 DEFAULT '0' NOT NULL,
  name char(32),
  PRIMARY KEY (code)
);




CREATE TABLE maillist (
  code int2 DEFAULT '0' NOT NULL,
  name char(32),
  PRIMARY KEY (code)
);




CREATE TABLE metamodlog (
  id SERIAL,
  mmid int4 DEFAULT '0' NOT NULL,
  uid int4 DEFAULT '0' NOT NULL,
  val int4 DEFAULT '0' NOT NULL,
  ts datetime,
  PRIMARY KEY (id)
);




CREATE TABLE moderatorlog (
  id SERIAL,
  uid int2 DEFAULT '0' NOT NULL,
  val int2 DEFAULT '0' NOT NULL,
  sid varchar(30) DEFAULT '' NOT NULL,
  ts datetime DEFAULT '1970-01-01 00:00:00' NOT NULL,
  cid int2 DEFAULT '0' NOT NULL,
  reason int4 DEFAULT '0',
  PRIMARY KEY (id),
  UNIQUE (sid,cid),
  UNIQUE (sid,uid,cid)
);




CREATE TABLE newstories (
  sid varchar(20) DEFAULT '' NOT NULL,
  tid varchar(20) DEFAULT '' NOT NULL,
  aid varchar(30) DEFAULT '' NOT NULL,
  commentcount int2 DEFAULT '0',
  title varchar(100) DEFAULT '' NOT NULL,
  dept varchar(100),
  time datetime DEFAULT '1970-01-01 00:00:00' NOT NULL,
  introtext text,
  bodytext text,
  writestatus int2 DEFAULT '0' NOT NULL,
  hits int2 DEFAULT '0' NOT NULL,
  section varchar(15) DEFAULT '' NOT NULL,
  displaystatus int2 DEFAULT '0' NOT NULL,
  commentstatus int2,
  hitparade varchar(64) DEFAULT '0,0,0,0,0,0,0',
  relatedtext text,
  extratext text,
  PRIMARY KEY (sid),
  UNIQUE (time),
  UNIQUE (displaystatus,time)
);




CREATE TABLE pollanswers (
  qid char(20) DEFAULT '' NOT NULL,
  aid int4 DEFAULT '0' NOT NULL,
  answer char(255),
  votes int4,
  PRIMARY KEY (qid,aid)
);




CREATE TABLE pollquestions (
  qid char(20) DEFAULT '' NOT NULL,
  question char(255) DEFAULT '' NOT NULL,
  voters int4,
  date datetime,
  PRIMARY KEY (qid)
);




CREATE TABLE pollvoters (
  qid char(20) DEFAULT '' NOT NULL,
  id char(35) DEFAULT '' NOT NULL,
  time datetime,
  uid int4 NOT NULL,
  UNIQUE (qid,id,uid)
);




CREATE TABLE postmodes (
  code char(10) DEFAULT '' NOT NULL,
  name char(32),
  PRIMARY KEY (code)
);




CREATE TABLE sections (
  section varchar(30) DEFAULT '' NOT NULL,
  artcount int4,
  title varchar(64),
  qid varchar(20) DEFAULT '' NOT NULL,
  isolate int2,
  issue int2,
  extras int4 DEFAULT '0',
  PRIMARY KEY (section)
);




CREATE TABLE sessions (
  session varchar(20) DEFAULT '' NOT NULL,
  aid varchar(30),
  logintime datetime,
  lasttime datetime,
  lasttitle varchar(50),
  PRIMARY KEY (session)
);




CREATE TABLE slashslices (
  ssID SERIAL,
  ssRank int4 DEFAULT '0' NOT NULL,
  ssRUID int4,
  ssLayer text,
  PRIMARY KEY (ssID,ssRank),
  UNIQUE (ssRank)
);




CREATE TABLE sortcodes (
  code int2 DEFAULT '0' NOT NULL,
  name char(32),
  PRIMARY KEY (code)
);




CREATE TABLE statuscodes (
  code int2 DEFAULT '0' NOT NULL,
  name char(32),
  PRIMARY KEY (code)
);




CREATE TABLE stories (
  sid varchar(20) DEFAULT '' NOT NULL,
  tid varchar(20) DEFAULT '' NOT NULL,
  aid varchar(30) DEFAULT '' NOT NULL,
  commentcount int2 DEFAULT '0',
  title varchar(100) DEFAULT '' NOT NULL,
  dept varchar(100),
  time datetime DEFAULT '1970-01-01 00:00:00' NOT NULL,
  introtext text,
  bodytext text,
  writestatus int2 DEFAULT '0' NOT NULL,
  hits int2 DEFAULT '0' NOT NULL,
  section varchar(15) DEFAULT '' NOT NULL,
  displaystatus int2 DEFAULT '0' NOT NULL,
  commentstatus int2,
  hitparade varchar(64) DEFAULT '0,0,0,0,0,0,0',
  relatedtext text,
  extratext text,
  PRIMARY KEY (sid),
  UNIQUE (time),
  UNIQUE (displaystatus,time)
);




CREATE TABLE storiestuff (
  sid varchar(20) DEFAULT '' NOT NULL,
  hits int2 DEFAULT '0' NOT NULL,
  PRIMARY KEY (sid)
);




CREATE TABLE submissions (
  subid varchar(15) DEFAULT '' NOT NULL,
  email varchar(50),
  name varchar(50),
  time datetime,
  subj varchar(50),
  story text,
  tid varchar(20),
  note varchar(30),
  section varchar(30) DEFAULT '' NOT NULL,
  comment varchar(255),
  uid int4 NOT NULL,
  del int2 DEFAULT '0' NOT NULL,
  PRIMARY KEY (subid),
  UNIQUE (subid,section)
);




CREATE TABLE threshcodes (
  thresh int2 DEFAULT '0' NOT NULL,
  description char(64),
  PRIMARY KEY (thresh)
);




CREATE TABLE topics (
  tid char(20) DEFAULT '' NOT NULL,
  image char(30),
  alttext char(40),
  width int4,
  height int4,
  PRIMARY KEY (tid)
);




CREATE TABLE tzcodes (
  tz char(3) DEFAULT '' NOT NULL,
  value int2,
  description varchar(64),
  PRIMARY KEY (tz)
);




CREATE TABLE users (
  uid SERIAL,
  nickname varchar(20) DEFAULT '' NOT NULL,
  realemail varchar(50) DEFAULT '' NOT NULL,
  fakeemail varchar(50),
  homepage varchar(100),
  passwd varchar(32) DEFAULT '' NOT NULL,
  sig varchar(160),
  seclev int4 DEFAULT '0' NOT NULL,
  matchname varchar(20),
  newpasswd varchar(32),
  PRIMARY KEY (uid),
  UNIQUE (uid,passwd,nickname),
  UNIQUE (nickname,realemail),
  UNIQUE (realemail)
);




CREATE TABLE users_comments (
  uid SERIAL,
  points int4 DEFAULT '0' NOT NULL,
  posttype varchar(10) DEFAULT 'html' NOT NULL,
  defaultpoints int4 DEFAULT '1' NOT NULL,
  highlightthresh int4 DEFAULT '4' NOT NULL,
  maxcommentsize int4 DEFAULT '4096' NOT NULL,
  hardthresh int2 DEFAULT '0' NOT NULL,
  clbig int4 DEFAULT '0' NOT NULL,
  clsmall int4 DEFAULT '0' NOT NULL,
  reparent int4 DEFAULT '1' NOT NULL,
  nosigs int4 DEFAULT '0' NOT NULL,
  commentlimit int4 DEFAULT '100' NOT NULL,
  commentspill int4 DEFAULT '50' NOT NULL,
  commentsort int2 DEFAULT '0',
  noscores int2 DEFAULT '0' NOT NULL,
  mode varchar(10) DEFAULT 'thread',
  threshold int2 DEFAULT '0',
  PRIMARY KEY (uid)
);




CREATE TABLE users_index (
  uid SERIAL,
  extid varchar(255),
  exaid varchar(100),
  exsect varchar(100),
  exboxes varchar(255),
  maxstories int4 DEFAULT '30' NOT NULL,
  noboxes int2 DEFAULT '0' NOT NULL,
  PRIMARY KEY (uid)
);




CREATE TABLE users_info (
  uid SERIAL,
  totalmods int4 DEFAULT '0' NOT NULL,
  realname varchar(50),
  bio text,
  tokens int4 DEFAULT '0' NOT NULL,
  lastgranted date DEFAULT '1970-01-01' NOT NULL,
  karma int4 DEFAULT '0' NOT NULL,
  maillist int2 DEFAULT '0' NOT NULL,
  totalcomments int2 DEFAULT '0',
  lastmm date DEFAULT '1970-01-01' NOT NULL,
  lastaccess date DEFAULT '1970-01-01' NOT NULL,
  lastmmid int4 DEFAULT '0' NOT NULL,
  PRIMARY KEY (uid)
);




CREATE TABLE users_key (
  uid SERIAL,
  pubkey text,
  PRIMARY KEY (uid)
);




CREATE TABLE users_prefs (
  uid int4 DEFAULT '0' NOT NULL,
  willing int2 DEFAULT '1' NOT NULL,
  dfid int4 DEFAULT '0' NOT NULL,
  tzcode char(3) DEFAULT 'edt' NOT NULL,
  noicons int2 DEFAULT '0' NOT NULL,
  light int2 DEFAULT '0' NOT NULL,
  mylinks varchar(255) DEFAULT '' NOT NULL,
  PRIMARY KEY (uid)
);




CREATE TABLE vars (
  name varchar(32) DEFAULT '' NOT NULL,
  value text,
  description varchar(127),
  datatype varchar(10),
  dataop varchar(12),
  PRIMARY KEY (name)
);

