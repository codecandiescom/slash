Summary: Slashdot-Like Automated Story Homepage
Name: slash
Version: 1.1.4_bender
Release: 1
Copyright: GPL
Group: Applications/Internet
Source: ftp://slashcode.sourceforge.net/pub/slashcode/slash-1.1.4-bender.tar.gz
BuildRoot: /var/tmp/%{name}-buildroot

%description
Slash is a database-driven news and message board, using Perl, Apache and mySQL.
It is the code that runs Slashdot. For forums, support, mailing lists, etc.
please see the Slashcode site.

%prep
%setup -q -n slash-1.1.4-bender

%build
make RPM_OPT_FLAGS="$RPM_OPT_FLAGS" PREFIX=$RPM_BUILD_ROOT/usr/local/slash INIT=$RPM_BUILD_ROOT/etc/rc.d USER=99 GROUP=99 RPM=1

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/rc.d/init.d
mkdir -p $RPM_BUILD_ROOT/etc/rc.d/rc3.d
mkdir -p $RPM_BUILD_ROOT/etc/rc.d/rc6.d
make install RPM_OPT_FLAGS="$RPM_OPT_FLAGS" PREFIX=/var/tmp/%{name}-buildroot/usr/local/slash INIT=/var/tmp/%{name}-buildroot/etc/rc.d USER=99 GROUP=99 RPM=1

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr (-,nobody,nobody)
%doc AUTHORS CHANGES COPYING INSTALL MANIFEST MANIFEST.SKIP README

