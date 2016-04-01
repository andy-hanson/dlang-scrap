//module compile.parse.slice;

import loc : Loc;
import util.array : head, isEmpty, last;
import util.option : Option;

import token : Token;

private struct Slice(SubType : Token) {
	SubType[] tokens;
	Loc loc;

	ulong size() pure {
		return tokens.length;
	}

	bool isEmpty() pure {
		return size == 0;
	}

	SubType head() pure {
		return tokens.head;
	}

	SubType last() pure {
		return tokens.last;
	}

	Slice tail() pure {
		return chopStart(1);
	}

	Slice rtail() pure {
		return chopEnd(tokens.length - 1);
	}

	static struct SplitOnceResult {
		Slice before;
		SubType at;
		Slice after;
	}
	Option!SplitOnceResult trySplitOnce(bool delegate(SubType) pure splitOn) pure {
		foreach (idx, token; tokens) {
			if (splitOn(token))
				return Option!SplitOnceResult(SplitOnceResult(chopEnd(idx), token, chopStart(idx + 1)));
		}
		return Option!SplitOnceResult.none;
	}

	Slice[] splitMany(bool delegate(SubType) pure splitOn) pure {
		ulong idxLast = 0;
		Slice[] res;
		foreach (idx, token; tokens)
			if (splitOn(token)) {
				res ~= chop(idxLast, idx);
				idxLast = idx + 1;
			}
		res ~= chopStart(idxLast);
		return res;
	}


	//splitMany
	//splitManyAndIgnoreSplitters

	//iterator
	
	//static if (is(SubType == Token.Group.Line)) {
	this(T : Token.Group)(T group) {
		this.tokens = group.subTokens;
		this.loc = group.loc;
	}
	//}

private:
	immutable this(immutable SubType[] tokens, Loc loc) {
		this.tokens = tokens;
		this.loc = loc;
	}

	Slice slice(ulong newStart, ulong newEnd, Loc newLoc) pure {
		return immutable Slice(tokens[newStart..newEnd], newLoc);
	}

	Slice chop(ulong newStart, ulong newEnd) pure {
		return slice(newStart, newEnd, Loc(tokens[newStart].loc.start, tokens[newEnd - 1].loc.end));
	}

	Slice chopStart(ulong newStart) pure {
		auto newTokens = tokens[newStart..$];
		auto newLoc = newTokens.isEmpty ? loc : Loc(newTokens.head.loc.start, loc.end);
		return immutable Slice(newTokens, newLoc);
	}

	Slice chopEnd(ulong newEnd) pure {
		auto newTokens = tokens[0..newEnd];
		auto newLoc = newTokens.isEmpty ? loc : Loc(loc.start, newTokens.last.loc.end);
		return immutable Slice(newTokens, newLoc);
	}
}

alias Lines = Slice!(Token.Group.Line);
alias Tokens = Slice!Token;
