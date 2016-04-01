import std.algorithm : map;
import std.array : join;
import std.conv : to;
import std.format : format;

import ast : Expr;
import loc : Loc;
static import symbol;
alias SName = symbol.Name;
alias STypeName = symbol.TypeName;
import util.array : isEmpty;

abstract immutable class Token_C {
	abstract string show() pure;
	Loc loc;
	
	this(Loc loc) pure {
		this.loc = loc;
	}
	
	static final immutable class Keyword_C : Token {
		Kind kind;
		
		this(Loc loc, Kind kind) pure {
			super(loc);
			this.kind = kind;
		}
		
		static enum Kind {
			case_,
			colon,
			comma,
			cond,
			false_,
			fn,
			ifc,
			rec,
			true_
		}

		override string show() pure {
			return to!string(kind);
		}

		static bool match(Token token, Kind kind) pure {
			Keyword keyword = cast(Keyword) token;
			return keyword !is null && keyword.kind == kind;
		}
	}
	alias Keyword = immutable Keyword_C;
	
	static final immutable class Name_C : Token {
		SName name;
		
		this(Loc loc, SName name) pure {
			super(loc);
			this.name = name;
		}

		override string show() {
			return name.value;
		}
	}
	alias Name = immutable Name_C;
	
	static final class TypeName_C : Token {
		STypeName name;
		
		this(Loc loc, STypeName name) pure {
			super(loc);
			this.name = name;
		}

		override string show() {
			return name.value;
		}
	}
	alias TypeName = immutable TypeName_C;

	static abstract class Group_C : Token {//(Self : Group!(Self, Subtype), SubType : Token) : AnyGroup {
		this(Loc loc) pure {
			super(loc);
		}

		abstract bool isEmpty() pure;

		static final class Block_C : Group {
			Line[] subTokens;

			override bool isEmpty() {
				return subTokens.isEmpty;
			}

			this(Loc loc, Line[] subTokens) pure {
				super(loc);
				this.subTokens = subTokens;
			}

			//override string typeName() { return "Block"; }
			override string show() pure {
				return "Block(%s)".format(subTokens.map!(t => t.show).join(" "));
			}
		}
		alias Block = immutable Block_C;

		static final class Line_C : Group {
			Token[] subTokens;

			override bool isEmpty() {
				return subTokens.isEmpty;
			}

			this(Loc loc, Token[] subTokens) pure {
				super(loc);
				this.subTokens = subTokens;
			}

			//override string typeName() { return "Line"; }
			override string show() pure {
				return "Line(%s)".format(subTokens.map!(t => t.show).join(" "));
			}
		}
		alias Line = immutable Line_C;
	}
	alias Group = immutable Group_C;
	
	static final immutable class Literal_C : Token {
		Expr.Literal.Value value;

		this(Loc loc, Expr.Literal.Value value) pure {
			super(loc);
			this.value = value;
		}

		override string show() {
			return value.show;
		}
	}
	alias Literal = immutable Literal_C;
	
	static final immutable class DocComment_C : Token {
		string text;
		
		this(Loc loc, string text) pure {
			super(loc);
			this.text = text;
		}
	}
	alias DocComment = immutable DocComment_C;
}
alias Token = immutable Token_C;

