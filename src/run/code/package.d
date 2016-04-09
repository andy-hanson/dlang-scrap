module run.code;

import run.any : Any;

public import reader : CodeUser, CodeReader, EndException;
public import writer : CodeWriter, Local;

immutable struct Code {
	Any[] constants;
	ByteCode[] code;
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
	eq,
}
