import ast : Decl, Expr, ModuleAst, Signature;
import compile.check : checkAll, Checks, Binding;
import symbol : Name;
import util.array : isEmpty, tail;

import run.code : Code, CodeWriter, Local;
import runtime : Fn;

Fn[Name] generateFns(ModuleAst ast, Checks checks) {
	Fn[Name] res;
	foreach (decl; ast.decls) {
		auto fn = cast(Decl.Val.Fn) decl;
		assert(fn !is null);
		res[fn.name] = new Fn(fn, genCode(fn, checks));
	}
	return res;
}

private:

Code genCode(Decl.Val.Fn fn, Checks checks) {
	CodeWriter cw = new CodeWriter();
	
	Local[Signature.Parameter] locals;
	auto l = cw.params(cast(uint) fn.sig.params.length);
	foreach (idx, param; fn.sig.params)
		locals[param] = l[idx];
	//foreach (param; fn.sig.params)
	//	locals[param] = cw.local();

	fn.value.accept(new ExprWriter(cw, checks, locals));
	return cw.finish;
}

class ExprWriter : Expr.VisitorVoid {
	CodeWriter cw;
	Checks checks;
	Local[Signature.Parameter] locals;

	this(CodeWriter cw, Checks checks, Local[Signature.Parameter] locals) {
		this.cw = cw;
		this.checks = checks;
		this.locals = locals;
	}

	override void visit(Expr.Access e) {
		//TODO: use binding information
		//(we should have associated the local's number with it.)
		checks.binding(e).accept(new class Binding.Visitor {
			override void visit(Binding.Builtin b) {
				//TODO: access a lambda for it
				throw new Error("TODO");
			}
			override void visit(Binding.Declared d) {
				// TODO: for Fn, construct a lambda. For Val, just push it.
				throw new Error("TODO");
			}
			override void visit(Binding.Local l) {
				// TODO: Access that local
				cw.getLocal(locals[l.declaration]);
			}
		});
	}

	override void visit(Expr.Block e) {
		assert(e.lines.isEmpty);
		visitAny(e.returned);
	}

	override void visit(Expr.Call e) {
		void callLambda() {
			throw new Error("TODO");
		}

		auto access = cast(Expr.Access) e.called;
		if (access is null)
			callLambda();
		else {
			checks.binding(access).accept(new class Binding.Visitor {
				override void visit(Binding.Builtin b) {
				final switch (b.kind) with (Binding.Builtin.Kind) {
						case add:
							assert(e.args.length > 1);
							visitAny(e.args[0]);
							foreach (arg; e.args.tail) {
								visitAny(arg);
								cw.add();
							}
							break;
						case eq:
							assert(e.args.length == 2); //TODO
							visitAny(e.args[0]);
							visitAny(e.args[1]);
							cw.eq();
					}
				}
				override void visit(Binding.Declared d) {
					// Call a declared function
					throw new Error("TODO");
				}
				override void visit(Binding.Local l) {
					callLambda();
				}
			});
		}


		//TODO: checks.getBinding(e.called)
		/*
		TODO: if a builtin, generate its bytecode.
		If a Decl.Type, cw.create it.
		If a Decl.Val.Fn, cw.call it.
		*/
	}

	override void visit(Expr.Cond e) {
		visitAny(e.condition);

		auto else_ = cw.label(), bottom = cw.label();
		cw.cond(else_);

		visitAny(e.ifTrue);
		cw.goto_(bottom);

		cw.resolveLabel(else_);
		visitAny(e.ifFalse);

		cw.resolveLabel(bottom);
	}

	override void visit(Expr.Literal e) {
		cw.ldc(e.value.toAny);
	}
}
