module compile.compileContext;

import std.format : format;
import std.typecons : NullableRef;

import compile.language;
import loc : Loc, Pos;
import symbol : Name, Symbols;
import util.option : Opt;

import token : Token;

class CompileContext {
	Symbols symbols;

	this(Symbols symbols) {
		this.symbols = symbols;
	}

	private immutable Language language = English.instance;
	private ErrorMessage[] warnings;

	alias Message = string delegate(immutable Language) pure;

	void check(bool condition, lazy Loc loc, lazy Message message) pure {
		if (!condition)
			throw fail(loc, message);
	}

	void check(bool condition, lazy Pos pos, lazy Message message) pure {
		if (!condition)
			throw fail(pos, message);
	}

	CompileException fail(Loc loc, Message message) pure {
		return new CompileException(errorMessage(loc, message));
	}

	CompileException fail(Pos pos, Message message) pure {
		return new CompileException(errorMessage(Loc.singleChar(pos), message));
	}

	void warn(Loc loc, Message message) pure {
		warnings ~= errorMessage(loc, message);
	}

	void warn(Pos pos, Message message) pure {
		warn(Loc.singleChar(pos), message);
	}

private:
	ErrorMessage errorMessage(Loc loc, Message message) pure {
		return ErrorMessage(loc, message(language));
	}
}

class CompileException : Exception {
	this(ErrorMessage message) pure {
		super("%s: %s".format(message.loc.show, message.message));
	}
}

struct ErrorMessage {
	Loc loc;
	string message;
}
