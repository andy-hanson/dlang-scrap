import ast : Decl, ModuleAst;
import compile.check : checkAll, Checks;
import compile.compileContext : CompileContext;
import compile.parse : parse;
import symbol : Symbols, Name;

import run.any : Any;
import codegen : generateFns;
import insn : GeneratedCode;
import interpreter : interpret;

//TODO: MOVE
class Runtime {
	Symbols symbols;
	this() {
		symbols = new Symbols();
	}

	Module loadModule(string source) {
		auto ctx = new CompileContext(symbols);
		ModuleAst ast = parse(source, ctx);
		auto checks = checkAll(ast, ctx);
		auto fns = generateFns(ast, checks);
		return new Module(symbols, ast, fns);
	}
}

class Module {
	Fn getFn(string name) {
		return getFn(symbols.name(name));
	}

	Fn getFn(Name name) {
		return fns[name];
	}

private:
	Symbols symbols;
	ModuleAst ast;
	Fn[Name] fns;

	this(Symbols symbols, ModuleAst ast, Fn[Name] fns) {
		this.symbols = symbols;
		this.ast = ast;
		this.fns = fns;
	}
}

class Fn {
	Decl.Val.Fn ast;
	GeneratedCode code;
	this(Decl.Val.Fn ast, GeneratedCode code) {
		this.ast = ast;
		this.code = code;
	}

	uint arity() {
		return cast(uint) ast.sig.params.length;
	}

	Any opCall(Any[] arguments ...) {
		assert(arguments.length == arity);
		return interpret(this.code, arguments);
	}
}
