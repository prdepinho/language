
%{
#include <stdio.h>
#include "test.tab.h"
%}

%%
_							{return UNDERLINE;}
print						{return PRINT;}
[ \t]+						{/* ignore return WHITESPACE; */}
\n							{return NEWLINE;}
[a-zA-Z_][a-zA-Z0-9_]*		{ yylval.str = strdup(yytext); return WORD; }
\"(\\.|[^\\"])*\"			{ yylval.str = strdup(yytext); return STRING_LITERAL;}
-							{return (int) yytext[0];}
\.							{return (int) yytext[0];}
\/							{return (int) yytext[0];}
((([0-9]*\.)?[0-9]+))		{ yylval.number = atof(yytext); return NUMBER; }
`							{return (int) yytext[0];}
~							{return (int) yytext[0];}
!							{return (int) yytext[0];}
@							{return (int) yytext[0];}
#							{return (int) yytext[0];}
\$							{return (int) yytext[0];}
%							{return (int) yytext[0];}
\^							{return (int) yytext[0];}
&							{return (int) yytext[0];}
\*							{return (int) yytext[0];}
=							{return (int) yytext[0];}
\+							{return (int) yytext[0];}
\(							{return (int) yytext[0];}
\)							{return (int) yytext[0];}
\[							{return (int) yytext[0];}
\]							{return (int) yytext[0];}
\{							{return (int) yytext[0];}
\}							{return (int) yytext[0];}
\\							{return (int) yytext[0];}
\|							{return (int) yytext[0];}
:							{return (int) yytext[0];}
;							{return (int) yytext[0];}
'							{return (int) yytext[0];}
\"							{return (int) yytext[0];}
,							{return (int) yytext[0];}
\<							{return (int) yytext[0];}
\>							{return (int) yytext[0];}
\?							{return (int) yytext[0];}
%%
