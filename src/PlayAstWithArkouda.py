#!/usr/bin/env python
# coding: utf-8

# In[11]:


import inspect
import ast
import typeguard

import numpy as np
import arkouda as ak


# In[12]:


ak.connect()


# In[106]:


class ArkoudaVisitor(ast.NodeVisitor):

    def __init__(self):
        self.ret = ""

    def visit_Add(self, node):
        self.ret += "+"

    def visit_Mult(self, node):
        self.ret += "*"
        
    def visit_BinOp(self, node):
        self.ret += "("
        self.visit(node.op)
        self.visit(node.left)
        self.visit(node.right)
        self.ret += ")"
        print(self.ret)
        
    
    def visit_Name(self, node):
        self.ret += " " + node.id + " "
        print(self.ret)
        
    
    def visit_arg(self, node):
        self.ret += " " + node.arg + " "
        print(self.ret)
        
    
    def visit_arguments(self, node):
        self.ret += "("
        for a in node.args:
            self.visit_arg(a)
        self.ret += ")"
        print(self.ret)
    
    def visit_Return(self, node):
        self.ret += "("
        self.visit(node.value)
        self.ret += ")"
        print(self.ret)
    
    def visit_FunctionDef(self, node):
        self.ret += "("
        self.ret += node.name
        self.visit_arguments(node.args)
        self.visit_Return(node.body[0])
        self.ret += ")"
        print(self.ret)
        
    def visit_Module(self, node):
        self.visit_FunctionDef(node.body[0])
        print(self.ret)
        


# In[107]:


def arkouda_func(func):
    def wrapper(*args):
        import inspect
        import ast
        source_code = inspect.getsource(func)
        tree = ast.parse(source_code)
        print(ast.dump(tree, indent=4))
        visitor = ArkoudaVisitor()
        visitor.visit(tree)
        return visitor.ret
        
    return wrapper


# In[108]:


@arkouda_func
def axpy(a : ak.float64, x : ak.pdarray, y : ak.pdarray) -> ak.pdarray:
    return a * x + y


# In[109]:


x = ak.ones(10)
y = ak.ones(10)
ret = axpy(5.0,x,y)
print(ret)


# In[ ]:





# In[ ]:




