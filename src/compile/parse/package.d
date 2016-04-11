module compile.parse;

import ast : ModuleAst;
import compile.compileContext : CompileContext;

import compile.parse.lex : lex;
import compile.parse.parser : Parser;
import compile.parse.parseModule : parseModule;

ModuleAst parse(string source, CompileContext ctx) {
	auto tokens = lex(source, ctx);
	//foreach (t; tokens)
	//	writeln(t.show);
	Parser p = Parser(tokens, ctx);
	return p.parseModule();
}
