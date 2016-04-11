module ast.statement;

import std.format : format;

import loc : Loc;
import symbol : Name;

import ast.expr : Expr;
import ast.node : Ast;

abstract class Statement_C : Ast {
	this(Loc loc) pure {
		super(loc);
	}

	static final immutable class Declare_C : Statement {
		Name name;
		Expr value;

		this(Loc loc, Name name, Expr value) pure {
			super(loc);
			this.name = name;
			this.value = value;
		}
		
		override string show() {
			return "Declare(%s, %s)".format(name.show, value.show);
		}
	}
	alias Declare = immutable Declare_C;
}
alias Statement = immutable Statement_C;
