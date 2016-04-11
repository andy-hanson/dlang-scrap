module compile.parse.parseExpr;

import ast : Expr, Statement;
import loc : Loc, Pos;

import compile.parse.lex.token : Token;
import compile.parse.parser : Parser;

Expr parseExpr(ref Parser p) {
	Pos start = p.curPos;
	Expr[] parts = p.parseExprParts();
	switch (parts.length) {
		case 0:
			throw p.unexpected(p.peek);
		case 1:
			return parts[0];
		default:
			return new Expr.Call(p.locFrom(start), parts[0], parts[1..$]);
	}
}

Expr parseBlock(ref Parser p) {
	Pos start = p.curPos;
	Statement[] lines;
	loop: for (;;) {
		lines ~= p.parseStatement();
		switch (p.next().kind) with (Token.Kind) {
			case dedent:
				break loop;
			case newline:
				break;
			default:
				// There shoudldn't be any other possibilities.
				assert(false);
		}
	}

	if (lines.length == 1) {
		Expr e = cast(Expr) lines[0];
		if (e !is null)
			return e;
	}
	return new Expr.Block(p.locFrom(start), lines);
}

private:

//TODO:MOVE?
Expr[] parseExprParts(ref Parser p) {
	Expr[] res;
	loop: for (;;) {
		auto token = p.next();
		switch (token.kind) with (Token.Kind) {
			case newline: case dedent:
				p.backUp();
				break loop;
			case and: case or:
				Pos start = p.curPos;
				auto args = p.parseExprParts(); 
				auto kind = token.kind == Token.Kind.and ? Expr.Special.Kind.and : Expr.Special.Kind.or;
				res ~= new Expr.Special(p.locFrom(start), kind, args);
				break loop;
			case case_:
				throw new Error("TODO");
			case colon:
				res ~= p.parseExpr();
				break loop;
			case cond: //TODO: share parsing code with Special?
				Pos start = p.curPos;
				auto args = p.parseExprParts();
				p.ctx.check(args.length == 3, p.curPos, l => l.condArgs);
				res ~= new Expr.Cond(p.locFrom(start), args[0], args[1], args[2]);
				break loop;
			case if_: case unless:
				/*
				bool isUnless = token.kind == Token.Kind.unless;
				auto kind = token.kind == Token.Kind.if_ ? Expr.Special.Kind.if_ : Expr.Special.Kind.unless;
				auto cond = readExprNoBlock();
				auto result = readBlock();
				return new Expr.Special(p.locFrom(start), kind, [cond, result]);
				*/
				throw new Error("TODO");
			default:
				res ~= p.parseSingle(token);
		}
	}
	return res;
}

Expr parseSingle(ref Parser p, Token token) {
	Expr.Literal lit(Expr.Literal.Value value) {
		return new Expr.Literal(token.loc, value);
	}
	switch (token.kind) with (Token.Kind) {
		case name:
			return new Expr.Access(token.loc, token.name);
		case literal:
			return lit(token.literal);
		case false_:
			return lit(Expr.Literal.Value.Bool.False);
		case true_:
			return lit(Expr.Literal.Value.Bool.True);
		default:
			throw p.unexpected(token);
	}
}
