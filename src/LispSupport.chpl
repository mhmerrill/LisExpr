module LispSupport {
    use LisExpr;
    /*
      tokenize the prog
    */
    proc tokenize(line: string) {
        // Want:
        //   var l: list(string) = line.replace("("," ( ").replace(")"," ) ").split()
        // Workaround (see https://github.com/chapel-lang/chapel/issues/16166):

        var l: list(string);
        for token in line.replace("("," ( ").replace(")"," ) ").split() do
          l.append(token);
        return l;
    }
    
    /*
      parse, check, and validate code and all symbols in the tokenized prog
    */ 
    proc parse(line: string): owned GenListValue throws {
        // Want:
        //   return read_from_tokens(tokenize(line));
        //
        // Workaround (see https://github.com/chapel-lang/chapel/issues/16170):

        var l: list(string) = tokenize(line);
        return read_from_tokens(l);
    }
    
    /*
      parse throught the list of tokens generating the parse tree / AST
      as a list of atoms and lists
    */
    proc read_from_tokens(ref tokens: list(string)): owned GenListValue throws {
        if (tokens.size == 0) then
            throw new owned ErrorWithMsg("SyntaxError: unexpected EOF");

        // Open Q: If we were to parse from the back of the string to the
        // front, could this be more efficient since popping from the
        // front of a list is an expensive operation?

        var token = tokens.pop(0);
        if (token == "(") {
            var L: GenList;
            while (tokens.first() != ")") {
                L.append(read_from_tokens(tokens));
                if (tokens.size == 0) then
                    throw new owned ErrorWithMsg("SyntaxError: unexpected EOF");
            }
            tokens.pop(0); // pop off ")"
            return new owned ListValue(L);
        }
        else if (token == ")") {
            throw new owned ErrorWithMsg("SyntaxError: unexpected )");
        }
        else {
            return atom(token);
        }
    }
    
    /* determine atom type and values */
    proc atom(token: string): owned GenListValue {
        try { // try to interpret as an integer ?
            return new owned ListValue(token:int); 
        } catch {
            try { //try to interpret it as a real ?
                return new owned ListValue(token:real);
            } catch { // return it as a symbol
                return new owned ListValue(token);
            }
        }
    }
    
    /* check to see if list value is a symbol otherwise throw error */
    inline proc checkSymbol(arg: borrowed GenListValue) throws {
        if (arg.lvt != LVT.Sym) {
          throw new owned ErrorWithMsg("arg must be a symbol " + arg:string);
        }
    }

    /* check to see if size is greater than or equal to size otherwise throw error */
    inline proc checkGEqLstSize(lst: GenList, sz: int) throws {
        if (lst.size < sz) {
          throw new owned ErrorWithMsg("list must be at least size " + sz:string + " " + lst:string);
        }
    }

    /* check to see if size is equal to size otherwise throw error */
    inline proc checkEqLstSize(lst: GenList, sz: int) throws {
        if (lst.size != sz) {
          throw new owned ErrorWithMsg("list must be size" + sz:string + " " +  lst:string);
        }
    }

    /*
      evaluate the expression
    */
    proc eval(ast: borrowed GenListValue, env: borrowed Env): owned GenValue throws {
        select (ast.lvt) {
            when (LVT.Sym) {
                var gv = env.lookup(ast.toListValue(Symbol).lv);
                return gv.copy();
            }
            when (LVT.I) {
                var ret: int = ast.toListValue(int).lv;
                return new owned Value(ret);
            }
            when (LVT.R) {
                var ret: real = ast.toListValue(real).lv;
                return new owned Value(ret);
            }
            when (LVT.Lst) {
                ref lst = ast.toListValue(GenList).lv;
                // no empty lists allowed
                checkGEqLstSize(lst,1);
                // currently first list element must be a symbol of operator
                checkSymbol(lst[0]);
                var op = lst[0].toListValue(Symbol).lv;
                select (op) {
                    when "+"  {checkEqLstSize(lst,3); return eval(lst[1], env) + eval(lst[2], env);}
                    when "-"  {checkEqLstSize(lst,3); return eval(lst[1], env) - eval(lst[2], env);}
                    when "*"  {checkEqLstSize(lst,3); return eval(lst[1], env) * eval(lst[2], env);}
                    when "<"  {checkEqLstSize(lst,3); return eval(lst[1], env) < eval(lst[2], env);}
                    when ">"  {checkEqLstSize(lst,3); return eval(lst[1], env) > eval(lst[2], env);}
                    when "<="  {checkEqLstSize(lst,3); return eval(lst[1], env) <= eval(lst[2], env);}
                    when ">="  {checkEqLstSize(lst,3); return eval(lst[1], env) >= eval(lst[2], env);}
                    when "==" {checkEqLstSize(lst,3); return eval(lst[1], env) == eval(lst[2], env);}
                    when "!=" {checkEqLstSize(lst,3); return eval(lst[1], env) != eval(lst[2], env);}
                    when "or" {checkEqLstSize(lst,3); return or(eval(lst[1], env), eval(lst[2], env));}
                    when "and" {checkEqLstSize(lst,3); return and(eval(lst[1], env), eval(lst[2], env));}
                    when "not" {checkEqLstSize(lst,2); return not(eval(lst[1], env));}
                    when "set!" {
                        checkEqLstSize(lst,3);
                        checkSymbol(lst[1]);
                        var name = lst[1].toListValue(Symbol).lv;
                        // addEnrtry redefines values for already existing entries
                        var gv = env.addEntry(name, eval(lst[2],env));
                        return gv.copy(); // return value assigned to symbol
                    }
                    when "if" {
                        checkEqLstSize(lst,4);
                        if isTrue(eval(lst[1], env)) {return eval(lst[2], env);} else {return eval(lst[3], env);}
                    }
                    otherwise {
                        throw new owned ErrorWithMsg("op not implemented " + op);
                    }
                }
            }
            otherwise {
              throw new owned ErrorWithMsg("undefined ast node type " + ast:string);
            }
        }
    }
}
