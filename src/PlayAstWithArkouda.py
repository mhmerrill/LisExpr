
import arkouda as ak

from arkouda_lambda import arkouda_func

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

@arkouda_func
def my_filter3(v : ak.int64, x : ak.pdarray, y : ak.pdarray) -> ak.pdarray:
    (a := v*10)
    return ((y+1) if (not (x < a) and (x >= 0)) else (y-1))

# try it out
ak.connect()
x = ak.ones(10)
y = ak.zeros(10)
a = 5.0

#ret = my_axpy(5.0,x,y)

ret = my_axpy(a,x,y)

#ret = my_filter(5,x,y)

#ret = my_filter2(5,x,y)

#ret = my_filter3(5,x,y)

