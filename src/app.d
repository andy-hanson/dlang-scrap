import std.stdio : writeln;

import run.any : Any;
import run.code : CodeWriter, Code;
import run.interpreter : interpret;
import symbol : Name, TypeName, Symbols;
import rtype : RType, Property;

// New instructions:
// First, we need Function (not a closure), which contains bytecode.
// We need to be able to generate bytecode for args. Do it like locals.
// The interpreter will need a stack of functions. (A return stack)
//	To call a function push arguments onto stack.
//	Then we use ldarg_m1 to access stack pointer minus 1.
// Also add a Call(Function) bytecode.
//		Leaves args on the stack, the function should use them up and leave its result.

import compile.check : checkAll;
import compile.compileContext : CompileContext;
import compile.parse : parse;
import run.debug_interpreter : showCode;
import run.runtime : Fn, Module, Runtime;
import util.array : pop;

import std.stdio : File;
import std.file : readText;

// Then TODO: type checking
// Then TODO: allow to call other functions
// Then TODO: records

string src = """
rec Point
	x Real
	y Real
""";

void main() {
	auto s = new Symbols();
	auto ctx = new CompileContext(s);
	auto mod = parse(src, ctx);
	writeln(mod.show);

	/*
	auto r = new Runtime();
	Module m = r.loadModule(src);
	Fn fn = m.getFn("main");
	writeln(fn.code.showCode());
	writeln(fn().show);
	*/

	/*
	auto ctx = new CompileContext();
	auto token = lex(src, ctx);
	//writeln(token.show);
	auto ast = parse(token, ctx);
	writeln(ast.show);

	auto checks = check(ast, ctx);

	//string s = readText("test.nz");
	//writeln(s);
	*/
}


void scoop() {
	Code genInsns() pure {
		with (new CodeWriter()) {
			/*
			ldc(Any.Int(0));
			auto else_ = label(), bottom = label();
			cond(else_); // If false, goto else
			ldc(Any.Int(1));
			goto_(bottom);
			resolveLabel(else_);
			ldc(Any.Int(2));
			resolveLabel(bottom);
			print();
			*/



			/*
			auto l = label();
			goto_(l);
			print();
			resolveLabel(l);
			dbg();
			*/

			ldc(Any.Bool(true));
			auto else_ = label(), bottom = label();
			cond(else_);
			ldc(Any.Int(1));
			goto_(bottom);
			resolveLabel(else_);
			ldc(Any.Int(2));
			resolveLabel(bottom);
			print();

			return finish();
		}
	}

	auto code = genInsns();
	interpret(code);
}


void poop() {
	auto symbols = new Symbols();
	auto ctx = new CompileContext(symbols);

	auto propX = new Property(symbols.name("x"), RType.Primitive.Real);
	auto propY = new Property(symbols.name("y"), RType.Primitive.Real);
	auto point = new RType.Record(symbols.typeName("Point"), [propX, propY]);

	Code getInsns() pure {
		with (new CodeWriter()) {
			auto block0 = block();

			/*
			a =
				b = 1
				c = 2
				+ b c
			+ a 3
			*/
			{
				auto block1 = block();
				ldc(Any.Int(1));
				auto b = block1.local();
				ldc(Any.Int(2));
				auto c = block1.local();
				// and get b
				getLocal(b);
				getLocal(c);
				add();
				block1.end();
			}

			auto a = block0.local();
			ldc(Any.Int(3));
			getLocal(a);
			add();

			block0.end();

			/*
			ldc(Any.Int(100));
			ldc(Any.Int(2));
			create(point);
			get(0);
			ldc(Any.Int(3));
			add();
			*/

			return finish();
		}
	}

	auto insns = getInsns();

	//debugInterpret(insns);

	writeln(interpret(insns).show);
}
