UPDATE blocks SET block = 'print \"\\n\\n<!-- begin index block -->\\n\\n\";\r\n\r\nif ($I{U}{uid} > 0) {\r\n	printf qq[<FONT SIZE=\"${\\( $I{fontbase} + 1 )}\"><B>This page was generated by a %s of %s %s for ] .\r\n		qq[<A HREF=\"$I{rootdir}/users.pl\">$I{U}{nickname}</A> ($I{U}{uid}).</B></FONT><P>\\n],\r\n		(\'Flock\', \'Swarm\', \'Barrel\', \'Team\', \'Squadron\', \'Group\', \'Cadre\')[rand 7],\r\n		(\'Rabid\', \'Uber\', \'Psycho\', \'Attack\', \'Circus\', \'Albino\', \'Trained\',\r\n			\'Stealth\', \'Super\', \'Elite\', \'Random\', \'Orange\', \'Ultra\')[rand 13],\r\n		(\'Mummies\', \'Elephants\', \'Midgets\', \'Ninjas\', \'Squirrels\',\r\n			\'Chickens\', \'Geese\', \'Monkeys\', \'Geese\')[rand 9],\r\n	$SECT->{artcount} = $I{U}{maxstories};\r\n}\r\n\r\n\r\nmy $stories = $I{dbobject}->getStories(\$I{U},\$I{F},$SECT,$I{currentSection});\r\ndisplayStories($stories);\r\n\r\nunless ($I{U}{noboxes}) {\r\n	print qq[\\n</TD>\\n<TD>&nbsp;</TD><TD WIDTH=\"210\" ALIGN=\"CENTER\" VALIGN=\"TOP\">\\n];\r\n	displayStandardBlocks($SECT, $stories);\r\n}\r\n\r\nprint \"\\n\\n<!-- end index block -->\\n\\n\";\r\n\r\n', blockbak = 'print \"\\n\\n<!-- begin index block -->\\n\\n\";\r\n\r\nif ($I{U}{uid} > 0) {\r\n	printf qq[<FONT SIZE=\"${\\( $I{fontbase} + 1 )}\"><B>This page was generated by a %s of %s %s for ] .\r\n		qq[<A HREF=\"$I{rootdir}/users.pl\">$I{U}{nickname}</A> ($I{U}{uid}).</B></FONT><P>\\n],\r\n		(\'Flock\', \'Swarm\', \'Barrel\', \'Team\', \'Squadron\', \'Group\', \'Cadre\')[rand 7],\r\n		(\'Rabid\', \'Uber\', \'Psycho\', \'Attack\', \'Circus\', \'Albino\', \'Trained\',\r\n			\'Stealth\', \'Super\', \'Elite\', \'Random\', \'Orange\', \'Ultra\')[rand 13],\r\n		(\'Mummies\', \'Elephants\', \'Midgets\', \'Ninjas\', \'Squirrels\',\r\n			\'Chickens\', \'Geese\', \'Monkeys\', \'Geese\')[rand 9],\r\n	$SECT->{artcount} = $I{U}{maxstories};\r\n}\r\n\r\n\r\nmy $stories = $I{dbobject}->getStories(\$I{U},\$I{F},$SECT,$I{currentSection});\r\ndisplayStories($stories);\r\n\r\nunless ($I{U}{noboxes}) {\r\n	print qq[\\n</TD>\\n<TD>&nbsp;</TD><TD WIDTH=\"210\" ALIGN=\"CENTER\" VALIGN=\"TOP\">\\n];\r\n	displayStandardBlocks($SECT, $stories);\r\n}\r\n\r\nprint \"\\n\\n<!-- end index block -->\\n\\n\";\r\n\r\n' where bid = 'index';
UPDATE blocks SET block = '\r\nmy $stories=I{dbobject}->getStories(\$I{U},\$I{F},$SECT,$I{currentSection});\r\n\r\ndisplayStories($stories);\r\nprint \"<P>\";\r\ndisplayStandardBlocks($SECT,$stories);\r\n', blockbak = '\r\nmy $stories=$I{dbobject}->getStories(\$I{U},\$I{F},$SECT,$I{currentSection});\r\n\r\ndisplayStories($stories);\r\nprint \"<P>\";\r\ndisplayStandardBlocks($SECT,$stories);\r\n' where bid = 'light_index';
UPDATE blocks SET block = 'if($I{U}{uid} > 0) {\r\nsrand();\r\nprint \"<FONT size=1><B> This page was generated by a \",\r\n      (\"Million\",\"Team\",\"Squadron\",\"Group\",\"Cadre\")[rand 5],\r\n      \" of \",\r\n      (\"Attack\",\"Circus\",\"Albino\",\"Trained\",\"Stealth\",\"Super\",\"Elite\",\"Random\",\"Orange\",\"Ultra\")[rand 10],\r\n      \" \",\r\n      (\"Mummies\",\"Elephants\",\"Midgets\",\"Ninjas\",\"Squirrels\",\"Chickens\",\"Geese\",\"Monkeys\",\"Geese\")[rand 9],\r\n      \" for <A href=$I{rootdir}/users.pl>$I{U}{nickname}</A> ($I{U}{uid}).</B>\r\n	</FONT><P>\";\r\n	$SECT->{artcount}=$I{U}{maxstories};\r\n\r\n}\r\n\r\n\r\nmy $stories=$I{dbobject}->getStories(\$I{U},\$I{F},$SECT,$I{currentSection});\r\ndisplayStories($stories);\r\n\r\nunless($I{U}{noboxes}) {\r\n	print \"</TD><TD width=210 align=center valign=top>\";\r\n	displayStandardBlocks($SECT,$stories);\r\n}\r\n\r\n', blockbak = 'if($I{U}{uid} > 0) {\r\nsrand();\r\nprint \"<FONT size=1><B> This page was generated by a \",\r\n      (\"Million\",\"Team\",\"Squadron\",\"Group\",\"Cadre\")[rand 5],\r\n      \" of \",\r\n      (\"Attack\",\"Circus\",\"Albino\",\"Trained\",\"Stealth\",\"Super\",\"Elite\",\"Random\",\"Orange\",\"Ultra\")[rand 10],\r\n      \" \",\r\n      (\"Mummies\",\"Elephants\",\"Midgets\",\"Ninjas\",\"Squirrels\",\"Chickens\",\"Geese\",\"Monkeys\",\"Geese\")[rand 9],\r\n      \" for <A href=$I{rootdir}/users.pl>$I{U}{nickname}</A> ($I{U}{uid}).</B>\r\n	</FONT><P>\";\r\n	$SECT->{artcount}=$I{U}{maxstories};\r\n\r\n}\r\n\r\n\r\nmy $stories=$I{dbobject}->getStories(\$I{U},\$I{F},$SECT,$I{currentSection});\r\ndisplayStories($stories);\r\n\r\nunless($I{U}{noboxes}) {\r\n	print \"</TD><TD width=210 align=center valign=top>\";\r\n	displayStandardBlocks($SECT,$stories);\r\n}\r\n\r\n' where bid = 'index2';
