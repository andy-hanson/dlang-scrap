module compile.parse.lex.reader;

import std.algorithm : endsWith;
import std.conv : parse;
import std.regex : ctRegex, matchFirst, StaticRegex;

import ast : Expr;
import compile.compileContext : CompileContext;
import loc : Loc, Pos;
import symbol : Name, TypeName;
import util : isInRange;

//TODO:STRUCT
class Reader {
	string source;
	immutable(char)* ptr;
	immutable(char)* endPtr;
	// TODO: just use a Pos
	ushort line;
	ushort column;

	this(string source) pure {
		// Lexing algorithm requires ending newline to close any blocks.
		if (!source.endsWith('\n'))
			source ~= '\n';
		source ~= '\0';
		this.source = source;
		ptr = source.ptr;
		endPtr = ptr + source.length;
	}

	void goBack() pure {
		ptr--;
		column--;
	}

	Pos pos() pure {
		return Pos(line, column);
	}

	Loc locFrom(Pos start) pure {
		return Loc(start, pos());
	}

	bool canPeek(int n = 0) pure {
		auto peekPtr = ptr + n;
		return ptr <= peekPtr && peekPtr < endPtr;
	}

	char peek(int n = 0) pure {
		return *(ptr + n);
	}

	char eat() pure {
		auto ch = peek();
		skip();
		return ch;
	}

	void skip(int n = 1)() pure {
		ptr += n;
		column += n;
	}

	bool tryEat(char charToEat) pure {
		return tryEatIf(ch => ch == charToEat);
	}

	bool tryEatIf(bool delegate(char) pure pred) pure {
		bool canEat = pred(peek());
		if (canEat)
			skip();
		return canEat;
	}

	void skipRestOfLine() {
		skipUntilRegex(ctRegex!r"\n");
	}

	string takeRestOfLine() {
		return takeUntilRegex(ctRegex!r"\n");
	}

	uint skipTabs() {
		return skipUntilRegex(ctRegex!r"[^\t]");
	}

	int takeIntBinary() {
		string s = takeUntilRegex(ctRegex!"[^01]");
		return parse!(int, string)(s, 2);
	}

	int takeIntHex() {
		string s = takeUntilRegex(ctRegex!"[^0-9a-f]");
		return parse!(int, string)(s, 16);
	}

	Expr.Literal.Value takeNumDecimal() {
		auto start = ptr - 1;
		skipUntilRegex(ctRegex!"[^0-9]");
		if (peek() == '.') {
			if (peek(1).isInRange('0', '9')) {
				skip();
				skipUntilRegex(ctRegex!"[^0-9]");
			}
			string s = sliceFrom(start);
			return new Expr.Literal.Value.Real(parse!double(s));
		} else {
			string s = sliceFrom(start);
			return new Expr.Literal.Value.Int(parse!int(s));
		}
	}

	uint skipNewlines() pure {
		uint startLine = line;
		line++;
		while (peek() == '\n') {
			ptr++;
			line++;
		}
		column = Pos.start.column;
		return line - startLine;
	}

	string takeNameLike() {
		auto start = ptr - 1;
		skipUntilRegex(ctRegex!r"[^a-zA-Z0-9\\+\\-\\*\\/\\=\\?]");
		return sliceFrom(start);
	}

private:
	// TODO: matchFirst is impure?
	uint skipUntilRegex(StaticRegex!char rgx) {
		auto capture = matchFirst(remainingSlice(), rgx);
		if (!capture)
			throw new Error("TODO");
		auto newPtr = capture.hit.ptr;

		uint diff = cast(uint) (newPtr - ptr);
		ptr = newPtr;
		column += diff;

		return diff;
	}

	string takeUntilRegex(StaticRegex!char rgx) {
		auto start = ptr;
		skipUntilRegex(rgx);
		return sliceFrom(start);
	}

	string remainingSlice() pure {
		return slice(ptr, endPtr);
	}

	string sliceFrom(immutable(char)* start) pure {
		return slice(start, ptr);
	}

	static string slice(immutable(char)* start, immutable(char)* end) pure {
		return start[0..(end - start)];
	}
}
