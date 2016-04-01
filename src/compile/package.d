module compile;

import ast : Decl, ModuleAst;
import loc : Loc, Pos;

ModuleAst compile(string source) pure {
	Pos pos = Pos(1, 2);
	Loc loc = Loc(pos, pos);
	immutable Decl[] decls;
	return new ModuleAst(loc, decls);
}
