import symbol : Name, TypeName;

// Runtime type.
// These are only ever exact types.
//TODO:KILL
abstract class RType_C {
	static final immutable class Primitive_C : RType {
		Kind kind;

		private this(Kind kind) pure {
			this.kind = kind;
		}
		
		enum Kind {
			int_,
			real_
		}

		static auto Int = new Primitive(Kind.int_);
		static auto Real = new Primitive(Kind.real_);
	}
	alias Primitive = immutable Primitive_C;

	static final immutable class Record_C : RType {
		TypeName name;
		Property[] properties;
		
		this(TypeName name, Property[] properties) {
			this.name = name;
			this.properties = properties;
		}
	}
	alias Record = immutable Record_C;
}
alias RType = immutable RType_C;

//TODO: don't need all this info here.
static final immutable class Property_C {
	Name name;
	RType type;
	
	this(Name name, RType type) {
		this.name = name;
		this.type = type;
	}
}
alias Property = immutable Property_C;

