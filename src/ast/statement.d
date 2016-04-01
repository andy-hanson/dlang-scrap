import loc : Loc;

import node : Ast;

abstract class Statement_C : Ast {
	this(Loc loc) pure {
		super(loc);
	}
}
alias Statement = immutable Statement_C;