/etc/rc.d/init.d/slash
/etc/rc.d/rc3.d/S99slash
/etc/rc.d/rc6.d/K99slash
/usr/local/slash
/usr/local/slash/bin
/usr/local/slash/bin/install-slashsite
/usr/local/slash/bin/install-plugin
/usr/local/slash/bin/tailslash
/usr/local/slash/bin/template-tool
/usr/local/slash/sbin
/usr/local/slash/sbin/slashd
/usr/local/slash/sbin/portald
/usr/local/slash/sbin/moderatord
/usr/local/slash/sbin/dailyStuff
/usr/local/slash/sql
/usr/local/slash/sql/mysql
/usr/local/slash/sql/mysql/schema.sql
/usr/local/slash/sql/postgresql
/usr/local/slash/sql/postgresql/schema.sql
/usr/local/slash/themes
/usr/local/slash/themes/slashcode
/usr/local/slash/themes/slashcode/htdocs
/usr/local/slash/themes/slashcode/htdocs/article.pl
/usr/local/slash/themes/slashcode/htdocs/404.pl
/usr/local/slash/themes/slashcode/htdocs/images
/usr/local/slash/themes/slashcode/htdocs/images/topics
/usr/local/slash/themes/slashcode/htdocs/images/topics/topicbug.jpg
/usr/local/slash/themes/slashcode/htdocs/images/topics/topiclinux.gif
/usr/local/slash/themes/slashcode/htdocs/images/topics/topicnews.gif
/usr/local/slash/themes/slashcode/htdocs/images/topics/topicslash.gif
/usr/local/slash/themes/slashcode/htdocs/images/topics/topicslashdot.gif
/usr/local/slash/themes/slashcode/htdocs/images/660000.gif
/usr/local/slash/themes/slashcode/htdocs/images/admin_bracket.jpg
/usr/local/slash/themes/slashcode/htdocs/images/andover.gif
/usr/local/slash/themes/slashcode/htdocs/images/bsb.gif
/usr/local/slash/themes/slashcode/htdocs/images/bsbr.gif
/usr/local/slash/themes/slashcode/htdocs/images/bsr.gif
/usr/local/slash/themes/slashcode/htdocs/images/cl.gif
/usr/local/slash/themes/slashcode/htdocs/images/cr.gif
/usr/local/slash/themes/slashcode/htdocs/images/gl.gif
/usr/local/slash/themes/slashcode/htdocs/images/gr.gif
/usr/local/slash/themes/slashcode/htdocs/images/greendot.gif
/usr/local/slash/themes/slashcode/htdocs/images/icondiv.gif
/usr/local/slash/themes/slashcode/htdocs/images/icondiv2.gif
/usr/local/slash/themes/slashcode/htdocs/images/leftbar.gif
/usr/local/slash/themes/slashcode/htdocs/images/line-bg.gif
/usr/local/slash/themes/slashcode/htdocs/images/line-corner.gif
/usr/local/slash/themes/slashcode/htdocs/images/mainbar.gif
/usr/local/slash/themes/slashcode/htdocs/images/pix.gif
/usr/local/slash/themes/slashcode/htdocs/images/portalmap.gif
/usr/local/slash/themes/slashcode/htdocs/images/rightbar.gif
/usr/local/slash/themes/slashcode/htdocs/images/sbs.gif
/usr/local/slash/themes/slashcode/htdocs/images/sdlogo.gif
/usr/local/slash/themes/slashcode/htdocs/images/sl.gif
/usr/local/slash/themes/slashcode/htdocs/images/slashhead.gif
/usr/local/slash/themes/slashcode/htdocs/images/slashlogo.gif
/usr/local/slash/themes/slashcode/htdocs/images/slashslogan.gif
/usr/local/slash/themes/slashcode/htdocs/images/slr.gif
/usr/local/slash/themes/slashcode/htdocs/images/sr.gif
/usr/local/slash/themes/slashcode/htdocs/images/srs.gif
/usr/local/slash/themes/slashcode/htdocs/images/wl.gif
/usr/local/slash/themes/slashcode/htdocs/images/wl_cccccc.gif
/usr/local/slash/themes/slashcode/htdocs/images/wr.gif
/usr/local/slash/themes/slashcode/htdocs/images/wr_cccccc.gif
/usr/local/slash/themes/slashcode/htdocs/authors.pl
/usr/local/slash/themes/slashcode/htdocs/cheesyportal.pl
/usr/local/slash/themes/slashcode/htdocs/comments.pl
/usr/local/slash/themes/slashcode/htdocs/getting_started.shtml
/usr/local/slash/themes/slashcode/htdocs/hof.pl
/usr/local/slash/themes/slashcode/htdocs/index.pl
/usr/local/slash/themes/slashcode/htdocs/metamod.pl
/usr/local/slash/themes/slashcode/htdocs/pollBooth.pl
/usr/local/slash/themes/slashcode/htdocs/sections.pl
/usr/local/slash/themes/slashcode/htdocs/submit.pl
/usr/local/slash/themes/slashcode/htdocs/topics.pl
/usr/local/slash/themes/slashcode/htdocs/users.pl
/usr/local/slash/themes/slashcode/sql
/usr/local/slash/themes/slashcode/sql/postgresql
/usr/local/slash/themes/slashcode/sql/postgresql/datadump.sql
/usr/local/slash/themes/slashcode/sql/postgresql/prep.sql
/usr/local/slash/themes/slashcode/sql/mysql
/usr/local/slash/themes/slashcode/sql/mysql/datadump.sql
/usr/local/slash/themes/slashcode/sql/mysql/prep.sql
/usr/local/slash/themes/slashcode/backup
/usr/local/slash/themes/slashcode/logs
/usr/local/slash/themes/slashcode/templates
/usr/local/slash/themes/slashcode/templates/admin;menu;default
/usr/local/slash/themes/slashcode/templates/comment_submit;comments;default
/usr/local/slash/themes/slashcode/templates/currentAdminUsers;misc;default
/usr/local/slash/themes/slashcode/templates/data;cheesyportal;default
/usr/local/slash/themes/slashcode/templates/data;hof;default
/usr/local/slash/themes/slashcode/templates/data;index;default
/usr/local/slash/themes/slashcode/templates/data;metamod;default
/usr/local/slash/themes/slashcode/templates/data;misc;default
/usr/local/slash/themes/slashcode/templates/data;pollBooth;default
/usr/local/slash/themes/slashcode/templates/data;sections;default
/usr/local/slash/themes/slashcode/templates/data;submit;default
/usr/local/slash/themes/slashcode/templates/data;topics;default
/usr/local/slash/themes/slashcode/templates/delSectCancel;sections;default
/usr/local/slash/themes/slashcode/templates/delSectConfirm;sections;default
/usr/local/slash/themes/slashcode/templates/delSection;sections;default
/usr/local/slash/themes/slashcode/templates/del_message;comments;default
/usr/local/slash/themes/slashcode/templates/deleted_cids;comments;default
/usr/local/slash/themes/slashcode/templates/discuss_list;comments;default
/usr/local/slash/themes/slashcode/templates/dispComment;misc;default
/usr/local/slash/themes/slashcode/templates/dispComment;misc;light
/usr/local/slash/themes/slashcode/templates/dispStory;misc;default
/usr/local/slash/themes/slashcode/templates/dispStory;misc;light
/usr/local/slash/themes/slashcode/templates/dispStoryTitle;misc;default
/usr/local/slash/themes/slashcode/templates/dispTheComments;metamod;default
/usr/local/slash/themes/slashcode/templates/display;article;default
/usr/local/slash/themes/slashcode/templates/displayForm;submit;default
/usr/local/slash/themes/slashcode/templates/displayForm;users;default
/usr/local/slash/themes/slashcode/templates/displayThread;misc;default
/usr/local/slash/themes/slashcode/templates/editComm;users;default
/usr/local/slash/themes/slashcode/templates/editHome;users;default
/usr/local/slash/themes/slashcode/templates/editKey;users;default
/usr/local/slash/themes/slashcode/templates/editSection;sections;default
/usr/local/slash/themes/slashcode/templates/editUser;users;default
/usr/local/slash/themes/slashcode/templates/edit_comment;comments;default
/usr/local/slash/themes/slashcode/templates/editpoll;pollBooth;default
/usr/local/slash/themes/slashcode/templates/errors;comments;default
/usr/local/slash/themes/slashcode/templates/fancybox;misc;default
/usr/local/slash/themes/slashcode/templates/fancybox;misc;light
/usr/local/slash/themes/slashcode/templates/footer;misc;admin
/usr/local/slash/themes/slashcode/templates/footer;misc;default
/usr/local/slash/themes/slashcode/templates/footer;misc;light
/usr/local/slash/themes/slashcode/templates/formLabel;misc;default
/usr/local/slash/themes/slashcode/templates/genQuickies;submit;default
/usr/local/slash/themes/slashcode/templates/getOlderStories;misc;default
/usr/local/slash/themes/slashcode/templates/getUserAdmin;users;default
/usr/local/slash/themes/slashcode/templates/header;misc;admin
/usr/local/slash/themes/slashcode/templates/header;misc;default
/usr/local/slash/themes/slashcode/templates/header;misc;light
/usr/local/slash/themes/slashcode/templates/html-header;misc;default
/usr/local/slash/themes/slashcode/templates/html-redirect;misc;default
/usr/local/slash/themes/slashcode/templates/index;index;default
/usr/local/slash/themes/slashcode/templates/index;index;light
/usr/local/slash/themes/slashcode/templates/isEligible;metamod;default
/usr/local/slash/themes/slashcode/templates/linkComment;misc;default
/usr/local/slash/themes/slashcode/templates/linkCommentPages;misc;default
/usr/local/slash/themes/slashcode/templates/linkStory;misc;default
/usr/local/slash/themes/slashcode/templates/listSections;sections;default
/usr/local/slash/themes/slashcode/templates/listTopics;topics;default
/usr/local/slash/themes/slashcode/templates/listpolls;pollBooth;default
/usr/local/slash/themes/slashcode/templates/lockTest;misc;default
/usr/local/slash/themes/slashcode/templates/main;404;default
/usr/local/slash/themes/slashcode/templates/main;authors;default
/usr/local/slash/themes/slashcode/templates/main;cheesyportal;default
/usr/local/slash/themes/slashcode/templates/main;hof;default
/usr/local/slash/themes/slashcode/templates/mainmenu;misc;default
/usr/local/slash/themes/slashcode/templates/messages;users;default
/usr/local/slash/themes/slashcode/templates/metaModerate;metamod;default
/usr/local/slash/themes/slashcode/templates/miniAdminMenu;users;default
/usr/local/slash/themes/slashcode/templates/modCommentLog;misc;default
/usr/local/slash/themes/slashcode/templates/mod_footer;comments;default
/usr/local/slash/themes/slashcode/templates/mod_header;comments;default
/usr/local/slash/themes/slashcode/templates/moderation;comments;default
/usr/local/slash/themes/slashcode/templates/motd;misc;default
/usr/local/slash/themes/slashcode/templates/newUserForm;users;default
/usr/local/slash/themes/slashcode/templates/organisation;misc;default
/usr/local/slash/themes/slashcode/templates/pollbooth;misc;default
/usr/local/slash/themes/slashcode/templates/portalboxtitle;misc;default
/usr/local/slash/themes/slashcode/templates/portalmap;misc;default
/usr/local/slash/themes/slashcode/templates/previewForm;submit;default
/usr/local/slash/themes/slashcode/templates/previewSlashbox;users;default
/usr/local/slash/themes/slashcode/templates/preview_comm;comments;default
/usr/local/slash/themes/slashcode/templates/printCommComments;misc;default
/usr/local/slash/themes/slashcode/templates/printCommNoArchive;misc;default
/usr/local/slash/themes/slashcode/templates/printCommentsMain;misc;default
/usr/local/slash/themes/slashcode/templates/saveSub;submit;default
/usr/local/slash/themes/slashcode/templates/savepoll;pollBooth;default
/usr/local/slash/themes/slashcode/templates/sectionisolate;misc;default
/usr/local/slash/themes/slashcode/templates/select;misc;default
/usr/local/slash/themes/slashcode/templates/ssifoot;misc;default
/usr/local/slash/themes/slashcode/templates/ssihead;misc;default
/usr/local/slash/themes/slashcode/templates/selectThreshLabel;misc;default
/usr/local/slash/themes/slashcode/templates/storylink;index;default
/usr/local/slash/themes/slashcode/templates/storylink;index;light
/usr/local/slash/themes/slashcode/templates/subEdAdmin;submit;default
/usr/local/slash/themes/slashcode/templates/subEdTable;submit;default
/usr/local/slash/themes/slashcode/templates/subEdUser;submit;default
/usr/local/slash/themes/slashcode/templates/tildeEd;users;default
/usr/local/slash/themes/slashcode/templates/titlebar;misc;default
/usr/local/slash/themes/slashcode/templates/titlebar;misc;light
/usr/local/slash/themes/slashcode/templates/titles;users;default
/usr/local/slash/themes/slashcode/templates/topTopics;topics;default
/usr/local/slash/themes/slashcode/templates/topics;menu;default
/usr/local/slash/themes/slashcode/templates/undo_mod;comments;default
/usr/local/slash/themes/slashcode/templates/userInfo;users;default
/usr/local/slash/themes/slashcode/templates/userlogin;misc;default
/usr/local/slash/themes/slashcode/templates/users;menu;default
/usr/local/slash/themes/slashcode/templates/vote;pollBooth;default
/usr/local/slash/themes/slashcode/templates/yourPendingSubs;submit;default
/usr/local/slash/themes/Simple\ Story
/usr/local/slash/themes/Simple\ Story/htdocs
/usr/local/slash/themes/Simple\ Story/htdocs/images
/usr/local/slash/themes/Simple\ Story/htdocs/images/frontpage_r1_c1.gif
/usr/local/slash/themes/Simple\ Story/htdocs/images/frontpage_r4_c1.gif
/usr/local/slash/themes/Simple\ Story/htdocs/images/frontpage_r4_c3.gif
/usr/local/slash/themes/Simple\ Story/htdocs/images/shim.gif
/usr/local/slash/themes/Simple\ Story/htdocs/images/yazz.jpg
/usr/local/slash/themes/Simple\ Story/htdocs/article.pl
/usr/local/slash/themes/Simple\ Story/htdocs/index.pl
/usr/local/slash/themes/Simple\ Story/README
/usr/local/slash/themes/Simple\ Story/sql
/usr/local/slash/themes/Simple\ Story/sql/mysql
/usr/local/slash/themes/Simple\ Story/sql/mysql/datadump.sql
/usr/local/slash/themes/Simple\ Story/sql/mysql/prep.sql
/usr/local/slash/plugins
/usr/local/slash/plugins/BunchaBlocks
/usr/local/slash/plugins/BunchaBlocks/PLUGIN
/usr/local/slash/plugins/BunchaBlocks/blocks
/usr/local/slash/plugins/Ladybug
/usr/local/slash/plugins/Ladybug/templates
/usr/local/slash/plugins/Ladybug/templates/bug_box;bugs;default
/usr/local/slash/plugins/Ladybug/templates/bugs;menu;default
/usr/local/slash/plugins/Ladybug/templates/create_report;bugs;default
/usr/local/slash/plugins/Ladybug/templates/list;bugs;default
/usr/local/slash/plugins/Ladybug/templates/reports;bugs;default
/usr/local/slash/plugins/Ladybug/templates/submit_box;bugs;default
/usr/local/slash/plugins/Ladybug/templates/update_bug;bugs;default
/usr/local/slash/plugins/Ladybug/Ladybug.pm
/usr/local/slash/plugins/Ladybug/MANIFEST
/usr/local/slash/plugins/Ladybug/Makefile.PL
/usr/local/slash/plugins/Ladybug/PLUGIN
/usr/local/slash/plugins/Ladybug/bugs.pl
/usr/local/slash/plugins/Ladybug/dump
/usr/local/slash/plugins/Ladybug/maildump.pl
/usr/local/slash/plugins/Ladybug/schema.sql
/usr/local/slash/plugins/Ladybug/test.pl
/usr/local/slash/plugins/Ladybug/blib
/usr/local/slash/plugins/Ladybug/blib/lib
/usr/local/slash/plugins/Ladybug/blib/lib/Slash
/usr/local/slash/plugins/Ladybug/blib/lib/Slash/.exists
/usr/local/slash/plugins/Ladybug/blib/lib/Slash/Ladybug.pm
/usr/local/slash/plugins/Ladybug/blib/lib/Slash/bugs.pl
/usr/local/slash/plugins/Ladybug/blib/lib/Slash/maildump.pl
/usr/local/slash/plugins/Ladybug/blib/lib/auto
/usr/local/slash/plugins/Ladybug/blib/lib/auto/Slash
/usr/local/slash/plugins/Ladybug/blib/lib/auto/Slash/Ladybug
/usr/local/slash/plugins/Ladybug/blib/lib/auto/Slash/Ladybug/.exists
/usr/local/slash/plugins/Ladybug/blib/arch
/usr/local/slash/plugins/Ladybug/blib/arch/auto
/usr/local/slash/plugins/Ladybug/blib/arch/auto/Slash
/usr/local/slash/plugins/Ladybug/blib/arch/auto/Slash/Ladybug
/usr/local/slash/plugins/Ladybug/blib/arch/auto/Slash/Ladybug/.exists
/usr/local/slash/plugins/Ladybug/blib/man3
/usr/local/slash/plugins/Ladybug/blib/man3/.exists
/usr/local/slash/plugins/Ladybug/blib/man3/Slash::Ladybug.3pm
/usr/local/slash/plugins/Ladybug/Makefile
/usr/local/slash/plugins/Ladybug/pm_to_blib
/usr/local/slash/plugins/Slash-Admin
/usr/local/slash/plugins/Slash-Admin/admin.pl
/usr/local/slash/plugins/Slash-Admin/PLUGIN
/usr/local/slash/plugins/Slash-Admin/templates
/usr/local/slash/plugins/Slash-Admin/templates/adminLoginForm;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/authorEdit;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/blockEdit;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/colorEdit;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/editFilter;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/editStory;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/editbuttons;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/listFilters;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/listStories;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/listTopics;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/messages;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/otherLinks;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/relatedlinks;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/siteInfo;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/templateEdit;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/titles;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/topicEdit;admin;default
/usr/local/slash/plugins/Slash-Admin/templates/varEdit;admin;default
/usr/local/slash/plugins/Slash-Admin/dump
/usr/local/slash/plugins/Slash-Comments
/usr/local/slash/plugins/Slash-Comments/Comments.pm
/usr/local/slash/plugins/Slash-Comments/Makefile.PL
/usr/local/slash/plugins/Slash-Comments/PLUGIN
/usr/local/slash/plugins/Slash-Comments/schema.sql
/usr/local/slash/plugins/Slash-Comments/test.pl
/usr/local/slash/plugins/Slash-Journal
/usr/local/slash/plugins/Slash-Journal/Journal.pm
/usr/local/slash/plugins/Slash-Journal/Changes
/usr/local/slash/plugins/Slash-Journal/templates
/usr/local/slash/plugins/Slash-Journal/templates/bluebox;journal;default
/usr/local/slash/plugins/Slash-Journal/templates/generic;journal;default
/usr/local/slash/plugins/Slash-Journal/templates/greypage;journal;default
/usr/local/slash/plugins/Slash-Journal/templates/journal;menu;default
/usr/local/slash/plugins/Slash-Journal/templates/journaledit;journal;default
/usr/local/slash/plugins/Slash-Journal/templates/journalentry;journal;default
/usr/local/slash/plugins/Slash-Journal/templates/journalfriends;journal;default
/usr/local/slash/plugins/Slash-Journal/templates/journalitem;journal;default
/usr/local/slash/plugins/Slash-Journal/templates/journallist;journal;default
/usr/local/slash/plugins/Slash-Journal/templates/journaltop;journal;default
/usr/local/slash/plugins/Slash-Journal/MANIFEST
/usr/local/slash/plugins/Slash-Journal/Makefile.PL
/usr/local/slash/plugins/Slash-Journal/PLUGIN
/usr/local/slash/plugins/Slash-Journal/dump
/usr/local/slash/plugins/Slash-Journal/install
/usr/local/slash/plugins/Slash-Journal/journal.pl
/usr/local/slash/plugins/Slash-Journal/mysql_schema
/usr/local/slash/plugins/Slash-Journal/test.pl
/usr/local/slash/plugins/Slash-Journal/blib
/usr/local/slash/plugins/Slash-Journal/blib/lib
/usr/local/slash/plugins/Slash-Journal/blib/lib/Slash
/usr/local/slash/plugins/Slash-Journal/blib/lib/Slash/.exists
/usr/local/slash/plugins/Slash-Journal/blib/lib/Slash/Journal.pm
/usr/local/slash/plugins/Slash-Journal/blib/lib/Slash/journal.pl
/usr/local/slash/plugins/Slash-Journal/blib/lib/auto
/usr/local/slash/plugins/Slash-Journal/blib/lib/auto/Slash
/usr/local/slash/plugins/Slash-Journal/blib/lib/auto/Slash/Journal
/usr/local/slash/plugins/Slash-Journal/blib/lib/auto/Slash/Journal/.exists
/usr/local/slash/plugins/Slash-Journal/blib/arch
/usr/local/slash/plugins/Slash-Journal/blib/arch/auto
/usr/local/slash/plugins/Slash-Journal/blib/arch/auto/Slash
/usr/local/slash/plugins/Slash-Journal/blib/arch/auto/Slash/Journal
/usr/local/slash/plugins/Slash-Journal/blib/arch/auto/Slash/Journal/.exists
/usr/local/slash/plugins/Slash-Journal/blib/man3
/usr/local/slash/plugins/Slash-Journal/blib/man3/.exists
/usr/local/slash/plugins/Slash-Journal/blib/man3/Slash::Journal.3pm
/usr/local/slash/plugins/Slash-Journal/Makefile
/usr/local/slash/plugins/Slash-Journal/pm_to_blib
/usr/local/slash/plugins/Slash-Search
/usr/local/slash/plugins/Slash-Search/MANIFEST
/usr/local/slash/plugins/Slash-Search/Changes
/usr/local/slash/plugins/Slash-Search/templates
/usr/local/slash/plugins/Slash-Search/templates/commentsearch;search;default
/usr/local/slash/plugins/Slash-Search/templates/linksearch;search;default
/usr/local/slash/plugins/Slash-Search/templates/searchform;search;default
/usr/local/slash/plugins/Slash-Search/templates/storysearch;search;default
/usr/local/slash/plugins/Slash-Search/templates/usersearch;search;default
/usr/local/slash/plugins/Slash-Search/Makefile.PL
/usr/local/slash/plugins/Slash-Search/PLUGIN
/usr/local/slash/plugins/Slash-Search/Search.pm
/usr/local/slash/plugins/Slash-Search/search.pl
/usr/local/slash/plugins/Slash-Search/test.pl
/usr/local/slash/plugins/Slash-Search/blib
/usr/local/slash/plugins/Slash-Search/blib/lib
/usr/local/slash/plugins/Slash-Search/blib/lib/Slash
/usr/local/slash/plugins/Slash-Search/blib/lib/Slash/.exists
/usr/local/slash/plugins/Slash-Search/blib/lib/Slash/Search.pm
/usr/local/slash/plugins/Slash-Search/blib/lib/Slash/search.pl
/usr/local/slash/plugins/Slash-Search/blib/lib/auto
/usr/local/slash/plugins/Slash-Search/blib/lib/auto/Slash
/usr/local/slash/plugins/Slash-Search/blib/lib/auto/Slash/Search
/usr/local/slash/plugins/Slash-Search/blib/lib/auto/Slash/Search/.exists
/usr/local/slash/plugins/Slash-Search/blib/arch
/usr/local/slash/plugins/Slash-Search/blib/arch/auto
/usr/local/slash/plugins/Slash-Search/blib/arch/auto/Slash
/usr/local/slash/plugins/Slash-Search/blib/arch/auto/Slash/Search
/usr/local/slash/plugins/Slash-Search/blib/arch/auto/Slash/Search/.exists
/usr/local/slash/plugins/Slash-Search/blib/man3
/usr/local/slash/plugins/Slash-Search/blib/man3/.exists
/usr/local/slash/plugins/Slash-Search/blib/man3/Slash::Search.3pm
/usr/local/slash/plugins/Slash-Search/Makefile
/usr/local/slash/plugins/Slash-Search/pm_to_blib
/usr/local/slash/httpd
/usr/local/slash/httpd/slash.conf
/usr/local/slash/slash.sites
/usr/local/slash/site
/usr/local/lib/site_perl/i386-linux/auto/Slash
/usr/local/lib/site_perl/i386-linux/auto/Slash/.packlist
/usr/local/lib/site_perl/i386-linux/auto/Slash/Apache
/usr/local/lib/site_perl/i386-linux/auto/Slash/Apache/Apache.bs
/usr/local/lib/site_perl/i386-linux/auto/Slash/Apache/Apache.so
/usr/local/lib/site_perl/i386-linux/auto/Slash/Apache/autosplit.ix
/usr/local/lib/site_perl/i386-linux/auto/Slash/Apache/User
/usr/local/lib/site_perl/i386-linux/auto/Slash/Apache/User/autosplit.ix
/usr/local/lib/site_perl/i386-linux/auto/Slash/Apache/User/User.bs
/usr/local/lib/site_perl/i386-linux/auto/Slash/Apache/User/User.so
/usr/local/lib/site_perl/i386-linux/auto/Slash/Journal
/usr/local/lib/site_perl/i386-linux/auto/Slash/Journal/.packlist
/usr/local/lib/site_perl/i386-linux/auto/Slash/Ladybug
/usr/local/lib/site_perl/i386-linux/auto/Slash/Ladybug/.packlist
/usr/local/lib/site_perl/i386-linux/auto/Slash/Search
/usr/local/lib/site_perl/i386-linux/auto/Slash/Search/.packlist
/usr/local/lib/site_perl/i386-linux/Slash
/usr/local/lib/site_perl/i386-linux/Slash.pm
/usr/local/lib/site_perl/i386-linux/Slash/Apache
/usr/local/lib/site_perl/i386-linux/Slash/Apache.pm
/usr/local/lib/site_perl/i386-linux/Slash/Apache/Log.pm
/usr/local/lib/site_perl/i386-linux/Slash/Apache/User.pm
/usr/local/lib/site_perl/i386-linux/Slash/DB
/usr/local/lib/site_perl/i386-linux/Slash/DB.pm
/usr/local/lib/site_perl/i386-linux/Slash/DB/MySQL.pm
/usr/local/lib/site_perl/i386-linux/Slash/DB/Oracle.pm
/usr/local/lib/site_perl/i386-linux/Slash/DB/PostgreSQL.pm
/usr/local/lib/site_perl/i386-linux/Slash/DB/Static
/usr/local/lib/site_perl/i386-linux/Slash/DB/Static/MySQL.pm
/usr/local/lib/site_perl/i386-linux/Slash/DB/Static/Oracle.pm
/usr/local/lib/site_perl/i386-linux/Slash/DB/Static/PostgreSQL.pm
/usr/local/lib/site_perl/i386-linux/Slash/DB/Utility.pm
/usr/local/lib/site_perl/i386-linux/Slash/Display
/usr/local/lib/site_perl/i386-linux/Slash/Display.pm
/usr/local/lib/site_perl/i386-linux/Slash/Display/Plugin.pm
/usr/local/lib/site_perl/i386-linux/Slash/Display/Provider.pm
/usr/local/lib/site_perl/i386-linux/Slash/Install.pm
/usr/local/lib/site_perl/i386-linux/Slash/Utility.pm
/usr/local/lib/site_perl/Slash
/usr/local/lib/site_perl/Slash/bugs.pl
/usr/local/lib/site_perl/Slash/journal.pl
/usr/local/lib/site_perl/Slash/Journal.pm
/usr/local/lib/site_perl/Slash/Ladybug.pm
/usr/local/lib/site_perl/Slash/maildump.pl
/usr/local/lib/site_perl/Slash/search.pl
/usr/local/lib/site_perl/Slash/Search.pm
/usr/local/man/man3/Slash.3pm
/usr/local/man/man3/Slash::Apache.3pm
/usr/local/man/man3/Slash::Apache::Log.3pm
/usr/local/man/man3/Slash::Apache::User.3pm
/usr/local/man/man3/Slash::DB.3pm
/usr/local/man/man3/Slash::DB::MySQL.3pm
/usr/local/man/man3/Slash::DB::Oracle.3pm
/usr/local/man/man3/Slash::DB::PostgreSQL.3pm
/usr/local/man/man3/Slash::DB::Static::MySQL.3pm
/usr/local/man/man3/Slash::DB::Static::Oracle.3pm
/usr/local/man/man3/Slash::DB::Static::PostgreSQL.3pm
/usr/local/man/man3/Slash::DB::Utility.3pm
/usr/local/man/man3/Slash::Display.3pm
/usr/local/man/man3/Slash::Display::Plugin.3pm
/usr/local/man/man3/Slash::Display::Provider.3pm
/usr/local/man/man3/Slash::Install.3pm
/usr/local/man/man3/Slash::Journal.3pm
/usr/local/man/man3/Slash::Ladybug.3pm
/usr/local/man/man3/Slash::Search.3pm
/usr/local/man/man3/Slash::Utility.3pm

%changelog
* Fri Feb 09 2001 Jonathan Pater <pater@slashdot.org>
- Initial Package
