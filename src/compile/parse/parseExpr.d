
import std.algorithm : map;
import std.array : array;
import std.functional : partial;

import ast : Expr;
import compile.parse : Parser;
import loc : Loc;
import util.array : rtail;

import slice : Lines, Tokens;
import token : Token;

Expr parseExpr(Parser p, Tokens tokens) pure {
	auto head = tokens.head;
	auto tail = tokens.tail;
	if (tail.isEmpty)
		return p.parseSingle(head);

	auto opSplit = tail.trySplitOnce(t => Token.Keyword.match(t, Token.Keyword.Kind.colon));
	Expr[] args;
	if (opSplit.hasValue) {
		auto split = opSplit.value;
		foreach (token; split.before.tokens)
			args ~= p.parseSingle(token);
		auto afterParts = split.after.splitMany(t => Token.Keyword.match(t, Token.Keyword.Kind.comma));
		foreach (part; afterParts)
			args ~= p.parseExpr(part);
	} else
		args = tail.tokens.map!(partial!(parseSingle, p)).array;

	if (Token.Keyword.match(head, Token.Keyword.Kind.cond))
		return p.parseCond(tokens.loc, args);
	else
		return new Expr.Call(tokens.loc, p.parseSingle(head), args);
}

Expr.Block parseBlock(Parser p, Lines lines) pure {
	auto statements = lines.tokens.rtail.map!(line => p.parseStatement(Tokens(line))).array;
	auto returned = p.parseExpr(Tokens(lines.last));
	return new Expr.Block(lines.loc, statements, returned);
}

Expr.Cond parseCond(Parser p, Loc loc, Expr[] args) pure {
	p.ctx.check(args.length == 3, loc, l => l.condArgs);
	return new Expr.Cond(loc, args[0], args[1], args[2]);
}

Expr parseSingle(Parser p, Token token) pure {
	Expr.Literal lit(Expr.Literal.Value value) {
		return new Expr.Literal(token.loc, value);
	}

	auto keyword = cast(Token.Keyword) token;
	if (keyword !is null) {
		switch (keyword.kind) with (Token.Keyword.Kind) {
			case false_: return lit(Expr.Literal.Value.Bool.False);
			case true_: return lit(Expr.Literal.Value.Bool.True);
			default: throw p.unexpected(keyword);
		}
	}

	auto literal = cast(Token.Literal) token;
	if (literal !is null)
		return lit(literal.value);

	auto name = cast(Token.Name) token;
	if (name !is null)
		return new Expr.Access(token.loc, name.name);

	throw p.unexpected(token);
}
