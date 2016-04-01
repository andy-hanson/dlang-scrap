import ast : Decl, Expr, ModuleAst;
import loc : Loc;

import bind : Bindings;
import compile.compileContext : CompileContext;
import type : Type;

immutable(Type[Expr]) typeCheck(ModuleAst mod, Bindings bindings, CompileContext ctx) {
	Type[Expr] res;
	return cast(immutable) res; //TODO
}
