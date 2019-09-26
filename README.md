# language
A toy language to learn flex and bison.

expression
	: NUMBER 
	| expression '+' expression { $$ = $1 + $3; }
	| expression '-' expression { $$ = $1 - $3; }
	| expression '*' expression { $$ = $1 * $3; }
	| expression '/' expression { $$ = $1 / $3; }
	| '-' expression { $$ = -$2; }
	| expression '^' expression { $$ = pow($1, $3); }
	| '(' expression ')' { $$ = $2; }
	;

assignment
	: WORD '=' NUMBER
	{
		float *p = &($3);
		if (map_put(variables, $1, strlen($1), (uint8_t*)p, sizeof(float))){
			fprintf(stderr, "out of memory for variables.\n");
		}
		printf("Command: %s = %f\n", $1, $3);
		free($1);
	}
	;

command
	: PRINT '(' WORD ')'
	{
		float *p;
		size_t size;
		if(map_get(variables, $3, strlen($3), (uint8_t*)p, &size)){
			fprintf(stderr, "out of memory for variables.\n");
		}
		printf("%f\n", *p);
		free($3);
	}
	;
