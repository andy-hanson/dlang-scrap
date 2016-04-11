module run.debug_interpreter;

import std.format : format;

import run.any : Any;
import run.code : Code, CodeReader, CodeUser, EndException;
import rtype : RType;

string showCode(Code code) {
	return new DbgInterpreter(code).runToEnd();
}

private:

final class DbgInterpreter : CodeUser {
	static immutable bool neverGoto = true;

	CodeReader reader;

	this(Code code) {
		this.reader = new CodeReader(code);
	}

	void step() {
		reader.step(this);
	}

	string runToEnd() {
		try
			for (;;)
				step();
		catch (EndException e) {}
		return result;
	}

	override void goto_(short jumpAmount) {
		write("goto %s".format(jumpAmount));
	}

	override bool jumpIfFalse(short jumpAmount) {
		write("jumpIfFalse %s".format(jumpAmount));
		// Never do the jump
		return true;
	}

	override void dbg() {
		write("dbg");
	}

	override void blockRet(ubyte blockDepth) {
		write("blockRet %u".format(blockDepth));
	}
	
	override void end() {
		throw new EndException();
	}

	override void getField(ubyte n) {
		write("getField %u".format(n));
	}
	
	override void ldc(const Any value) {
		write("ldc %s".format(value.show));
	}
	
	override void create(immutable RType.Record type) {
		write("create"); //write("create %s".format(type));
	}

	override void print() {
		write("print");
	}

	override void reach(ubyte n) {
		write("reach %u".format(n));
	}

	// Builtins

	override void add() {
		write("add");
	}

	override void eq() {
		write("eq");
	}

private:
	string result = "";

	void write(string s) {
		result ~= s ~ '\n';
	}
}
