module compile.language;

import std.format : format;

import groupContext : GroupBuilder;
import token : Token;

abstract immutable class Language {
	// Lex
	string commentNeedsSpace() pure;
	string emptyBlock() pure;
	string leadingZero() pure;
	string mismatchedGroupClose(GroupBuilder.Kind expected, GroupBuilder.Kind actual) pure;
	string noLeadingSpace() pure;
	string nonLeadingTab() pure;
	string tooMuchIndent() pure;
	string trailingDocComment() pure;
	string trailingSpace() pure;
	string unrecognizedCharacter(char ch) pure;

	// Parse
	string condArgs() pure;
	string expectedBlock() pure;
	string expectedNothing() pure;
	string expectedSomething() pure;
	string unexpected(Token token) pure;

	// Check
	string cantBind(string name) pure;
	string nameAlreadyAssigned(string name) pure;
	string noShadow(string name) pure;
	string numArgs(uint expected, uint actual) pure;
	string shadow(string name) pure;
}

immutable class English : Language {
	private this() {}
	// TODO: http://wiki.dlang.org/Low-Lock_Singleton_Pattern
	static immutable English instance = new immutable English();

	// Lex
	override string commentNeedsSpace() {
		return "COMMENT NEEDS A SPACE";
	}

	override string emptyBlock() {
		return "EMPTY BLOCK";
	}

	override string leadingZero() {
		return "Leading '0' must be followed by 'b', 'x', or decimal point ('.').";
	}

	override string mismatchedGroupClose(GroupBuilder.Kind expected, GroupBuilder.Kind actual) {
		return "Trying to close %foo, but last opened was %bar";
	}

	override string noLeadingSpace() {
		return "NO LEAD A SPACE!";
	}

	override string nonLeadingTab() {
		return "NO LEAD A YOU TAB";
	}

	override string tooMuchIndent() {
		return "TOO MUCH INDENT";
	}

	override string trailingDocComment() {
		return "TRAILING DOC COMMENT";
	}

	override string trailingSpace() {
		return "YOU SPACE A TRAILING!";
	}

	override string unrecognizedCharacter(char ch) {
		return "Unrecognized character '%c'".format(ch);
	}

	// Parse

	override string condArgs() {
		return "COND ARGS";
	}

	override string expectedBlock() {
		return "YOU GOT TO HAVE A BLOCK THERE";
	}

	override string expectedNothing() {
		return "Expected nothing here";
	}

	override string expectedSomething() {
		return "Expected something here";
	}

	override string unexpected(Token token) {
		return "I NOT SEE THAT ONE COMING! %s".format(token.show);
	}

	// Check
	override string cantBind(string name) {
		return "Can't find a definition for %s".format(name);
	}
	
	override string nameAlreadyAssigned(string name) {
		return "Already assigned %s".format(name);
	}

	override string noShadow(string name) {
		return "Can't shadow %s".format(name);
	}

	override string numArgs(uint expected, uint actual) {
		return "Expected %u arguments, got %u".format(expected, actual);
	}

	override string shadow(string name) {
		return "Can't shadow %s".format(name);
	}
}
