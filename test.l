
%{
#include <stdio.h>
#include "hash.h"
#include "array.h"
#include "vm.h"
#include "types.h"
#include "test.tab.h"
%}

%%
VM_PUSH						{return VM_PUSH;}
VM_PUSH_BYTE				{return VM_PUSH_BYTE;}
VM_PUSH_INT					{return VM_PUSH_INT;}
VM_PUSH_UINT				{return VM_PUSH_UINT;}
VM_PUSH_FLOAT				{return VM_PUSH_FLOAT;}
VM_SET_BYTE					{return VM_SET_BYTE;}
VM_SET_INT					{return VM_SET_INT;}
VM_SET_UINT					{return VM_SET_UINT;}
VM_SET_FLOAT				{return VM_SET_FLOAT;}
VM_MALLOC					{return VM_MALLOC;}
VM_FREE						{return VM_FREE;}
VM_ADD						{return VM_ADD;}
VM_SUB						{return VM_SUB;}
VM_MULT						{return VM_MULT;}
VM_DIV						{return VM_DIV;}
VM_AND						{return VM_AND;}
VM_OR						{return VM_OR;}
VM_XOR						{return VM_XOR;}
VM_NOT						{return VM_NOT;}
VM_JUMP						{return VM_JUMP;}
VM_JCOND					{return VM_JCOND;}
VM_POP						{return VM_POP;}

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
dump						{return DUMP;}
PRINT						{return PRINT;}
STACK						{return STACK;}
COMMANDS					{return COMMANDS;}
true						{return TRUE;}
false						{return FALSE;}
goto						{return GOTO;}
[ \t]+						{/* ignore return WHITESPACE; */}
#.+							{/* ignore return COMMENTS; */}
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
