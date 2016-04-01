import std.algorithm : map;
import std.array : join;
import std.format : format;

import decl : Decl;
import loc : Loc;

abstract immutable class Ast {
	Loc loc;
	
	this(Loc loc) pure {
		this.loc = loc;
	}
	
	abstract string show() pure;
}

final immutable class ModuleAst_C : Ast {
	Decl[] decls;
	
	this(Loc loc, immutable Decl[] decls) pure {
		super(loc);
		this.decls = decls;
	}
	
	override string show() const pure {
		return "ModuleAst(%s)".format(decls.map!((immutable(Decl) d) => d.show).join(" "));
	}
}
alias ModuleAst = immutable ModuleAst_C;
