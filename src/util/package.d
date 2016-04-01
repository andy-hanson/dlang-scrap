module util;

import std.conv : to;

bool isInRange(T)(T value, T min, T max) pure nothrow {
	return min <= value && value < max;
}


/*
T[] popN(T)(ref T[] arr, ulong n) pure {
	T[] values = arr[$-n..$];
	arr.length -= n;
	return values;
}
*/

string floatToString(float f) pure nothrow {
	//TODO: to!string(f) is apparently impure. Write my own?
	//return to!string(to!int(f));
	return "TODO:floatToString";
}

T nullOr(T)(T nullable, lazy T orElse) {
	return nullable is null ? orElse : nullable;
}

A[B] invert(A, B)(const B[A] dct) pure nothrow {
	A[B] res;
	foreach (key, val; dct)
		res[val] = key;
	return res;
}
