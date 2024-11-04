%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    char* lexeme;
    int position;
} SymbolTableEntry;

SymbolTableEntry symbolTable[1000];
int stCount = 0;

typedef struct {
    char* token;
    char* value;
    int line;
    int column;
} PIFEntry;

PIFEntry pif[1000];
int pifCount = 0;

int line_num = 1;
int col_num = 1;

void addSymbolTable(char* lexeme) {
    symbolTable[stCount].lexeme = strdup(lexeme);
    symbolTable[stCount].position = stCount;
    stCount++;
}

int lookupSymbolTable(char* lexeme) {
    for (int i = 0; i < stCount; i++) {
        if (strcmp(symbolTable[i].lexeme, lexeme) == 0) return i;
    }
    addSymbolTable(lexeme);
    return stCount - 1;
}

void addPIF(char* token, char* value) {
    pif[pifCount].token = strdup(token);
    pif[pifCount].value = strdup(value);
    pif[pifCount].line = line_num;
    pif[pifCount].column = col_num;
    pifCount++;
}

void printSymbolTable() {
    printf("\nSymbol Table:\n");
    for (int i = 0; i < stCount; i++) {
        printf("%d: %s\n", i, symbolTable[i].lexeme);
    }
}

void printPIF() {
    printf("\nProgram Internal Form:\n");
    for (int i = 0; i < pifCount; i++) {
        printf("Token: %s, Value: %s, Line: %d, Column: %d\n",
               pif[i].token, pif[i].value, pif[i].line, pif[i].column);
    }
}

%}

%%

\n                  { line_num++; col_num = 1; }
[ \t]+              { col_num += yyleng; }

(var|const|let|int|bool|do|if|else|then|while|for|read|write|START|END) {
    addPIF("RESERVED", yytext);
    col_num += yyleng;
}

(\+|\-|\*|\/|=|>=|<=|<|>|!=|==|===) {
    addPIF("OPERATOR", yytext);
    col_num += yyleng;
}

(;|:|\{|\}|\[|\]) {
    addPIF("SEPARATOR", yytext);
    col_num += yyleng;
}

[a-zA-Z][a-zA-Z0-9_]* {
    if (strcmp(yytext, "true") == 0 || strcmp(yytext, "false") == 0) {
        addPIF("BOOL_CONST", yytext);
    } else {
        int pos = lookupSymbolTable(yytext);
        char posStr[10];
        sprintf(posStr, "%d", pos);
        addPIF("IDENTIFIER", posStr);
    }
    col_num += yyleng;
}

[0-9]+ {
    int pos = lookupSymbolTable(yytext);
    char posStr[10];
    sprintf(posStr, "%d", pos);
    addPIF("INT_CONST", posStr);
    col_num += yyleng;
}

. {
    fprintf(stderr, "Lexical error at line %d, column %d: Unrecognized character '%s'\n",
            line_num, col_num, yytext);
    col_num += yyleng;
}

%%

int main(int argc, char** argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }
    FILE* file = fopen(argv[1], "r");
    if (!file) {
        perror("Error opening file");
        return 1;
    }
    yyin = file;
    yylex();

    printSymbolTable();
    printPIF();
    fclose(file);
    return 0;
}
