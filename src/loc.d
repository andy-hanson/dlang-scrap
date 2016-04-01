import std.format : format;

struct Pos {
	ushort line;
	ushort column;
	
	this(short line, short column) pure {
		this.line = line;
		this.column = column;
	}

	Pos nextColumn() pure {
		return Pos(line, cast(ushort) (column + 1));
	}

	Pos nextLine() pure {
		return Pos(cast(ushort) (line + 1), column);
	}

	static immutable Pos start = Pos(1, 1);

	string show() pure {
		return "%u:%u".format(line, column);
	}
}

struct Loc {
	Pos start;
	Pos end;
	
	this(Pos start, Pos end) pure {
		this.start = start;
		this.end = end;
	}

	static Loc singleChar(Pos pos) pure {
		return Loc(pos, pos.nextColumn());
	}

	string show() pure {
		return "%s-%s".format(start.show, end.show);
	}
}
