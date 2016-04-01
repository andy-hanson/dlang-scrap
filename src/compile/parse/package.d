module compile.parse;

import std.algorithm : map;
import std.array : array;

import ast : Decl, ModuleAst, Signature, Statement, TypeAst;
import compile.compileContext : CompileContext, CompileException;
import loc : Loc;
import symbol : Name, TypeName;
import util.option : Option;

import compile.parse.lex : lex;
import parseExpr : parseBlock, parseExpr;
import slice : Lines, Tokens;
import token : Token;

ModuleAst parse(string source, CompileContext ctx) {
	Token.Group.Block root = lex(source, ctx);
	return Parser(ctx).parseModule(Lines(root));
}

struct Parser {
	CompileContext ctx;

	ModuleAst parseModule(Lines lines) pure {
		immutable Decl[] decls = lines.tokens.map!(line => parseDecl(Tokens(line))).array;
		return new ModuleAst(lines.loc, decls);
	}

	immutable(Decl) parseDecl(Tokens tokens) pure {
		auto first = tokens.head;
		auto tail = tokens.tail;

		auto keyword = cast(Token.Keyword) first;
		if (keyword !is null)
			switch (keyword.kind) with (Token.Keyword.Kind) {
				case fn: return parseFn(tail);
				//case REC: return parseRec(tail);
				default: break;
			}
		throw unexpected(first);
	}

	Decl.Val.Fn parseFn(Tokens tokens) pure {
		auto fullLoc = tokens.loc;
		auto block = takeBlock(tokens);

		auto name = parseName(tokens.head);
		tokens = tokens.tail;

		auto sigLoc = tokens.loc;
		auto returnType = takeType(tokens);
		auto params = parseParams(tokens);
		auto sig = new Signature(sigLoc, returnType, params);
		auto value = this.parseBlock(block);

		return new Decl.Val.Fn(fullLoc, name, sig, value);
	}

	Signature.Parameter[] parseParams(Tokens tokens) pure {
		Signature.Parameter[] res;
		while (!tokens.isEmpty) {
			auto start = tokens.loc.start;
			auto name = parseName(tokens.head);
			tokens = tokens.tail();
			auto type = takeType(tokens);
			res ~= new Signature.Parameter(Loc(start, type.loc.end), name, type);
		}
		return res;
	}

	Name parseName(Token token) pure {
		auto name = cast(Token.Name) token;
		if (name is null)
			throw unexpected(token);
		else
			return name.name;
	}

	TypeName parseTypeName(Token token) pure {
		auto name = cast(Token.TypeName) token;
		if (name is null)
			throw unexpected(token);
		else
			return name.name;
	}

	TypeAst takeType(ref Tokens tokens) pure {
		auto type = parseType(tokens.head());
		tokens = tokens.tail();
		return type;
	}

	TypeAst parseType(Token token) pure {
		return new TypeAst.Access(token.loc, parseTypeName(token));
	}

	Statement parseStatement(Tokens tokens) pure {
		// TODO
		return this.parseExpr(tokens);
	}

	Lines takeBlock(ref Tokens tokens) pure {
		return opTakeBlock(tokens).orThrow(ctx.fail(tokens.loc, l => l.expectedBlock()));
	}

	Option!Lines opTakeBlock(ref Tokens tokens) pure {
		if (tokens.isEmpty)
			return Option!Lines.none;
		else {
			auto block = cast(Token.Group.Block) tokens.last;
			if (block is null)
				return Option!Lines.none;
			else {
				tokens = tokens.rtail;
				return Option!Lines(Lines(block));
			}
		}
	}

	CompileException unexpected(Token token) pure {
		return ctx.fail(token.loc, l => l.unexpected(token));
	}
}
