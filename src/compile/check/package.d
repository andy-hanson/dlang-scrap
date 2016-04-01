module compile.check;

import ast : Expr, ModuleAst, TypeAst;
import compile.compileContext : CompileContext;

import bind : Binding, Bindings, getBindings;
import type : Type;
import typeCheck : typeCheck;

Checks checkAll(ModuleAst mod, CompileContext ctx) {
	auto bindings = getBindings(mod, ctx);
	auto types = typeCheck(mod, bindings, ctx);
	return new Checks(bindings, types);
}

final immutable class Checks_C {
	Binding binding(Expr.Access a) {
		return bindings[a];
	}

	Type binding(TypeAst.Access a) {
		return bindings[a];
	}

private:
	this(Bindings bindings, immutable Type[Expr] types) {
		this.bindings = bindings;
		this.types = types;
	}

	Bindings bindings;
	Type[Expr] types;
}
alias Checks = immutable Checks_C;
