module compile.parse.parser;

//TOOD: clean up imports
import ast : Decl, ModuleAst, Signature, Statement, TypeAst;
import loc : Loc, Pos;
import symbol : Name, TypeName;
import util.option : Option;

import compile.compileContext : CompileContext, CompileException;

import compile.parse.lex.token : Token;
import compile.parse.parseDecl : tryParseDecl;
import compile.parse.parseExpr : parseBlock, parseExpr;

struct Parser {
	CompileContext ctx;
	immutable(Token)* curToken;

	this(immutable Token[] tokens, CompileContext ctx) {
		this.curToken = tokens.ptr;
		this.ctx = ctx;
	}

	Pos curPos() {
		return peek.loc.start;
	}

	Loc locFrom(Pos start) {
		return Loc(start, peek(-1).loc.end);
	}

	Token peek(int offset = 0) {
		return *(curToken + offset);
	}

	Token next() {
		Token t = *curToken;
		curToken++;
		return t;
	}

	void backUp() {
		curToken--;
	}

	void skip() {
		curToken++;
	}

	Token expect(Token.Kind kind) {
		auto t = next();
		if (t.kind != kind)
			throw unexpected(t);
		return t;
	}

	Name parseName() {
		auto name = next();
		return name.opName.orThrow(unexpected(name));
	}

	TypeName parseTypeName() {
		auto name = next();
		return name.opTypeName.orThrow(unexpected(name));
	}

	TypeAst parseType() {
		auto type = next();
		auto typeName = type.opTypeName.orThrow(unexpected(type));
		return new TypeAst.Access(type.loc, typeName);
	}

	bool tryEatKind(Token.Kind kind) {
		if (peek.kind == kind) {
			next();
			return true;
		} else
			return false;
	}

	bool tryEatIndent() {
		return tryEatKind(Token.Kind.indent);
	}

	CompileException unexpected(Token token) pure {
		return ctx.fail(token.loc, l => l.unexpected(token));
	}

	Statement parseStatement() {
		if (peek(1).kind == Token.Kind.equals) {
			Pos start = curPos;
			auto name = parseName();
			skip(); // The '=' sign
			auto expr = this.parseExpr();
			return new Statement.Declare(locFrom(start), name, expr);
		} else
			return this.parseExpr();
	}
}
