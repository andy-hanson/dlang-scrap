module ast.typeAst;

import std.string : format;

import loc : Loc;
import symbol : TypeName;

import ast.node : Ast;

abstract immutable class TypeAst_C : Ast {
	this(Loc loc) pure {
		super(loc);
	}
	
	static final immutable class Access_C : TypeAst_C {
		TypeName name;
		
		this(Loc loc, TypeName name) pure {
			super(loc);
			this.name = name;
		}
		
		override string show() {
			return "Access(%s)".format(name.value);
		}
	}
	alias Access = immutable Access_C;
}
alias TypeAst = immutable TypeAst_C;
