module LisExprData
{

    public use List;
    
    type Symbol = string;

   /* allowed list value types */
    enum LVT {Lst, Sym, I, R};
    
    /* allowed value types in the eval */
    /* in a real scheme/lisp interpreter these two enums (LVT and VT) would be the same */
    enum VT {I, R};

    /*
      List Class wraps the standard List which is a record
      forwarding the interface to the class definition
      this gives me a more familiar feel to lists in python
    */
    class ListClass {
      type etype;
      forwarding var l: list(etype);
    }
    
    /* type: list of genric list values */
    type GenList = shared ListClass(owned GenListValue);

    /* generic list value */
    class GenListValue
    {
        var lvt: LVT;
        
        /* initialize the list value type so we can test it at runtime */
        proc init(type lvtype) {
            if (lvtype == GenList)            {lvt = LVT.Lst;}
            if (lvtype == Symbol)             {lvt = LVT.Sym;}
            if (lvtype == int)                {lvt = LVT.I;}
            if (lvtype == real)               {lvt = LVT.R;}
        }
        
        /* cast to the GenListValue to borrowed ListValue(vtype) halt on failure */
        inline proc toListValue(type lvtype) {
            return try! this :borrowed ListValue(lvtype);
        }

        /* returns a copy of this... an owned GenListValue */
        proc copy(): owned GenListValue throws {
          select (this.lvt) {
            when (LVT.Lst) {
              return new owned ListValue(this.toListValue(GenList).lv);
            }
            when (LVT.Sym) {
              return new owned ListValue(this.toListValue(Symbol).lv);
            }
            when (LVT.I) {
              return new owned ListValue(this.toListValue(int).lv);
            }
            when (LVT.R) {
              return new owned ListValue(this.toListValue(real).lv);
            }
            otherwise {throw new owned Error("not implemented");}
          }
        }
    }
    
    /* concrete list value */
    class ListValue : GenListValue
    {
        type lvtype;
        var lv: lvtype;
        
        /* initialize the value and the vtype */
        proc init(val: ?vtype) {
            super.init(vtype);
            this.lvtype = vtype;
            this.lv = val;
            this.complete();
        }
        
    }


    /* generic value class */
    class GenValue
    {
        /* value type testable at runtime */
        var vt: VT;
    
        /* initialize the value type so we can test it at runtime */
        proc init(type vtype) {
            if (vtype == int)  {vt = VT.I;}
            if (vtype == real) {vt = VT.R;}
        }
        
        /* cast to the GenValue to borrowed Value(vtype) halt on failure */
        inline proc toValue(type vtype) {
            return try! this :borrowed Value(vtype);
        }

        /* returns a copy of this... an owned GenValue */
        proc copy(): owned GenValue throws {
            select (this.vt) {
                when (VT.I) {return new owned Value(this.toValue(int).v);}
                when (VT.R) {return new owned Value(this.toValue(real).v);}
                otherwise { throw new owned Error("not implemented"); }
            }
        }
    }
    
    /* concrete value class */
    class Value : GenValue
    {
        type vtype; // value type
        var v: vtype; // value
        
        /* initialize the value and the vtype */
        proc init(val: ?vtype) {
            super.init(vtype);
            this.vtype = vtype;
            this.v = val;
        }
    }

    //////////////////////////////////////////
    // operators over GenValue
    //////////////////////////////////////////
    
