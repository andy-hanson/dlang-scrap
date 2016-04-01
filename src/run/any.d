module run.any;

import std.algorithm : map;
import std.conv : to;
import std.array : join;
import std.format : format;

import rtype : RType;
import util : floatToString;

abstract class Any {
	abstract string show() const pure;
	
	static final class Bool : Any {
		immutable bool value;
		static immutable Bool true_ = new Bool(true);
		static immutable Bool false_ = new Bool(false);

		static immutable(Bool) opCall(bool b) pure {
			return b ? true_ : false_;
		}

		override string show() const pure {
			return to!string(value);
		}

	private:
		this(bool value) pure { this.value = value; }
	}

	static final class Int : Any {
		immutable int value;

		static Int opCall(int i) pure {
			return new Int(i);
		}
	
		override string show() const pure {
			return to!string(value);
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
			
		override string show() const pure {
			return floatToString(value);
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
		
		override string show() const pure {
			auto parts = data.map!(part => part.show); //TODO:SYNTAX
			string scoop = type.name.value;
			string poop = parts.join(" ");
			return "%s(%s)".format(scoop, poop);
		}
	}
}
