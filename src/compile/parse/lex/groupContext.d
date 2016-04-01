import compile.compileContext : CompileContext;
import loc : Loc, Pos;
import util.array : isEmpty, pop;

import token : Token;

struct GroupContext {
	CompileContext ctx;
	GroupBuilder cur;
	private GroupBuilder[] stack;

	this(CompileContext ctx) pure {
		this.ctx = ctx;
		cur = GroupBuilder(GroupBuilder.Kind.block, Pos.start);
		openLine(Pos.start);
	}

	Token.Group.Block finish(Pos endPos) pure {
		closeLine(endPos);
		assert(stack.isEmpty);
		return cast(Token.Group.Block) cur.finish(endPos);
	}

	// TODO: operator ~=

	void opOpAssign(string op)(Token t) pure if (op == "~") {
		cur ~= t;
	}

	void closeGroupsForDedent(Pos pos) pure {
		closeLine(pos);
		closeGroup(GroupBuilder.Kind.block, pos);
	}

	void openBlock(Pos pos) pure {
		openGroup(GroupBuilder.Kind.block, pos);
	}

	void openLine(Pos pos) pure {
		openGroup(GroupBuilder.Kind.line, pos);
	}

	void closeLine(Pos pos) pure {
		closeGroup(GroupBuilder.Kind.line, pos);
	}

private:
	void dropGroup() pure {
		cur = stack.pop();
	}

	void openGroup(GroupBuilder.Kind kind, Pos openPos) pure {
		stack ~= cur;
		cur = GroupBuilder(kind, openPos);
	}

	void closeGroup(GroupBuilder.Kind kind, Pos closePos) pure {
		ctx.check(cur.kind == kind, closePos, l => l.mismatchedGroupClose(cur.kind, kind));
		closeGroupNoCheck(kind, closePos);
	}

	void closeGroupNoCheck(GroupBuilder.Kind kind, Pos closePos) pure {
		auto justClosed = cur.finish(closePos);
		dropGroup();
		final switch (kind) {
			case GroupBuilder.Kind.line:
				if (!justClosed.isEmpty())
					this ~= justClosed;
				break;
			case GroupBuilder.Kind.block:
				//TODO: SYNTAX _.emptyBlock
				ctx.check(!justClosed.isEmpty(), closePos, l => l.emptyBlock());
				this ~= justClosed;
				break;
		}
	}
}

struct GroupBuilder {
	Kind kind;
	Pos openPos;
	private Token[] subTokens;

	static enum Kind {
		block,
		line
	}

	bool isEmpty() pure {
		return subTokens.isEmpty;
	}

	void opOpAssign(string op)(Token t) pure if (op == "~") {
		subTokens ~= t;
	}
	
	Token.Group finish(Pos endPos) pure {
		Loc loc = Loc(openPos, endPos);
		final switch (kind) {
			case Kind.block:
				return new Token.Group.Block(loc, cast(Token.Group.Line[]) subTokens);
			case Kind.line:
				return new Token.Group.Line(loc, subTokens);
		}	
	}
}
