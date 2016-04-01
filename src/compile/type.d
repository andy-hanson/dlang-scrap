
import ast : Decl;
import symbol : TypeName;

abstract immutable class Type_C {
	static final immutable class Builtin_C : Type {
		Kind kind;

		static enum Kind {
			bool_,
			char_,
			int_,
			int8,
			int16,
			int64,
			real_,
			real64
		}

		static immutable Builtin
			bool_ = new Builtin(Kind.bool_),
			char_ = new Builtin(Kind.char_),
			int_ = new Builtin(Kind.int_),
			int8 = new Builtin(Kind.int8),
			int16 = new Builtin(Kind.int16),
			int64 = new Builtin(Kind.int64),
			real_ = new Builtin(Kind.real_),
			real64 = new Builtin(Kind.real64);

		static immutable(Builtin[TypeName]) nameToBuiltin(TypeName delegate(string) pure name) pure {
			return [
				name("Bool"): bool_,
				name("Char"): char_,
				name("Int"): int_,
				name("Int8"): int8,
				name("Int16"): int16,
				name("Int64"): int64,
				name("Real"): real_,
				name("Real64"): real64
			];
		}

	private:
		this(Kind kind) { this.kind = kind; }
	}
	alias Builtin = immutable Builtin_C;

	static final immutable class Declared_C : Type {
		Decl.Type decl;

		this(Decl.Type decl) {
			this.decl = decl;
		}
	}
	alias Declared = immutable Declared_C;
}
alias Type = immutable Type_C;
