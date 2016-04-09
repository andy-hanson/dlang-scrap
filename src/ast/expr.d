import std.algorithm : map;
import std.array : join;
import std.conv : to;
import std.format : format;

import run.any : Any;
import loc : Loc;
import symbol : Name;
import util : floatToString;

import node : Ast;
import statement : Statement;

abstract immutable class Expr_C : Statement {
	static abstract class VisitorAny {
		mixin template V(T) {
			void* visit(T e, void* p);
		}
		mixin V!(Expr.Access);
		mixin V!(Expr.Block);
		mixin V!(Expr.Call);
		mixin V!(Expr.Cond);
		mixin V!(Expr.Literal);	
	}
	static abstract class Visitor(P, R) : VisitorAny {
		mixin template V(T) {
			R visit(T e, P p);
			override void* visit(T e, void* p) {
				return visit(e, cast(P) p);
			}
		}
		mixin V!(Expr.Access);
		mixin V!(Expr.Block);
		mixin V!(Expr.Call);
		mixin V!(Expr.Cond);
		mixin V!(Expr.Literal);
	}
	static abstract class VisitorVoid : VisitorAny {
		final void visitAny(Expr e) {
			e.accept(this);
		}

		void visit(Expr.Access e) { /* no children */ }
		void visit(Expr.Block e) {
			//TODO
			//foreach (line; e.lines)
			//	visitAny(line);
			visitAny(e.returned);
		}
		void visit(Expr.Call e) {
			visitAny(e.called);
			foreach (arg; e.args)
				visitAny(arg);
		}
		void visit(Expr.Cond e) {
			visitAny(e.condition);
			visitAny(e.ifTrue);
			visitAny(e.ifFalse);
		}
		void visit(Expr.Literal e) { /* no children */ }

		private static string v(string name) {
			return "override void* visit(%s e, void* p) { visit(e); return null; }".format(name);
		}
		mixin(v("Expr.Access"));
		mixin(v("Expr.Block"));
		mixin(v("Expr.Call"));
		mixin(v("Expr.Cond"));
		mixin(v("Expr.Literal"));

		/*
		Would prefer to do this. Looks like a compiler bug where it can't find the other `visit` method.

		mixin template V(T) {
			override void* visit(T e, void* p) {
	 			visit(e);
				return null;
			}
		}
		mixin V!(Expr.Access);
		mixin V!(Expr.Block);
		mixin V!(Expr.Call);
		mixin V!(Expr.Cond);
		mixin V!(Expr.Literal);
		*/
	}

	R accept(P, R)(Visitor!(P, R) v, P p) {
		return cast(R) accept(v, cast(void*) p);
	}
	abstract void accept(VisitorVoid v);
	protected abstract void* accept(VisitorAny v, void* p);
	mixin template Visitable() {
		override void accept(VisitorVoid v) {
			v.visit(this);
		}
		override void* accept(VisitorAny v, void* p) {
			return v.visit(this, p);
		}
	}

	this(Loc loc) pure {
		super(loc);
	}

	static final immutable class Access_C : Expr {
		Name name;

		this(Loc loc, Name name) pure {
			super(loc);
			this.name = name;
		}

		override string show() {
			return "Access(%s)".format(name.value);
		}
		mixin Visitable;
	}
	alias Access = immutable Access_C;
	
	//TODO: never allow empty lines
	static final immutable class Block_C : Expr {
		Statement[] lines;
		Expr returned;
		
		this(Loc loc, immutable Statement[] lines, Expr returned) pure {
			super(loc);
			this.lines = lines;
			this.returned = returned;
		}
		
		override string show() {
			return "Block(%s, %s)".format(lines.map!(line => line.show).join(" "), returned.show);
		}
		mixin Visitable;
	}
	alias Block = immutable Block_C;

	static final immutable class Call_C : Expr {
		Expr called;
		Expr[] args;

		this(Loc loc, Expr called, immutable Expr[] args) pure {
			super(loc);
			this.called = called;
			this.args = args;
		}

		override string show() {
			return "Call(%s, %s)".format(called.show, args.map!(a => a.show).join(" "));
		}
		mixin Visitable;
	}
	alias Call = immutable Call_C;

	//static final immutable class Case_C : Expr {

	static final immutable class Cond_C : Expr {
		Expr condition;
		Expr ifTrue;
		Expr ifFalse;

		this(Loc loc, Expr condition, Expr ifTrue, Expr ifFalse) pure {
			super(loc);
			this.condition = condition;
			this.ifTrue = ifTrue;
			this.ifFalse = ifFalse;
		}

		override string show() {
			return "Cond(%s, %s, %s)".format(condition.show, ifTrue.show, ifFalse.show);
		}
		mixin Visitable;
	}
	alias Cond = immutable Cond_C;

	static final immutable class Literal_C : Expr {
		Value value;

		this(Loc loc, Value value) pure {
			super(loc);
			this.value = value;
		}

		override string show() {
			return "Literal(%s)".format(value.show);
		}
		mixin Visitable;

		static abstract immutable class Value_C {
			abstract immutable(Any) toAny() pure;
			abstract string show() pure;

			static final immutable class Bool_C : Value {
				static Bool False = new Bool_C(false);
				static Bool True = new Bool_C(true);
				bool value;
				private this(bool value) pure { this.value = value; }
				override immutable(Any) toAny() { return Any.Bool(value); }
				override string show() { return value ? "true" : "false"; }
			}
			alias Bool = immutable Bool_C;

			static final immutable class Int_C : Value {
				int value;
				this(int value) pure { this.value = value; }
				override immutable(Any) toAny() { return Any.Int(value); }
				override string show() { return to!string(value); }
			}
			alias Int = immutable Int_C;

			static final immutable class Real_C : Value {
				double value;
				this(double value) pure { this.value = value; }
				override immutable(Any) toAny() { return Any.Real(value); }
				override string show() { return floatToString(value); }
			}
			alias Real = immutable Real_C;
		}
		alias Value = immutable Value_C;
	}
	alias Literal = immutable Literal_C;
}
alias Expr = immutable Expr_C;
