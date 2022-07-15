#!/usr/bin/env python
# coding: utf-8


import inspect
import ast

import numpy as np
import arkouda as ak


class ArkoudaVisitor(ast.NodeVisitor):

    # initialize return string which will contain scheme/lisp code
    def __init__(self):
        self.ret = ""
        self.arg_list = []

    # Binary Operators
    def visit_Add(self, node):
        self.ret += " +"

    def visit_Sub(self, node):
        self.ret += " -"

    def visit_Mult(self, node):
        self.ret += " *"
        
    # Comparison operators
    def visit_Eq(self, node):
        self.ret += " =="

    def visit_NotEq(self, node):
        self.ret += " !="

    def visit_Lt(self, node):
        self.ret += " <"

    def visit_LtE(self, node):
        self.ret += " <="

    def visit_Gt(self, node):
        self.ret += " >"

    def visit_GtE(self, node):
        self.ret += " <="

    # Boolean Operators
    def visit_And(self, node):
        self.ret += " and"

    def visit_Or(self, node):
        self.ret += " or"

    # Uniary Operators
    def visit_Not(self, node):
        self.ret += " not"

    # Unary Op (only `not` at this point)
    def visit_UnaryOp(self, node):
        self.ret += " ("
        self.visit(node.op) 
        self.visit(node.operand)
        self.ret += " )"
        print(self.ret)

    # Compare Op
    def visit_Compare(self, node):
        self.ret += " ("
        self.visit(node.ops[0]) 
        self.visit(node.left)  # left?
        self.visit(node.comparators[0]) # right?
        self.ret += " )"
        print(self.ret)

    # Boolean Op 
    def visit_BoolOp(self, node):
        self.ret += " ("
        self.visit(node.op)
        self.visit(node.values[0]) # left?
        self.visit(node.values[1]) # right?
        self.ret += " )"
        print(self.ret)

    # Binary Op 
    def visit_BinOp(self, node):
        self.ret += " ("
        self.visit(node.op)
        self.visit(node.left)
        self.visit(node.right)
        self.ret += " )"
        print(self.ret)

    # If Expression (body) if (test) else (orelse)
    def visit_IfExp(self, node):
        self.ret += " ( if"
        self.visit(node.test)
        self.visit(node.body)
        self.visit(node.orelse)
        self.ret += " )"
        print(self.ret)

    # Assignment which returns a value `(x := 5)`
    def visit_NamedExpr(self, node):
        self.ret += " ( :="
        self.visit(node.target)
        self.visit(node.value)
        self.ret += " )"
        print(self.ret)
        
    # Constant
    def visit_Constant(self, node):
        self.ret += " " + str(node.value)
        print(self.ret)

    # Name, mostly variable names, I think
    def visit_Name(self, node):
        if node.id in self.arg_list:
            self.ret += " ${" + node.id + "}"
        else:
            self.ret += " " + node.id
        print(self.ret)
        
    # argument name in argument list
    def visit_arg(self, node):
        self.arg_list += node.arg
        self.ret += " ${" + node.arg + "}"
        print(self.ret)
        
    # argument list
    def visit_arguments(self, node):
        self.ret += " ("
        for a in node.args:
            self.visit_arg(a)
        self.ret += " )"
        print(self.ret)

    # Return, `return v`
    def visit_Return(self, node):
        self.ret += " ( return"
        self.visit(node.value)
        self.ret += " )"
        print(self.ret)

    # Function Definition
    def visit_FunctionDef(self, node):
        self.ret += " ("
        self.ret += " " + node.name
        self.visit_arguments(node.args)
        self.ret += " ( body"
        for b in node.body:
            self.visit(b)
        self.ret += " )"
        self.ret += " )"
        print(self.ret)
        
# Arkouda function decorator
# transforms a simple python function into a Scheme/Lisp lambda
# which could be sent to the arkouda server to be evaluated there
def arkouda_func(func):
    def wrapper(*args):
        import inspect
        import ast
        from string import Template
        
         # get source code for function
        source_code = inspect.getsource(func)
        print(source_code)

         # parse sorce code into a python ast
        tree = ast.parse(source_code)
        print(ast.dump(tree, indent=4))

         # create ast visitor to transform ast into scheme/lisp code
        visitor = ArkoudaVisitor()
        visitor.visit(tree)
        print(visitor.ret)

        # create linkage to arkouda server
        print(args)
        print(func.__annotations__.items())
        t = Template(visitor.ret) # make template
        s = {} # make variable/arg subsitution dict
        keys = func.__annotations__.keys()
        for name,arg in zip(keys,args):
            if isinstance(arg, ak.pdarray):
                print(name,func.__annotations__[name],arg.name)
                s[name] = arg.name
            elif isinstance(arg, ak.numeric_scalars):
                print(name,func.__annotations__[name],arg)
                s[name] = arg
            else:
                raise Exception("unhandled arg type = " + str(func.__annotations__[name]))

        print(s)
        ret = t.substitute(s)
        print(ret)
        
        return ret
        
    return wrapper


# some test function definitions
@arkouda_func
def my_axpy(a : ak.float64, x : ak.pdarray, y : ak.pdarray) -> ak.pdarray:
    return a * x + y

@arkouda_func
def my_filter(v : ak.int64, x : ak.pdarray, y : ak.pdarray) -> ak.pdarray:
    return ((y+1) if (not (x < v)) else (y-1))

@arkouda_func
def my_filter2(v : ak.int64, x : ak.pdarray, y : ak.pdarray) -> ak.pdarray:
    (a := v*10)
    return ((y+1) if (not (x < a)) else (y-1))

# try it out
ak.connect()
x = ak.ones(10)
y = ak.zeros(10)
ret = my_axpy(5.0,x,y)
print(ret)

ret = my_filter(5,x,y)
print(ret)

ret = my_filter2(5,x,y)
print(ret)
