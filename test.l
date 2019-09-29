
%{
#include <stdio.h>
#include "test.tab.h"
%}

%%
_							{return UNDERLINE;}
quit						{return QUIT;}
exit						{return EXIT;}
byte						{return BYTE;}
int							{return INT;}
uint						{return UINT;}
long						{return LONG;}
ulong						{return ULONG;}
float						{return FLOAT;}
double						{return DOUBLE;}
bool						{return BOOL;}
string						{return STRING;}
pure						{return PURE;}
print						{return PRINT;}
true						{return TRUE;}
false						{return FALSE;}
[ \t]+						{/* ignore return WHITESPACE; */}
\n							{return NEWLINE;}
[a-zA-Z_][a-zA-Z0-9_]*		{ yylval.str = strdup(yytext); return IDENTIFIER; }
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
