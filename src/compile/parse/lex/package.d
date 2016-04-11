module compile.parse.lex;

import std.stdio; //TODO:KILL

import ast : Expr;
import loc : Loc, Pos;
import symbol : Name, TypeName;
import util : isInRange;

import compile.compileContext : CompileContext;
import compile.parse.lex.reader : Reader;
import compile.parse.lex.token : Token;

immutable(Token[]) lex(string source, CompileContext ctx) {
	return Lexer(source, ctx).lex();
}

private:

struct Lexer {
	//TODO: rename to `reader`
	private Reader source;
	private CompileContext ctx;
	private uint indent;
	Token[] res;

	void output(Token t) {
		res ~= t;
	}

	this(string source, CompileContext ctx) {
		this.source = new Reader(source);
		this.ctx = ctx;
		this.indent = 0;
	}

	Pos pos() {
		return source.pos;
	}
	Loc locFrom(Pos start) {
		return source.locFrom(start);
	}

	immutable(Token[]) lex() {
		go();
		return cast(immutable) res;
	}

	void go() {
		for (;;) {
			Pos startPos = source.pos;

			void t(Token.Kind kind) {
				output(Token(locFrom(startPos), kind));
			}

			char characterEaten = source.eat();

			switch (characterEaten) {
				case '\0':
					t(Token.Kind.end);
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
						t(Token.Kind.indent);
					} else {
						foreach (i; indent..oldIndent) {
							t(Token.Kind.dedent);
							//t(Token.Kind.newline);
						}
					}
					break;

				case '|':
					auto isDocComment = source.tryEat('|');
					if (!(source.tryEat(' ') || source.tryEat('\t') || source.peek == '\n'))
						ctx.warn(source.pos, l => l.commentNeedsSpace);
					source.skipRestOfLine();
					break;

				case ':':
					t(Token.Kind.colon);
					break;

				case 'A': .. case 'Z':
					lexTypeName(startPos);
					break;

				case 'a': .. case 'z': case '+': case '*': case '/': case '=': case '?':
					lexName(startPos);
					break;

				case '\t':
					throw ctx.fail(source.pos, l => l.nonLeadingTab);

				case '-':
					if (source.peek.isInRange('0', '9'))
						lexNumber(startPos);
					else
						lexName(startPos);
					break;

				case '(':
					t(Token.Kind.lparen);
					break;

				case ')':
					t(Token.Kind.rparen);
					break;

				case '0': .. case '9':
					lexNumber(startPos);
					break;

				default:
					throw ctx.fail(source.pos, l => l.unrecognizedCharacter(characterEaten));
			}
		}
	}

	uint lexIndent() {
		uint indent = source.skipTabs();
		ctx.check(source.peek != ' ', source.pos, l => l.noLeadingSpace);
		return indent;
	}

	void lexName(Pos start) {
		Name name = ctx.symbols.name(source.takeNameLike());
		Loc loc = source.locFrom(start);
		auto keyword = ctx.symbols.keywordFromName(name);
		if (keyword.hasValue)
			output(Token(loc, keyword.value));
		else
			output(Token.name(loc, name));
	}

	void lexTypeName(Pos start) {
		TypeName name = ctx.symbols.typeName(source.takeNameLike());
		Loc loc = source.locFrom(start);
		output(Token.typeName(loc, name));
	}

	void lexNumber(Pos start) {
		Expr.Literal.Value maybeSpecial() {
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
		Expr.Literal.Value value = source.peek(-1) == '0' ? maybeSpecial() : source.takeNumDecimal();
		output(Token.literal(source.locFrom(start), value));
	}
}
