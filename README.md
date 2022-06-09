# LisExpr
Mike's version of a simple Lisp interpreter written in Chapel

Inspration taken from http://norvig.com/lispy.html

Goal: make a promoted Lisp interpreter written in Chapel which takes a Lisp expression and executes it in parallel over a Chapel `forall` loop on a set distributed arrays.

more to come