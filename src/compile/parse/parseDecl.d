module compile.parse.parseDecl;

import ast : Decl, Property, Signature;
import loc : Pos;
import util.option : Option;

import compile.parse.lex.token : Token;
import compile.parse.parseExpr : parseBlock;
import compile.parse.parser : Parser;

Option!Decl tryParseDecl(ref Parser p) {
	Pos start = p.curPos;
	auto first = p.next();
	switch (first.kind) with (Token.Kind) {
		case end: return Option!Decl.none;
		case fn: return Option!Decl(p.parseFn(start));
		case rec: return Option!Decl(p.parseRec(start));
		default: throw p.unexpected(first);
	}
}

private:

Decl.Val.Fn parseFn(ref Parser p, Pos start) {
	auto name = p.parseName();
	auto sig = p.parseSignature();
	auto value = p.parseBlock();
	return new Decl.Val.Fn(p.locFrom(start), name, sig, value);
}

Decl.Type.Rec parseRec(ref Parser p, Pos start) {
	auto name = p.parseTypeName();
	p.expect(Token.Kind.indent);
	auto props = p.parseProperties();
	return new Decl.Type.Rec(p.locFrom(start), name, props);
}

immutable(Property[]) parseProperties(ref Parser p) {
	Pos start = p.curPos;
	Property[] res;
	loop: for (;;) {
		auto t = p.next();
		Pos propStart = t.loc.start;
		switch (t.kind) with (Token.Kind) {
			case name:
				auto name = t.name();
				auto type = p.parseType();
				res ~= new Property(p.locFrom(propStart), name, type);
				break;
			case dedent:
				break loop;
			default:
				throw p.unexpected(t);
		}
	}
	return res;
}

// Eats the \n at the end.
Signature parseSignature(ref Parser p) {
	Pos start = p.curPos;
	auto returnType = p.parseType();
	
	Signature.Parameter[] params;
	for (;;) {
		Pos paramStart = p.curPos;
		if (p.tryEatIndent())
			break;
		auto name = p.parseName();
		auto type = p.parseType();
		params ~= new Signature.Parameter(p.locFrom(paramStart), name, type);
	}

	return new Signature(p.locFrom(start), returnType, params);
}
