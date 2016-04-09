module run.any;

import std.algorithm : map;
import std.array : join;
import std.conv : to;
import std.format : format;
import std.range : iota;

import rtype : RType;
import util : floatToString;

abstract class Any {
	abstract bool equals(Any other) const pure;
	abstract string show() const pure;
	
	static final class Bool : Any {
		immutable bool value;
		static immutable Bool true_ = new Bool(true);
		static immutable Bool false_ = new Bool(false);

		static immutable(Bool) opCall(bool b) pure {
			return b ? true_ : false_;
		}

		override string show() const {
			return to!string(value);
		}

		override bool equals(Any other) const {
			return this is other;
		}

	private:
		this(bool value) pure { this.value = value; }
	}

	static final class Int : Any {
		immutable int value;
		// TODO: following would be preferrable
		//static Int[256] cache = iota(-128, 127).map!(i => new Int(i));
		static immutable Int[256] cache;
		static this() {
			foreach (idx, ref value; cache)
				value = new Int((cast(int) idx) - 128);
		}

		static Int opCall(int i) pure {
			int cacheIdx = i + 128;
			if (0 <= cacheIdx && cacheIdx < cache.length)
				return cast(Int) cache[cacheIdx];
			else
				return new Int(i);
			/*
			Int* cached = (i + 128) in cache;
			if (cached)
				return *cached;
			else
				return new Int(i);
			*/
		}
	
		override string show() const {
			return to!string(value);
		}

		override bool equals(Any other) const {
			auto i = cast(Any.Int) other;
			return i !is null && this.value == i.value;
		}
		
		Int opBinary(string op)(const Int rhs) const pure {
			return Int(mixin("value " ~ op ~ " rhs.value"));
		}

	private:
		this(int value) pure { this.value = value; }
	}

	static final class Real : Any {
		immutable float value;

		static Real opCall(immutable float r) pure {
			return new Real(r);
		}
			
		override string show() const {
			return floatToString(value);
		}

		override bool equals(Any other) const {
			auto r = cast(Any.Real) other;
			return r !is null && this.value == r.value;
		}
		
		Real opBinary(string op)(const Real rhs) const pure {
			return Float(mixin("value " ~ op ~ " rhs.value"));
		}

	private:
		this(double value) pure { this.value = value; }
	}
	
	static final class Record : Any {
		immutable RType.Record type;
		Any[] data;
		
		this(immutable RType.Record type, Any[] data) pure {
			this.type = type;
			this.data = data;
		}
		
		override string show() const {
			auto showData = data.map!(part => part.show).join(" ");
			return "%s(%s)".format(type.name.value, showData);
		}

		override bool equals(Any other) const {
			auto r = cast(Any.Record) other;
			if (r is null || type !is r.type)
				return false;
			if (data.length != r.data.length)
				return false;
			foreach (idx, value; data)
				if (!value.equals(r.data[idx]))
					return false;
			return true;
		}
	}
}
