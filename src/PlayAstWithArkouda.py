#!/usr/bin/env python
# coding: utf-8


import inspect
import ast

import numpy as np
import arkouda as ak


class ArkoudaVisitor(ast.NodeVisitor):

    def __init__(self):
        self.ret = ""

    def visit_Add(self, node):
        self.ret += " +"

    def visit_Mult(self, node):
        self.ret += " *"
        
    def visit_BinOp(self, node):
        self.ret += " ("
        self.visit(node.op)
        self.visit(node.left)
        self.visit(node.right)
        self.ret += " )"
        print(self.ret)
            
    def visit_Name(self, node):
        self.ret += " ${" + node.id + "}"
        print(self.ret)
        
    
    def visit_arg(self, node):
        self.ret += " ${" + node.arg + "}"
        print(self.ret)
        
    
    def visit_arguments(self, node):
        self.ret += " ("
        for a in node.args:
            self.visit_arg(a)
        self.ret += " )"
        print(self.ret)
    
    def visit_Return(self, node):
        self.ret += " ( return"
        self.visit(node.value)
        self.ret += " )"
        print(self.ret)
    
    def visit_FunctionDef(self, node):
        self.ret += " ("
        self.ret += " " + node.name
        self.visit_arguments(node.args)
        self.visit_Return(node.body[0])
        self.ret += " )"
        print(self.ret)
        
    def visit_Module(self, node):
        self.visit_FunctionDef(node.body[0])
        print(self.ret)
        

def arkouda_func(func):
    def wrapper(*args):
        import inspect
        import ast
        from string import Template
        
        source_code = inspect.getsource(func)
        tree = ast.parse(source_code)
        print(ast.dump(tree, indent=4))
        visitor = ArkoudaVisitor()
        visitor.visit(tree)
        print(visitor.ret)

        print(args)
        print(func.__annotations__.items())
        t = Template(visitor.ret) # make template
        s = {} # make subs dict
        keys = func.__annotations__.keys()
        for name,arg in zip(keys,args):
            if isinstance(arg, ak.pdarray):
                print(name,func.__annotations__[name],arg.name)
                s[name] = arg.name
            elif isinstance(arg, float):
                print(name,func.__annotations__[name],arg)
                s[name] = arg
            else:
                raise Exception("unhandled arg type = " + str(func.__annotations__[name]))
             
        print(s)
        ret = t.substitute(s)
        print(ret)
        
        return ret
        
    return wrapper


@arkouda_func
def axpy(a : ak.float64, x : ak.pdarray, y : ak.pdarray) -> ak.pdarray:
    return a * x + y


ak.connect()
x = ak.ones(10)
y = ak.zeros(10)
ret = axpy(5.0,x,y)
print(ret)


