// TODO: kill, use std.typecons Nullable and NullableRef

module util.option;

import std.format : format;

// TODO: special-case for reference types and nillable values (those with a `isNil` function)
struct Option(T) {
	bool hasValue;
	T value;

	this(T value) pure {
		hasValue = true;
		this.value = value;
	}

	T or(lazy T _default) const pure {
		return hasValue ? value : _default;
	}

	T orThrow(Exception e) const pure {
		if (hasValue)
			return value;
		else
			throw e;
	}

	string show(alias showValue = value => value.toString())() const pure {
		if (hasValue)
			return "Option(%s)".format(showValue(value));
		else
			return "Option.none";
	}

	static immutable Option none;

	static Option iff(bool cond, T then) {
		return cond ? Option(then) : none;
	}
}

struct Opt(T) {// if (is(T == class)) {
	T value;

	this(T value) pure {
		this.value = value;
	}
}
