module util.array;

// TODO: move stuff from util.package to here

T[] rtail(T)(T[] arr) {
	return arr[0..$-1];
}

T head(T)(T[] arr) {
	return arr[0];
}

T last(T)(T[] arr) {
	return arr[$ - 1];
}

bool isEmpty(T)(T[] arr) pure nothrow {
	return arr.length == 0;
}

ref T peek(T)(T[] arr) pure nothrow {
	return arr[$-1];
}

//TODO: just use popBack
T pop(T)(ref T[] arr) pure nothrow {
	T value = arr.peek;
	arr.length--;
	return value;
}

T[] tail(T)(T[] arr) {
	return arr[1..$];
}
