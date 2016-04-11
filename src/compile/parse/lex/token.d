module compile.parse.lex.token;

import std.conv : to;
import std.format : format;

import ast : Expr;
import loc : Loc;
import symbol : Name, TypeName;
import util.option : Option;

struct Token {
	Loc loc;
	Kind kind;
	/*
	For Kind.name or Kind.typeName: a string
	For Kind.literal: an Expr.Literal.Value
	*/
	private union Value { Name name; TypeName typeName; Expr.Literal.Value_C literal; };
	Value value;

	this(Loc loc, Kind kind) {
		this.loc = loc;
		this.kind = kind;
	}

	static Token name(Loc loc, Name name) {
		Token t;
		t.loc = loc;
		t.kind = Kind.name;
		t.value.name = name;
		return t;
	}

	static Token typeName(Loc loc, TypeName name) {
		Token t;
		t.loc = loc;
		t.kind = Kind.typeName;
		t.value.typeName = name;
		return t;
	}

	static Token literal(Loc loc, Expr.Literal.Value value) {
		Token t;
		t.loc = loc;
		t.kind = Kind.literal;
		t.value.literal = cast(Expr.Literal.Value_C) value;
		return t;
	}

	Name name() const pure {
		assert(kind == Kind.name);
		return cast(Name) value;
	}

	TypeName typeName() const pure {
		assert(kind == Kind.typeName);
		return cast(TypeName) value;
	}

	Expr.Literal.Value literal() const pure {
		assert(kind == Kind.literal);
		return cast(immutable) value.literal;
	}

	Option!Name opName() const pure {
		return Option!Name.iff(kind == Kind.name, value.name);
	}

	Option!TypeName opTypeName() const pure {
		return Option!TypeName.iff(kind == Kind.typeName, value.typeName);
	}

	string show() const pure {
		//TODO:Better
		switch (kind) {
			case Kind.name:
				return "Token.name(%s)".format(name.show);
			case Kind.typeName:
				return "Token.typeName(%s)".format(typeName.show);
			case Kind.literal:
				return "Token.literal(%s)".format(literal.show);
			default:
				return to!string(kind);
		}
	}

	static enum Kind {
		// Keywords
		and,
		case_,
		colon,
		comma,
		cond,
		equals,
		false_,
		fn,
		if_,
		ifc,
		or,
		rec,
		true_,
		unless,
		
		// Grouping
		indent,
		dedent,
		newline,
		lparen,
		rparen,
		end,

		// Other
		name,
		typeName,
		literal
	}
}
