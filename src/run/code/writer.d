module run.code.writer;

import std.algorithm : map;
import std.array : array;
import std.range : iota;

import symbol : Name;
import util.array : peek, pop;

import run.any : Any;
import run.code : ByteCode, Code;
import rtype : RType, RType_C;

struct Block {
	private CodeWriter cw;
	// Starting stack depth of this block.
	private uint stackDepth;
	private Local[] locals;

	this(CodeWriter cw, uint stackDepth) pure {
		this.cw = cw;
		this.stackDepth = stackDepth;
	}

	void end() pure {
		cw.blockEnd();
	}

	Local local() pure {
		auto l = cw.local();
		locals ~= l;
		return l;
	}
}

struct Label {
private:
	// Array of indices into code being built.
	uint[] uses;
}

struct Local {
private:
	// Stack depth the local is stored at.
	uint stackLoc;
}

final class CodeWriter {
private:
	immutable(Any)[] constants; // Ensures that gc doesn't nab these
	uint stackDepth;

	Block[] blocks;
	Local[immutable(Name)] locals;
	
	void bc(ByteCode b) pure {
		code ~= b;
		//assert(codeCur < codeEnd);
		//*codeCur = b;
		//codeCur++;
	}
	
	void param(T)(T t) pure {
		//foreach (b; toBytes(t))
		//	bc(b);
		code ~= toBytes(t);
	}

	ByteCode[] code;
	//ByteCode* codeStart;
	//ByteCode* codeCur;
	//ByteCode* codeEnd;

//TODO: move public to top	
public:
	this() pure {		
		//codeStart = cast(ByteCode*) GC.malloc(1000);
		//codeCur = codeStart;
		//codeEnd = codeStart + 1000;
	}

	Label label() pure {
		return Label();
	}
	void resolveLabel(ref Label label) pure {
		foreach (use; label.uses) {
			short* ptr = cast(short*) &code[use];
			uint labelIdx = cast(uint) code.length;
			*ptr = cast(short) (labelIdx - use);
		}
	}

	void cond(ref Label else_) pure {
		bc(ByteCode.jumpIfFalse);
		lbl(else_);
	}

	void goto_(ref Label to) pure {
		bc(ByteCode.goto_);
		lbl(to);
	}

	private void lbl(ref Label label) pure {
		//TODO: we must ensure that code is never reallocated!
		label.uses ~= cast(uint) code.length;
		// This will be overwritten when the label is resolved.
		param!short(-1);
	}

	Block block() pure {
		auto b = Block(this, stackDepth);
		blocks ~= b;
		return b;
	}

	private void blockEnd() pure {
		// TODO: safe cast
		blockRet(cast(ubyte) (stackDepth - curBlock.stackDepth));
		blocks.pop();
	}

	ref Block curBlock() pure {
		return blocks.peek;
	}

	Local[] params(uint n) pure {
		return iota(0, n).map!(i => Local(i - n)).array;
	}

	private Local local() pure {
		return Local(stackDepth - 1);
	}

	void getLocal(Local local) pure {
		//TODO: safe cast
		reach(cast(ubyte) (stackDepth - local.stackLoc));
	}

	private void blockRet(ubyte blockDepth) pure {
		bc(ByteCode.blockRet);
		param(blockDepth);
		// -1 because of the returned value
		stackDepth -= blockDepth - 1;
	}

	private void reach(ubyte n) pure {
		bc(ByteCode.reach);
		param(n);
		stackDepth++;
	}

	void print() pure {
		bc(ByteCode.print);
		stackDepth--;
	}

	void ldc(immutable Any value) pure {
		constants ~= value;
		bc(ByteCode.ldc);
		param(cast(Any) value);
		stackDepth++;
	}
	
	void dbg() pure {
		bc(ByteCode.dbg);
	}

	void getField(ubyte n) pure {
		assert(n < 2);
		bc(ByteCode.getField);
		param(n);
		stackDepth++;
	}
	
	void create(immutable RType.Record t) pure {
		bc(ByteCode.create);
		param(cast(RType_C) t);
		stackDepth -= t.properties.length;
		stackDepth++;
	}
	
	Code finish() pure {
		// TODO: detect unresolved labels

		bc(ByteCode.end);
		//immutable ByteCode[] code = codeStart[0..(codeCur - codeStart)].dup;
		return Code(cast(immutable Any[]) constants, cast(immutable ByteCode[]) code);
	}

	// Builtins:

	void add() pure {
		bc(ByteCode.add);
		stackDepth--;
	}

	void eq() pure {
		bc(ByteCode.eq);
		stackDepth--;
	}
}

private:

ByteCode[T.sizeof] toBytes(T)(T value) pure {
	union TBytes {
		T t;
		ByteCode[T.sizeof] bytes;
	}
	TBytes tb;
	tb.t = value;
	return tb.bytes;
}
