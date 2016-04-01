import std.algorithm : map;
import std.format : format;
import std.stdio : writeln;

import run.any : Any;
import insn : GeneratedCode, CodeReader, CodeUser, EndException;
import rtype : RType;

void debugInterpret(GeneratedCode code) {
	new DbgInterpreter(code).runToEnd();
}

Any interpret(GeneratedCode code, Any[] initialStack = []) {
	auto interp = new Interpreter(code, initialStack);

	try
		for (;;) {
			interp.step();
			//interp.printStack();
		}
	catch (EndException) {}
	
	auto v = interp.peek();
	return v;
}

private:

final class Interpreter : CodeUser {
	static immutable bool neverGoto = false;

	// Points to the last item put on the stack.
	private Any* sp;
	private Any[256] stack;
	private CodeReader reader;

	this(GeneratedCode code, Any[] initialStack) {
		stack[] = null;
		sp = stackEnd;
		this.reader = new CodeReader(code);
		// Ensure that sp is a valid reference even for an empty stack.
		// Otherwise GC will crash this!
		// push(Any.Int.of(-1));
		foreach (value; initialStack)
			push(value);
	}

	void step() {
		reader.step(this);
	}

	void printStack() {
		ulong stackDepth = (stack.ptr + stack.length) - sp;
		Any[] realStack = stack[$-stackDepth..$];
		writeln(realStack.map!(a => a.show));
	}

	override void add() pure {
		auto a = pop!(Any.Int);
		auto b = pop!(Any.Int);
		push(a + b);
	}
	
	override void dbg() {
		writeln("DBG");
	}

	override void end() {
		throw new EndException();
	}

	override void blockRet(ubyte blockDepth) pure {
		Any* newSp = sp + blockDepth - 1;
		*newSp = *sp;
		sp = newSp;
	}
	
	override void getField(ubyte n) pure {
		auto rec = pop!(Any.Record);
		push(rec.data[n]);
	}
	
	override void ldc(const Any value) pure {
		push(cast(Any) value);
	}
	
	override void create(immutable RType.Record rec) pure {
		auto properties = popN(rec.properties.length);
		push(new Any.Record(rec, properties));
	}

	override void goto_(short jumpAmount) pure {
		// Reader does the jumping
	}

	override bool jumpIfFalse(short jumpAmount) pure {
		return pop!(Any.Bool).value;
	}

	override void print() {
		writeln(pop().show);
	}

	override void reach(ubyte n) pure {
		push(*(sp + n - 1));
	}

private:
	Any[] popN(ulong n) pure {
		Any[] res = new Any[n];
		Any* endSp = sp + n;
		for (auto i = 0; sp != endSp; sp++, i++)
			res[i] = *sp;
		return res;
	}
	
	void push(Any value) pure {
		sp--;
		*sp = value;
	}
	
	T pop(T : Any = Any)() pure {
		T value = peek!T;
		sp++;
		return value;
	}

	T peek(T : Any = Any)() pure {
		return cast(T) *sp;
	}

	Any* stackEnd() {
		return stack.ptr + stack.length;
	}

	ulong stackDepth() {
		return stackEnd() - sp;
	}

	ulong stackIdx() {
		return stack.length - stackDepth;
	}
}

//TODO: its own file
final class DbgInterpreter : CodeUser {
	static immutable bool neverGoto = true;

	CodeReader reader;

	this(GeneratedCode code) {
		this.reader = new CodeReader(code);
	}

	void step() {
		reader.step(this);
	}

	void runToEnd() {
		try
			for (;;)
				step();
		catch (EndException e) {}
	}

	override void add() {
		writeln("add");
	}

	override void goto_(short jumpAmount) {
		writeln("goto %s".format(jumpAmount));
	}

	override bool jumpIfFalse(short jumpAmount) {
		writeln("jumpIfFalse %s".format(jumpAmount));
		// Never do the jump
		return true;
	}

	override void dbg() {
		writeln("dbg");
	}

	override void blockRet(ubyte blockDepth) {
		writeln("blockRet %u".format(blockDepth));
	}
	
	override void end() {
		throw new EndException();
	}

	override void getField(ubyte n) {
		writeln("getField %u".format(n));
	}
	
	override void ldc(const Any value) {
		writeln("ldc %s".format(value.show));
	}
	
	override void create(immutable RType.Record type) {
		writeln("create"); //writeln("create %s".format(type));
	}

	override void print() {
		writeln("print");
	}

	override void reach(ubyte n) {
		writeln("reach %u".format(n));
	}
}
