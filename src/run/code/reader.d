module run.code.reader;

import run.any : Any;
import run.code : ByteCode, Code;
import rtype : RType;

final class CodeReader {
	this(Code code) pure {
		ptr = code.code.ptr;
	}
	
	void step(User)(User user) {
		auto bc = *ptr;
		ptr++;
		final switch (bc) with (ByteCode) {
			case end:
				user.end();
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

			// Builtins:
			case add:
				user.add();
				break;
			case eq:
				user.eq();
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

	// Builtins:

	// Add the top 2 values on the stack.
	void add();
	// If the top 2 values are equal, push true, else push false.
	void eq();
}

class EndException : Exception {
	this() pure {
		super("Program ended");
	}
}
