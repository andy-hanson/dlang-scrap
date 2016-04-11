module compile.parse.parseModule;

import ast : Decl, ModuleAst;
import loc : Pos;

import compile.parse.parseDecl : tryParseDecl;
import compile.parse.parser : Parser;

ModuleAst parseModule(ref Parser p) {
	Pos start = p.curPos;

	Decl[] decls;
	for (;;) {
		auto d = p.tryParseDecl();
		if (d.hasValue)
			decls ~= d.value;
		else
			break;
	}

	return new ModuleAst(p.locFrom(start), decls);
}
