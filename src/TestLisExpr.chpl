module TestLisExpr
{

    use LisExprData;
    use LisExprInterp;
    
    /* parse expression and return true if no parse errors */
    proc test_parse(prog: string): bool {
        var f = true;
        try {
            writeln(prog);
            var tokens = tokenize(prog);
            for tok in tokens {
                write("{"); write(tok); write("}");
            }
            writeln("");
            
            writeln(parse(prog));
        }
        catch e: Error {
            writeln(e.message());
            f = false;
        }
       
        return f;
    }

    /* eval with a specific environment for the test expression return true if no errors */
    proc test_eval(prog: string): bool {
        var f = true;
        try {
            var N = 10;
            var D = {0..#N};
            var A: [D] int = D;
            var B: [D] int;
            
            // this could have the advantage of not creating array temps like the rest of arkouda does
            // forall (a,b) in zip(A,B) with (var ast = try! parse(prog3), var env = new owned Env()) {
            //forall (a,b) in zip(A,B) {
            for (a,b) in zip(A,B) {
                var ast = parse(prog); // parse and check the program
                var env = new owned Env(); // allocate the env for variables
                // addEnrtry redefines values for already existing entries
                env.addEntry("elt",a); // add a symbol called "elt" and value for a
                
                // this version does the eval the in the enviroment which creates the symbol "ans"
                //var ans = env.lookup("ans").toValue(int).v; // retrieve value for ans
                //b = ans;

                // this version just returns the GenValue from the eval call
                var ans = eval(ast,env);
                b = ans.toValue(int).v; // put answer into b
            }
            writeln(A);
            writeln(B);
        }
        catch e: Error {
            writeln(e.message());
            f = false;
        }

        return f;
    }

    proc test_parse_then_eval(prog: string) {
        if test_parse(prog) {test_eval(prog);} else {writeln("error!");}
    }
    
    /* test */
    proc main() {

        // very simple scheme
        // all symbols are in a predifined map

        // syntax error
        writeln(">>> Syntax error");
        var prog = "(:= ans (if (and (>= elt 5) (<= elt 5)) (+ elt 100 (- elt 10)))";
        test_parse_then_eval(prog);

        // syntax error
        writeln(">>> Syntax error");
        prog = "(:= ans (if (and (>= elt 5 (<= elt 5)) (+ elt 100) (- elt 10)))";
        test_parse_then_eval(prog);

        // eval error
        writeln(">>> Eval error: unkown symbol");
        prog = "(if (and (>= a 5) (<= elt 5)) (+ elt 100) (- elt 10))";
        test_parse_then_eval(prog);

        // eval error
        writeln(">>> Eval error: wrong numbe of args");
        prog = "(if (and (>= elt 5) (<= elt 5 1)) (+ elt 100) (- elt 10))";
        test_parse_then_eval(prog);

        // this returns the answer from the eval and also sets "ans" in the env
        writeln(">>> ans symbol");
        prog = "(:= ans (if (and (>= elt 5) (<= elt 5)) (+ elt 100) (- elt 10)))";
        test_parse_then_eval(prog);

        // this one only returns the answer from the eval
        writeln(">>> val returned from eval");
        prog = "(if (and (>= elt 5) (<= elt 5)) (+ elt 100) (- elt 10))";
        test_parse_then_eval(prog);

    }
}
