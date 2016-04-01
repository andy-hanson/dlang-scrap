import std.algorithm : map;
import std.array : join;
import std.format : format;

import node : Ast;
import expr : Expr;
import typeAst : TypeAst;
import loc : Loc;
import symbol : Name, TypeName;

abstract immutable class Decl_C : Ast {
	static abstract class Visitor {
		void visit(Decl.Val.Fn decl);
	}
	abstract void accept(Visitor v);
	private mixin template Visitable() {
		override void accept(Visitor v) {
			v.visit(this);
		}
	}

	this(Loc loc) pure {
		super(loc);
	}
	
	static abstract immutable class Val_C : Decl {
		Name name;
		
		this(Loc loc, Name name) pure {
			super(loc);
			this.name = name;
		}
		
		static final immutable class Fn_C : Val {
			Signature sig;
			Expr value;
			
			this(Loc loc, Name name, Signature sig, Expr value) pure {
				super(loc, name);
				this.sig = sig;
				this.value = value;
			}
			
			override string show() {
				return "Fn(%s, %s, %s)".format(name.value, sig.show, value.show);
			}
			mixin Visitable;
		}
		alias Fn = immutable Fn_C;
	}
	alias Val = immutable Val_C;
	
	static abstract immutable class Type_C : Decl {
		TypeName name;

		this(Loc loc, TypeName name) {
			super(loc);
			this.name = name;
		}

		//static final immutable class Rec_C : Type {

		//}
	}
	alias Type = immutable Type_C;
	
	//match
}
alias Decl = Decl_C;
		
static final immutable class Signature_C : Ast {
	TypeAst returnType;
	Parameter[] params;
	
	this(Loc loc, TypeAst returnType, Parameter[] params) pure {
		super(loc);
		this.returnType = returnType;
		this.params = params;
	}
	
	override string show() {
		return "Signature(%s, %s)".format(returnType.show, params.map!(p => p.show).join(" "));
	}
	
	static final class Parameter_C : Ast {
		Name name;
		TypeAst type;
		
		this(Loc loc, Name name, TypeAst type) pure {
			super(loc);
			this.name = name;
			this.type = type;
		}
		
		override string show() {
			return "Parameter(%s, %s)".format(name.value, type.show);
		}
	}
	alias Parameter = immutable Parameter_C;
}
alias Signature = immutable Signature_C;
