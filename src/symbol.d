import std.format : format;

import compile.check.binding : Binding;
import compile.parse.lex.token : Token;
import compile.type : Type;
import loc : Loc;
import util.option : Option;

class Symbols {
	this() {
		//TODO:MOVE
		alias n = name;

		with (Token.Kind)
			nameToKeyword = [
				n("and"): and,
				n("case"): case_,
				n("cond"): cond,
				n("="): equals,
				n("false"): false_,
				n("fn"): fn,
				n("if"): if_,
				n("ifc"): ifc,
				n("or"): or,
				n("rec"): rec,
				n("true"): true_,
				n("unless"): unless
			];

		//TODO:MOVE
		nameToBuiltin = Binding.Builtin.nameToBuiltin(&this.name);
		typeNameToBuiltin = Type.Builtin.nameToBuiltin(&this.typeName);
	}

	Option!(Token.Kind) keywordFromName(Name name) {
		auto kind = nameToKeyword.get(name, cast(Token.Kind) -1);
		return Option!(Token.Kind).iff(kind != -1, kind);
	}

	Name name(string s) pure {
		return names.get(s);
	}

	TypeName typeName(string s) pure {
		return typeNames.get(s);
	}

	immutable Binding.Builtin[Name] nameToBuiltin;
	immutable Type.Builtin[TypeName] typeNameToBuiltin;

private:
	SymbolTable!Name names;
	SymbolTable!TypeName typeNames;
	immutable Token.Kind[Name] nameToKeyword;
}

struct Name {
	mixin Symbol!Name;
}
struct TypeName {
	mixin Symbol!TypeName;
}

private:

struct SymbolTable(Symbol) {
	Symbol[string] table;
	
	Symbol get(string s) pure {
		Symbol old = table.get(s, Symbol(null));
		if (old.value == null) {
			auto newEntry = Symbol(s);
			table[s] = newEntry;
			return newEntry;
		} else
			return old;
	}
}

mixin template Symbol(T) {
	string value;

	bool opEquals(ref const T other) const pure {
		return value is other.value;
	}

	string show() const pure {
		return value;
	}

	private:
		this(string s) pure { value = s; }
}
