
import inspect
import ast

import arkouda as ak


class ArkoudaVisitor(ast.NodeVisitor):

    # initialize return string which will contain scheme/lisp code
    def __init__(self, echo=False):
        self.name = ""
        self.ret = ""
        self.formal_arg = {}
        self.echo = echo

    # allowed nodes without specialized visitors
    ALLOWED = tuple()
    ALLOWED += (ast.Module,)
    ALLOWED += (ast.Expr,)
    
    # Binary ops
    ALLOWED += (ast.BinOp,)
    def visit_BinOp(self, node):
        self.ret += " ("
        self.visit(node.op)
        self.visit(node.left)
        self.visit(node.right)
        self.ret += " )"
        if self.echo: print(self.ret)

    ALLOWED += (ast.Add,)
    def visit_Add(self, node):
        self.ret += " +"

    ALLOWED += (ast.Sub,)
    def visit_Sub(self, node):
        self.ret += " -"

    ALLOWED += (ast.Mult,)
    def visit_Mult(self, node):
        self.ret += " *"
        
    # Comparison ops
    ALLOWED += (ast.Compare,)
    def visit_Compare(self, node):
        if len(node.ops) != 1:
            raise Exception("only one comparison operator allowed")
        self.ret += " ("
        self.visit(node.ops[0]) 
        self.visit(node.left)  # left?
        self.visit(node.comparators[0]) # right?
        self.ret += " )"
        if self.echo: print(self.ret)

    ALLOWED += (ast.Eq,)
    def visit_Eq(self, node):
        self.ret += " =="

    ALLOWED += (ast.NotEq,)
    def visit_NotEq(self, node):
        self.ret += " !="

    ALLOWED += (ast.Lt,)
    def visit_Lt(self, node):
        self.ret += " <"

    ALLOWED += (ast.LtE,)
    def visit_LtE(self, node):
        self.ret += " <="

    ALLOWED += (ast.Gt,)
    def visit_Gt(self, node):
        self.ret += " >"

    ALLOWED += (ast.GtE,)
    def visit_GtE(self, node):
        self.ret += " >="

    # Boolean Ops
    ALLOWED += (ast.BoolOp,)
    def visit_BoolOp(self, node):
        self.ret += " ("
        self.visit(node.op)
        for v in node.values:
            self.visit(v)
        self.ret += " )"
        if self.echo: print(self.ret)

    ALLOWED += (ast.And,)
    def visit_And(self, node):
        self.ret += " and"

    ALLOWED += (ast.Or,)
    def visit_Or(self, node):
        self.ret += " or"

    # Unary ops (only `not` at this point)
    ALLOWED += (ast.UnaryOp,)
    def visit_UnaryOp(self, node):
        self.ret += " ("
        self.visit(node.op) 
        self.visit(node.operand)
        self.ret += " )"
        if self.echo: print(self.ret)

    ALLOWED += (ast.Not,)
    def visit_Not(self, node):
        self.ret += " not"

    # If Expression `(body) if (test) else (orelse)`
    ALLOWED += (ast.IfExp,)
    def visit_IfExp(self, node):
        self.ret += " ( if"
        self.visit(node.test)
        self.visit(node.body)
        self.visit(node.orelse)
        self.ret += " )"
        if self.echo: print(self.ret)

    # Assignment which returns a value `(x := 5)`
    ALLOWED += (ast.NamedExpr,)
    def visit_NamedExpr(self, node):
        self.ret += " ( :="
        self.visit(node.target)
        self.visit(node.value)
        self.ret += " )"
        if self.echo: print(self.ret)
        
    # Constant
    ALLOWED += (ast.Constant,)
    def visit_Constant(self, node):
        self.ret += " " + str(node.value)
        if self.echo: print(self.ret)

    # Name, mostly variable names, I think
    ALLOWED += (ast.Name,)
    def visit_Name(self, node):
        self.ret += " " + node.id
        if self.echo: print(self.ret)
        
    # argument name in argument list
    ALLOWED += (ast.arg,)
    def visit_arg(self, node):
        self.formal_arg[node.arg] = node.annotation.attr
        if self.echo: print(self.ret)
        
    # argument list
    ALLOWED += (ast.arguments,)
    def visit_arguments(self, node):
        for a in node.args:
            self.visit_arg(a)
        if self.echo: print(self.ret)

    # Return, `return value`
    ALLOWED += (ast.Return,)
    def visit_Return(self, node):
        self.ret += " ( return"
        self.visit(node.value)
        self.ret += " )"
        if self.echo: print(self.ret)

    # Function Definition
    ALLOWED += (ast.FunctionDef,)
    def visit_FunctionDef(self, node):
        self.name = node.name
        self.visit_arguments(node.args)
        self.ret += "( begin"
        for b in node.body:
            self.visit(b)
        self.ret += " )"
        if self.echo: print(self.ret)

    # override ast.NodeVisitor.visit() method
    def visit(self, node):
        """Ensure only contains allowed ast nodes."""
        if not isinstance(node, self.ALLOWED):
            raise SyntaxError("ast node not allowed: " + str(node))
        ast.NodeVisitor.visit(self, node)



# Arkouda function decorator
# transforms a simple python function into a Scheme/Lisp lambda
# which could be sent to the arkouda server to be evaluated there
def arkouda_func(func):
    def wrapper(*args):
        
         # get source code for function
        source_code = inspect.getsource(func)
        print("source_code :\n" + source_code)

         # parse sorce code into a python ast
        tree = ast.parse(source_code)
        #print(ast.dump(tree, indent=4))

         # create ast visitor to transform ast into scheme/lisp code
        visitor = ArkoudaVisitor(echo=False)
        visitor.visit(tree)
        #print("name :", visitor.name)
        #print("formal_arg :", visitor.formal_arg)
        #print("code :", visitor.ret)

        # create bindings/linkage to arkouda server symboltable
        #print("args :", args)
        #print("annotations :", func.__annotations__.items())
        bindings = {} # make variable/arg linkage/binding dict
        keys = func.__annotations__.keys()
        for name,arg in zip(keys,args):
            if isinstance(arg, ak.pdarray):
                #print(name,func.__annotations__[name],(arg.name,"pdarray"))
                bindings[name] = {"type" : "pdarray", "name" : arg.name}
            elif isinstance(arg, ak.numeric_scalars):
                #print(name,func.__annotations__[name],(arg,str(ak.resolve_scalar_dtype(arg))))
                bindings[name] = {"type" : str(ak.resolve_scalar_dtype(arg)), "value" : str(arg)}
            else:
                raise Exception("unhandled arg type = " + str(func.__annotations__[name]))


        msg_payload = repr({'bindings' : repr(bindings), 'code' : repr(visitor.ret)})
        print(msg_payload)

        # construct a message to the arkouda server
        # send it
        # get result
        # return pdarray of result
        
        # return a dummy pdarray
        return ak.zeros(10)
        
    return wrapper


