module compile.check.bind;

import ast : Decl, Expr, ModuleAst, Signature, TypeAst;
import loc : Loc;
import symbol : Name, TypeName;

import compile.compileContext : CompileContext;
import compile.type : Type, Type_C;

import compile.check.binding : Binding, Binding_C;

immutable struct Bindings {
	Binding opIndex(Expr.Access a) {
		return vals[a];
	}
	Type opIndex(TypeAst.Access a) {
		return types[a];
	}

private:
	Binding[Expr.Access] vals;
	Type[TypeAst.Access] types;
}

Bindings getBindings(ModuleAst mod, CompileContext ctx) {
	auto b = new BindingContext(ctx);
	addDeclarationBindings(mod, b);
	useBindings(mod, b);
	return b.finish();
}

private:

void addDeclarationBindings(ModuleAst mod, BindingContext ctx) {
	foreach (decl; mod.decls)
		decl.accept(new class Decl.Visitor {
			override void visit(Decl.Val.Fn fn) {
				ctx.set(decl.loc, fn.name, new Binding.Declared(fn));
			}
			override void visit(Decl.Type.Rec rec) {
				throw new Error("TODO");
			}
		});
}

void useBindings(ModuleAst mod, BindingContext ctx) {
	auto ex = new ExpressionBinder(ctx);
	foreach (decl; mod.decls)
		decl.accept(new class Decl.Visitor {
			override void visit(Decl.Val.Fn fn) {
				auto sig = fn.sig;
				ctx.bindType(sig.returnType);
				foreach (param; sig.params)
					ctx.bindType(param.type);
				ctx.withLocals(sig.params, () => fn.value.accept(ex));
			}
			override void visit(Decl.Type.Rec rec) {
				throw new Error("TODO");
			}
		});
}

class ExpressionBinder : Expr.VisitorVoid {
	BindingContext ctx;
	this(BindingContext ctx) { this.ctx = ctx; }

	override void visit(Expr.Access a) {
		ctx.writeBinding(a);
	}
}

class BindingContext {
	CompileContext ctx;

	Binding_C[Name] names;
	Type_C[TypeName] typeNames;

	Binding_C[Expr.Access] accesses;
	Type_C[TypeAst.Access] typeAccesses;

	this(CompileContext ctx) {
		this.ctx = ctx;
		this.names = cast(Binding_C[Name]) ctx.symbols.nameToBuiltin.dup;
		this.typeNames = cast(Type_C[TypeName]) ctx.symbols.typeNameToBuiltin.dup;
	}

	void writeBinding(Expr.Access a) {
		auto boundTo = a.name in names;
		ctx.check(boundTo !is null, a.loc, l => l.cantBind(a.name.value));
		accesses[a] = *boundTo;
	}

	void writeBinding(TypeAst.Access a) {
		auto boundTo = a.name in typeNames;
		ctx.check(boundTo !is null, a.loc, l => l.cantBind(a.name.value));
		typeAccesses[a] = *boundTo;
	}

	void bindType(TypeAst a) {
		TypeAst.Access access = cast(TypeAst.Access) a;
		if (access !is null)
			writeBinding(access);
	}

	void set(Loc loc, Name name, Binding binding) {
		ctx.check(name !in names, loc, l => l.nameAlreadyAssigned(name.value));
		names[name] = cast(Binding_C) binding;
	}

	void set(Loc loc, TypeName name, Type binding) {
		ctx.check(name !in typeNames, loc, l => l.nameAlreadyAssigned(name.value));
		typeNames[name] = cast(Type_C) binding;
	}

	void withLocals(Signature.Parameter[] locals, void delegate() action) {
		foreach (local; locals) {
			ctx.check(local.name !in names, local.loc, l => l.noShadow(local.name.value));
			names[local.name] = cast(Binding_C) new Binding.Local(local);
		}
		action();
		foreach (local; locals)
			names.remove(local.name);
	}

	Bindings finish() {
		return Bindings(cast(immutable) accesses.rehash, cast(immutable) typeAccesses.rehash);
	}
}
