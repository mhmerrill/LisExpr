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

    def visit_BinOp(self, node):
        ret = "("
        ret += str(node.op)
        ret += str(node.left)
        ret += str(node.right)
        ret += ")"
        return ret
    
    def visit_Name(self, node):
        ret = " " + node + " "
        print(ret)
        return ret
    
    def visit_arg(self, node):
        ret = " " + node.arg + " "
        print(ret)
        return ret
    
    def visit_arguments(self, node):
        ret = " "
        for a in node.args:
            ret += self.visit_arg(a) + " "
        ret = "(" + ret + ")"
        print(ret)
        return ret
    
    def visit_Return(self, node):
        ret = "("
        ret += self.visit_BinOp(node.value)
        ret += ")"
        print(ret)
        return ret
    
    def visit_FunctionDef(self, node):
        ret = "("
        ret += node.name
        ret += self.visit_arguments(node.args)
        ret += self.visit_Return(node.body[0])
        ret += ")"
        print(ret)
        return ret
        
    def visit_Module(self, node):
        ret = self.visit_FunctionDef(node.body[0])
        print(ret)
        return ret
        


# In[107]:


def arkouda_func(func):
    def wrapper(*args):
        import inspect
        import ast
        source_code = inspect.getsource(func)
        tree = ast.parse(source_code)
        print(ast.dump(tree, indent=4))
        visitor = ArkoudaVisitor()
        ret = visitor.visit(tree)
        return ret
        
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




