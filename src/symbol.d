import std.format : format;

import compile.check.binding : Binding;
import loc : Loc;
import token : Token;
import type : Type;

class Symbols {
	this() {
		//TODO:MOVE
		with (Token.Keyword.Kind)
			nameToKeyword = [
				name("case"): case_,
				name("cond"): cond,
				name("false"): false_,
				name("fn"): fn,
				name("ifc"): ifc,
				name("rec"): rec,
				name("true"): true_
			];

		//TODO:MOVE
		nameToBuiltin = Binding.Builtin.nameToBuiltin(&this.name);
		typeNameToBuiltin = Type.Builtin.nameToBuiltin(&this.typeName);
	}

	//TODO:Option!(Token.Keyword)
	Token.Keyword keywordFromName(Loc loc, Name name) {
		auto kind = nameToKeyword.get(name, cast(Token.Keyword.Kind) -1);
		return kind == -1 ? null : new Token.Keyword(loc, kind);
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
	immutable Token.Keyword.Kind[Name] nameToKeyword;
}

struct Name {
	mixin Symbol!Name;
}
struct TypeName {
	mixin Symbol!TypeName;
}

private:

struct SymbolTable(Symbol) {
	Symbol get(string s) pure {
		Symbol old = table.get(s, Symbol(null));
		if (old.value == null) {
			auto newEntry = Symbol(s);
			table[s] = newEntry;
			return newEntry;
		} else
			return old;
	}

private:
	Symbol[string] table;
}


private:

mixin template Symbol(T) {
	string value;

	bool opEquals(ref const T other) const pure {
		return value is other.value;
	}

	string show() const pure {
		return "%s(%s)".format(T.mangleof, value);
	}

	private:
		this(string s) pure { value = s; }
}

/*
struct SymbolTable(string T) {
	struct Symbol {
		string value;

		bool opEquals(ref const Symbol other) const pure nothrow {
			return value is other.value;
		}

		string show() const pure {
			return "%s(%s)".format(T, value);
		}

	private:
		this(string s) { value = s; }
	}

	//TODO: nothrow
	Symbol get(string s) pure @safe {
		Symbol old = table.get(s, Symbol(null));
		if (old.value == null) {
			auto newEntry = Symbol(s);
			table[s] = newEntry;
			return newEntry;
		} else
			return old;
	}

private:
	Symbol[string] table;
}

alias NameTable = SymbolTable!"Name";
alias Name = immutable NameTable.Symbol;
alias TypeNameTable = SymbolTable!"TypeName";
alias TypeName = immutable TypeNameTable.Symbol;
*/


/*
struct Name {
	string value;

	// TODO: use a trie
	static Name[string] table;

	static Name of(string s) {
		return table.get(s, Name(s));
	}

private:
	this(string s) {
		value = s;
	}
}

struct TypeName {
	string value;

	static TypeName[string] table;

	static TypeName of(string s) {
		return table.get(s, TypeName(s));
	}

	bool opBinary(op)(TypeName other) {

	}

private:
	this(string s) {
		value = s;
	}
}
*/
