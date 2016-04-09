module compile.check.binding;

import ast : Decl, Signature;
import compile.compileContext : CompileContext;
import symbol : Name;

abstract immutable class Binding_C {
	static abstract class Visitor {
		void visit(Builtin b);
		void visit(Declared d);
		void visit(Local l);
	}

	abstract void accept(Visitor v);
	private mixin template Visitable() {
		override void accept(Visitor v) {
			v.visit(this);
		}
	}

	// Binds to a builtin.
	static final immutable class Builtin_C : Binding {
		Kind kind;

		private this(Kind kind) pure nothrow @safe {
			this.kind = kind;
		}

		static enum Kind {
			add,
			eq
		}

		static immutable Builtin
			add = new Builtin(Kind.add),
			eq = new Builtin(Kind.eq);

		static immutable(Builtin[Name]) nameToBuiltin(Name delegate(string) pure name) pure {
			return [
				name("+"): add,
				name("=?"): eq
			];
		}

		mixin Visitable;
	}
	alias Builtin = immutable Builtin_C;

	static final immutable class Declared_C : Binding {
		Decl.Val decl;
		this(Decl.Val decl) { this.decl = decl;}
		mixin Visitable;
	}
	alias Declared = immutable Declared_C;

	static final immutable class Local_C : Binding {
		// TODO: more general type (support locals defined like `a = ...`)
		Signature.Parameter declaration;
		this(Signature.Parameter declaration) { this.declaration = declaration; }
		mixin Visitable;
	}
	alias Local = immutable Local_C;
}
alias Binding = immutable Binding_C;
