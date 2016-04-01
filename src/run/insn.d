import core.memory : GC;
import std.algorithm : map;
import std.array : array;
import std.range : iota;
import std.stdio : writeln, writefln;

import run.any : Any;
import rtype : RType, RType_C;
import symbol : Name;
import util.array : peek, pop;

immutable struct GeneratedCode {
	immutable Any[] constants;
	immutable ByteCode[] code;
}

private enum ByteCode : byte {
	end,
	blockRet,
	create,
	dbg,
	getField,
	goto_,
	jumpIfFalse,
	ldc,
	print,
	reach,
	// Builtins
	add,
	
}

//TODO:MOVE, private
ByteCode[T.sizeof] toBytes(T)(T value) pure {
	union TBytes {
		T t;
		ByteCode[T.sizeof] bytes;
	}
	TBytes tb;
	tb.t = value;
	return tb.bytes;
}

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

	//~this() pure {
	//	cw.blockEnd();
	//}

	Local local() pure {
		auto l = cw.local();
		locals ~= l;
		return l;
	}
}

struct Label {
private:
	// Upon calling resolveLabel, These will be written to with the # of bytes to jump by.
	//this(ulong[] uses) { this.uses = uses; }

	// Array of indices into code being built.
	uint[] uses;
}

struct Local {
	// Stack depth the local is stored at.
	private uint stackLoc;
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

	
	/*void block(T)(T fun) pure {
		blockStart();
		fun();
		blockEnd();
	}
	*/
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

	/*
	Local local(immutable Name name) pure {
		auto local = Local(stackDepth);
		curBlock.locals ~= local;
		locals[name] = local;
		stackDepth++;
	}

	void getLocal(immutable Name name) pure {
		auto local = locals[name];
		reach(stackDepth - local.stackDepth);
	}
	*/

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
	
	void add() pure {
		bc(ByteCode.add);
		stackDepth--;
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
	
	GeneratedCode finish() pure {
		// TODO: detect unresolved labels

		bc(ByteCode.end);
		//immutable ByteCode[] code = codeStart[0..(codeCur - codeStart)].dup;
		return GeneratedCode(cast(immutable Any[]) constants, cast(immutable ByteCode[]) code);
	}
}

//TODO: struct
final class CodeReader {
public:
	this(GeneratedCode code) pure {
		ptr = code.code.ptr;
	}
	
	void step(User)(User user) {
		auto bc = *ptr;
		ptr++;
		final switch (bc) with (ByteCode) {
			case end:
				user.end();
				break;
			case add:
				user.add();
				break;
			case blockRet:
				user.blockRet(read!ubyte);
				break;
			case create:
				user.create(read!(RType.Record));
				break;
			case dbg:
				user.dbg();
				break;
			case getField:
				user.getField(read!ubyte);
				break;
			case goto_:
				// The relative jump is relative to the location to the short value representing it.
				static if (User.neverGoto)
					user.goto_(read!short);
				else {
					short jmp = readNoPtrUpdate!short;
					user.goto_(jmp);
					ptr += jmp;
				}
				break;
			case jumpIfFalse:
				short jmp = readNoPtrUpdate!short;
				bool cond = user.jumpIfFalse(jmp);
				if (cond)
					ptr += short.sizeof;
				else
					ptr += jmp;
				break;
			case ldc:
				user.ldc(read!Any);
				break;
			case print:
				user.print();
				break;
			case reach:
				user.reach(read!ubyte);
				break;
		}
	}

	//void jumpBy(short amount) pure {
	//	ptr += amount;
	//}

	//void next() pure {
	//	ptr++;
	//}


private:
	// At the beginning of step(), points to the next instruction to read.
	immutable(ByteCode)* ptr;
	
	/*ByteCode next() pure {
		ByteCode next = *ptr;
		// This may be unnecessary
		ptr++;
		return next;
	}*/
	
	T readNoPtrUpdate(T)() pure {
		return *(cast(T*) ptr);
	}
	
	T read(T)() pure {
		T* tPtr = cast(T*) ptr;
		T value = *tPtr;
		tPtr++;
		ptr = cast(immutable(ByteCode)*) tPtr;
		return value;
	}
}

interface CodeUser {
	// Add the top 2 values on the stack.
	void add();
	// Take the top value on the stack, drop blockDepth values, and push that former top value.
	void blockRet(ubyte blockDepth);
	void goto_(short jumpAmount);
	void end();
	bool jumpIfFalse(short jumpAmount);
	// ???
	void dbg();
	// Get the nth field in a record.
	void getField(ubyte n);
	// Push a constant to the stack.
	void ldc(const Any value);
	// Pop a value and print it.
	void print();
	// Pop field values from the stack and push a new record.
	void create(immutable RType.Record t);
	// Get the nth value from the top of the stack.
	void reach(ubyte n);
}

class EndException : Exception {
	this() pure {
		super("Program ended");
	}
}