    inline operator +(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value(l.toValue(int).v + r.toValue(int).v);}
            when (VT.I, VT.R) {return new owned Value(l.toValue(int).v + r.toValue(real).v);}
            when (VT.R, VT.I) {return new owned Value(l.toValue(real).v + r.toValue(int).v);}
            when (VT.R, VT.R) {return new owned Value(l.toValue(real).v + r.toValue(real).v);}
            otherwise {throw new owned Error("not implemented");}
        }
    }

    inline operator -(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value(l.toValue(int).v - r.toValue(int).v);}
            when (VT.I, VT.R) {return new owned Value(l.toValue(int).v - r.toValue(real).v);}
            when (VT.R, VT.I) {return new owned Value(l.toValue(real).v - r.toValue(int).v);}
            when (VT.R, VT.R) {return new owned Value(l.toValue(real).v - r.toValue(real).v);}
            otherwise {throw new owned Error("not implemented");}
        }
    }

    inline operator *(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value(l.toValue(int).v * r.toValue(int).v);}
            when (VT.I, VT.R) {return new owned Value(l.toValue(int).v * r.toValue(real).v);}
            when (VT.R, VT.I) {return new owned Value(l.toValue(real).v * r.toValue(int).v);}
            when (VT.R, VT.R) {return new owned Value(l.toValue(real).v * r.toValue(real).v);}
            otherwise {throw new owned Error("not implemented");}
        }
    }

    inline operator <(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value((l.toValue(int).v < r.toValue(int).v):int);}
            when (VT.I, VT.R) {return new owned Value((l.toValue(int).v < r.toValue(real).v):int);}
            when (VT.R, VT.I) {return new owned Value((l.toValue(real).v < r.toValue(int).v):int);}
            when (VT.R, VT.R) {return new owned Value((l.toValue(real).v < r.toValue(real).v):int);}
            otherwise {throw new owned Error("not implemented");}
        }
    }

    inline operator >(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value((l.toValue(int).v > r.toValue(int).v):int);}
            when (VT.I, VT.R) {return new owned Value((l.toValue(int).v > r.toValue(real).v):int);}
            when (VT.R, VT.I) {return new owned Value((l.toValue(real).v > r.toValue(int).v):int);}
            when (VT.R, VT.R) {return new owned Value((l.toValue(real).v > r.toValue(real).v):int);}
            otherwise {throw new owned Error("not implemented");}
        }
    }

    inline operator <=(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value((l.toValue(int).v <= r.toValue(int).v):int);}
            when (VT.I, VT.R) {return new owned Value((l.toValue(int).v <= r.toValue(real).v):int);}
            when (VT.R, VT.I) {return new owned Value((l.toValue(real).v <= r.toValue(int).v):int);}
            when (VT.R, VT.R) {return new owned Value((l.toValue(real).v <= r.toValue(real).v):int);}
            otherwise {throw new owned Error("not implemented");}
        }
    }

    inline operator >=(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value((l.toValue(int).v >= r.toValue(int).v):int);}
            when (VT.I, VT.R) {return new owned Value((l.toValue(int).v >= r.toValue(real).v):int);}
            when (VT.R, VT.I) {return new owned Value((l.toValue(real).v >= r.toValue(int).v):int);}
            when (VT.R, VT.R) {return new owned Value((l.toValue(real).v >= r.toValue(real).v):int);}
            otherwise {throw new owned Error("not implemented");}
        }
    }

    inline operator ==(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value((l.toValue(int).v == r.toValue(int).v):int);}
            when (VT.I, VT.R) {return new owned Value((l.toValue(int).v == r.toValue(real).v):int);}
            when (VT.R, VT.I) {return new owned Value((l.toValue(real).v == r.toValue(int).v):int);}
            when (VT.R, VT.R) {return new owned Value((l.toValue(real).v == r.toValue(real).v):int);}
            otherwise {throw new owned Error("not implemented");}
        }
    }

    inline operator !=(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value((l.toValue(int).v != r.toValue(int).v):int);}
            when (VT.I, VT.R) {return new owned Value((l.toValue(int).v != r.toValue(real).v):int);}
            when (VT.R, VT.I) {return new owned Value((l.toValue(real).v != r.toValue(int).v):int);}
            when (VT.R, VT.R) {return new owned Value((l.toValue(real).v != r.toValue(real).v):int);}
            otherwise {throw new owned Error("not implemented");}
        }
    }

    inline proc and(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        return new owned Value((l && r):int);
    }

    inline proc or(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        return new owned Value((l || r):int);
    }

    inline proc not(l: borrowed GenValue): owned GenValue throws {
        return new owned Value((! isTrue(l)):int);
    }

    inline proc isTrue(gv: borrowed GenValue): bool throws {
        select (gv.vt) {
            when (VT.I) {return (gv.toValue(int).v != 0);}
            when (VT.R) {return (gv.toValue(real).v != 0.0);}
            otherwise {throw new owned Error("not implemented");}
        }
    }
    
    /* environment is a dictionary of {string:GenValue} */
    class Env
    {
        /* what data structure to use ??? assoc array over strings or a map ? */
        var tD: domain(string);
        var tab: [tD] owned GenValue?;

        /* add a new entry or set an entry to a new value */
        proc addEntry(name:string, val: ?t): borrowed Value(t) throws {
            var entry = new owned Value(val);
            if (!tD.contains(name)) {tD += name;};
            ref tableEntry = tab[name];
            tableEntry = entry;
            return tableEntry!.borrow().toValue(t);
        }

        /* add a new entry or set an entry to a new value */
        proc addEntry(name:string, in entry: owned GenValue): borrowed GenValue throws {
            if (!tD.contains(name)) {tD += name;};
            ref tableEntry = tab[name];
            tableEntry = entry;
            return tableEntry!.borrow();
        }

        /* lookup symbol and throw error if not found */
        proc lookup(name: string): borrowed GenValue throws {
            if (!tD.contains(name) || tab[name] == nil) {
              throw new owned Error("undefined symbol error " + name);
            }
            return tab[name]!;
        }

        /* delete entry -- not sure if we need this */
        proc deleteEntry(name: string) {
            import IO.stdout;
            if (tD.contains(name)) {
                tab[name] = nil;
                tD -= name;
            }
            else {
                writeln("unkown symbol ",name);
                try! stdout.flush();
            }
        }
    }


}