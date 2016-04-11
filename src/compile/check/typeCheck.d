module compile.check.typeCheck;

import ast : Decl, Expr, ModuleAst;
import loc : Loc;

import compile.compileContext : CompileContext;
import compile.type : Type;

import compile.check.bind : Bindings;

immutable(Type[Expr]) typeCheck(ModuleAst mod, Bindings bindings, CompileContext ctx) {
	Type[Expr] res;
	return cast(immutable) res; //TODO
}
