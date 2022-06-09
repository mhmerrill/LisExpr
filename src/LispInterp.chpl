module LisExpr
{
    class ErrorWithMsg: Error
    {
        var msg: string;
    }
    
    public use List;
    
    /* list value type */
    enum LVT {Lst, Sym, I, R};
    
    type Symbol = string;

    /* type: list of genric list values */
    type GenList = list(owned GenListValue);

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
              var copyList = copyOwnedList(this.toListValue(GenList).lv);
              return new owned ListValue(copyList);
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
            otherwise {throw new owned ErrorWithMsg("not implemented");}
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
            // for non-lists, we can just initialize via assignment
            if (!isListType(vtype)) {
              this.lv = val;
            }
            this.complete();
            // for lists, we need a helper function; see copyOwnedList() for
            // an explanation.
            if (isListType(vtype)) {
              try! copyOwnedList(this.lv, val);
            }
        }
        
    }

    // Helpers to determine whether something is a list or not.
    // Should we have to write these ourselves?  See
    // https://github.com/chapel-lang/chapel/issues/16171
    proc isListType(type t: list(?)) param {
      return true;
    }

    proc isListType(type t) param {
      return false;
    }

    // lists of non-nilable owned aren't copyable via assignment
    // because it's not clear what would happen to the rhs 'owned'
    // variables.  They'd transfer ownership which would make the
    // original list useless; and even if that was OK, there's no good
    // value to assign to the RHS list elements.  In the context of
    // this work, we know we'd want to deep copy such lists, so the
    // following two helpers do that in one-arg (+ return) and
    // two-args forms.  For further discussion on this, see
    // https://github.com/chapel-lang/chapel/issues/16167
    proc copyOwnedList(src: list(?t, ?p)): list(t, p) throws {
      var dst: list(t, p);
      for item in src {
        dst.append(item.copy());
      }
      return dst;
    }

    proc copyOwnedList(ref dst: list(?t,?p), src: list(t, ?p2)) throws {
      for item in src {
        dst.append(item.copy());
      }
    }

    // allowed value types int and real
    enum VT {I, R};

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
                otherwise { throw new owned ErrorWithMsg("not implemented"); }
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
            otherwise {throw new owned ErrorWithMsg("not implemented");}
        }
    }

    inline operator -(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value(l.toValue(int).v - r.toValue(int).v);}
            when (VT.I, VT.R) {return new owned Value(l.toValue(int).v - r.toValue(real).v);}
            when (VT.R, VT.I) {return new owned Value(l.toValue(real).v - r.toValue(int).v);}
            when (VT.R, VT.R) {return new owned Value(l.toValue(real).v - r.toValue(real).v);}
            otherwise {throw new owned ErrorWithMsg("not implemented");}
        }
    }

    inline operator *(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value(l.toValue(int).v * r.toValue(int).v);}
            when (VT.I, VT.R) {return new owned Value(l.toValue(int).v * r.toValue(real).v);}
            when (VT.R, VT.I) {return new owned Value(l.toValue(real).v * r.toValue(int).v);}
            when (VT.R, VT.R) {return new owned Value(l.toValue(real).v * r.toValue(real).v);}
            otherwise {throw new owned ErrorWithMsg("not implemented");}
        }
    }

    inline operator <(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value((l.toValue(int).v < r.toValue(int).v):int);}
            when (VT.I, VT.R) {return new owned Value((l.toValue(int).v < r.toValue(real).v):int);}
            when (VT.R, VT.I) {return new owned Value((l.toValue(real).v < r.toValue(int).v):int);}
            when (VT.R, VT.R) {return new owned Value((l.toValue(real).v < r.toValue(real).v):int);}
            otherwise {throw new owned ErrorWithMsg("not implemented");}
        }
    }

    inline operator >(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value((l.toValue(int).v > r.toValue(int).v):int);}
            when (VT.I, VT.R) {return new owned Value((l.toValue(int).v > r.toValue(real).v):int);}
            when (VT.R, VT.I) {return new owned Value((l.toValue(real).v > r.toValue(int).v):int);}
            when (VT.R, VT.R) {return new owned Value((l.toValue(real).v > r.toValue(real).v):int);}
            otherwise {throw new owned ErrorWithMsg("not implemented");}
        }
    }

    inline operator <=(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value((l.toValue(int).v <= r.toValue(int).v):int);}
            when (VT.I, VT.R) {return new owned Value((l.toValue(int).v <= r.toValue(real).v):int);}
            when (VT.R, VT.I) {return new owned Value((l.toValue(real).v <= r.toValue(int).v):int);}
            when (VT.R, VT.R) {return new owned Value((l.toValue(real).v <= r.toValue(real).v):int);}
            otherwise {throw new owned ErrorWithMsg("not implemented");}
        }
    }

    inline operator >=(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value((l.toValue(int).v >= r.toValue(int).v):int);}
            when (VT.I, VT.R) {return new owned Value((l.toValue(int).v >= r.toValue(real).v):int);}
            when (VT.R, VT.I) {return new owned Value((l.toValue(real).v >= r.toValue(int).v):int);}
            when (VT.R, VT.R) {return new owned Value((l.toValue(real).v >= r.toValue(real).v):int);}
            otherwise {throw new owned ErrorWithMsg("not implemented");}
        }
    }

    inline operator ==(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value((l.toValue(int).v == r.toValue(int).v):int);}
            when (VT.I, VT.R) {return new owned Value((l.toValue(int).v == r.toValue(real).v):int);}
            when (VT.R, VT.I) {return new owned Value((l.toValue(real).v == r.toValue(int).v):int);}
            when (VT.R, VT.R) {return new owned Value((l.toValue(real).v == r.toValue(real).v):int);}
            otherwise {throw new owned ErrorWithMsg("not implemented");}
        }
    }

    inline operator !=(l: borrowed GenValue, r: borrowed GenValue): owned GenValue throws {
        select (l.vt, r.vt) {
            when (VT.I, VT.I) {return new owned Value((l.toValue(int).v != r.toValue(int).v):int);}
            when (VT.I, VT.R) {return new owned Value((l.toValue(int).v != r.toValue(real).v):int);}
            when (VT.R, VT.I) {return new owned Value((l.toValue(real).v != r.toValue(int).v):int);}
            when (VT.R, VT.R) {return new owned Value((l.toValue(real).v != r.toValue(real).v):int);}
            otherwise {throw new owned ErrorWithMsg("not implemented");}
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
            otherwise {throw new owned ErrorWithMsg("not implemented");}
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
              throw new owned ErrorWithMsg("undefined symbol error " + name);
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
