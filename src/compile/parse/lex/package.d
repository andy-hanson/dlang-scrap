module compile.parse.lex;

import ast : Expr;
import compile.compileContext : CompileContext;
import loc : Loc, Pos;
import util : isInRange, nullOr;

import groupContext : GroupContext;
import sourceContext : SourceContext;
import token : Token;

Token.Group.Block lex(string source, CompileContext ctx) {
	return Lexer(source, ctx).lex();
}

private:

struct Lexer {
	CompileContext ctx;
	SourceContext source;
	GroupContext groups;

	this(string source, CompileContext ctx) {
		this.ctx = ctx;
		this.source = SourceContext(source, ctx);
		this.groups = GroupContext(ctx);
	}

	Token.Group.Block lex() {
		lexPlain();
		return groups.finish(source.pos);
	}

	void lexPlain() {
		uint indent = 0;

		while (true) {
			ushort startColumn = source.column;
			char characterEaten = source.eat();

			Pos startPos() pure {
				return Pos(source.line, startColumn);
			}
			Loc loc() pure {
				return source.locFrom(startPos());
			}

			switch (characterEaten) {
				case '\0':
					return;

				case ' ':
					break;

				case '\n':
					if (source.canPeek(-2) && source.peek(-2) == ' ')
						ctx.warn(source.pos, l => l.trailingSpace);

					source.skipNewlines();
					uint oldIndent = indent;
					indent = lexIndent();
					if (indent > oldIndent) {
						ctx.check(indent == oldIndent + 1, source.pos, l => l.tooMuchIndent);
						groups.openBlock(startPos());
						groups.openLine(source.pos());
					} else {
						Pos p = startPos();
						foreach (i; indent..oldIndent)
							groups.closeGroupsForDedent(p);
						groups.closeLine(p);
						groups.openLine(source.pos);
					}
					break;

				case '|':
					throw new Error("TODO");

				case ':':
					groups ~= new Token.Keyword(loc(), Token.Keyword.Kind.colon);
					break;

				case ',':
					groups ~= new Token.Keyword(loc(), Token.Keyword.Kind.comma);
					break;

				case 'A': .. case 'Z':
					lexTypeName(startPos());
					break;

				case 'a': .. case 'z': case '+': case '*': case '/':
					lexName(startPos());
					break;

				case '\t':
					throw ctx.fail(source.pos, l => l.nonLeadingTab);

				case '-':
					if (source.peek().isInRange('0', '9'))
						lexNumber(startPos());
					else
						lexName(startPos());
					break;

				case '0': .. case '9':
					lexNumber(startPos());
					break;

				default:
					throw ctx.fail(source.pos(), l => l.unrecognizedCharacter(characterEaten));
			}
		}
	}

	uint lexIndent() {
		uint indent = source.skipTabs();
		ctx.check(source.peek != ' ', source.pos, l => l.noLeadingSpace);
		return indent;
	}

	void lexName(Pos start) {
		auto name = source.takeName();
		auto loc = source.locFrom(start);
		auto keyword = ctx.symbols.keywordFromName(loc, name);
		groups ~= keyword.nullOr!Token(new Token.Name(loc, name));
	}

	void lexTypeName(Pos start) {
		auto name = source.takeTypeName();
		auto loc = source.locFrom(start);
		groups ~= new Token.TypeName(loc, name);
	}

	void lexNumber(Pos start) {
		auto maybeSpecial() {
			switch (source.peek) {
				case 'b':
					source.skip();
					return new Expr.Literal.Value.Int(source.takeIntBinary);
				case 'x':
					source.skip();
					return new Expr.Literal.Value.Int(source.takeIntHex);
				default:
					return source.takeNumDecimal();
			}
		}
		auto value = source.peek(-1) == '0' ? maybeSpecial() : source.takeNumDecimal();
		groups ~= new Token.Literal(source.locFrom(start), value);
	}


}

