
%{
#include <stdio.h>
#include "hash.h"
#include "array.h"
#include "vm.h"
#include "types.h"
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
stack						{return STACK;}
commands					{return COMMANDS;}
true						{return TRUE;}
false						{return FALSE;}
[ \t]+						{/* ignore return WHITESPACE; */}
\n							{return NEWLINE;}
[a-zA-Z_][a-zA-Z0-9_]*		{ yylval.str = strdup(yytext); return IDENTIFIER; }
\"(\\.|[^\\"])*\"			{ yylval.str = strdup(yytext); return STRING_LITERAL;}
-							{return (int) yytext[0];}
\.							{return (int) yytext[0];}
\/							{return (int) yytext[0];}
((([0-9]*\.)+[0-9]+))		{ yylval.float_value = atof(yytext); return FLOAT_LITERAL; }
(0x[0-9a-f]+)				{ yylval.int_value = strtol(yytext, NULL, 0); return HEX_LITERAL; }
([0-9]+)					{ yylval.int_value = atol(yytext); return INT_LITERAL; }
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
