#!/usr/bin/env python
    
ENV = globals().copy() # Clean user environment
COMMANDS = [] # Result buffer

OP_SHIFT = 12
SLOT1_SHIFT = OP_SHIFT - 4
SLOT2_SHIFT = SLOT1_SHIFT - 4

from inspect import getouterframes, currentframe
def here():
    '''Get file and line number in source file'''
    try:
        return getouterframes(currentframe())[3][1:3]
    except:
        return "???", 0

def out(type, file, line, msg):
    '''Output message'''
    print "%s:%d: %s: %s" % (file, line, type, msg)

def error(file, line, msg):
    '''Print error message'''
    out("error", file, line, msg)

def warn(file, line, msg):
    '''Print warning message'''
    out("warning", file, line, msg)

class ASM:
    '''Base ASM instruction'''
    def __init__(self):
        self.file, self.line = here()
        COMMANDS.append(self)

class lri(ASM):
    '''lri instruction'''
    def __init__(self, dest, imm):
        ASM.__init__(self)
        self.code = 1
        self.dest = dest
        if imm >= (1 << 8): # Check that imm is valid
            warn(self.file, self.line, "0x%X too big, will truncate" % imm)
            addr &= ((1 << 8) - 1) # Mask all bits above 8
        self.imm = imm

    def genbits(self):
        return (self.code << OP_SHIFT) | \
               (self.imm << SLOT2_SHIFT) | \
               (self.dest)

class ALU3(ASM):
    '''ALU instruction with 3 operands'''
    def __init__(self, src1, src2, dest):
        ASM.__init__(self)
        self.src1 = src1
        self.src2 = src2
        self.dest = dest

    def genbits(self):
        return (self.code << OP_SHIFT) | \
               (self.src1 << SLOT1_SHIFT) | \
               (self.src2 << SLOT2_SHIFT)  | \
               (self.dest)

class add(ALU3):
    '''`add' instruction'''
    code = 4
'''
class sub(ALU3):
    code = 1

class move(ASM):
    def __init__(self, src, dest):
        ASM.__init__(self)
        self.src = src
        self.dest = dest

    def genbits(self):
        return (2 << OP_SHIFT) | \
               (self.src << SLOT1_SHIFT) | \
               (self.dest << SLOT2_SHIFT)

class MemOp(ASM):
    def __init__(self, reg, addr):
        ASM.__init__(self)
        self.reg = reg
        if addr >= (1 << 16): # Check that address is valid
            warn(self.file, self.line, "0x%X too big, will truncate" % addr)
            addr &= ((1 << 16) - 1) # Mask all bits above 16
        self.addr = addr

    def genbits(self):
        return (self.code << OP_SHIFT) | \
               (self.reg << SLOT1_SHIFT) | \
               self.addr

class load(MemOp):
    code = 3

class store(MemOp):
    code = 4
    
class jmp(ASM):
    def __init__(self, dest):
        ASM.__init__(self)
        self.dest = dest

    def genbits(self):
        return (5 << OP_SHIFT) | self.dest
'''
def label(name):
    '''Setting a label'''
    ENV[name] = len(COMMANDS)

# Setup user environment
# Add registers
for i in range(16):
    ENV["r%d" % i] = i 

# Add operators
#for op in (add, sub, move, load, store, label, jmp):
for op in (add, lri, label):
    ENV[op.__name__] = op

def parse(fname):
    '''Parse file '''
    global COMMANDS
    COMMANDS = []
    execfile(fname, ENV, {})
    return COMMANDS

from os.path import splitext, isfile
from array import array
from sys import exc_info, byteorder
from optparse import OptionParser
parser = OptionParser(usage="usage: %prog [options] FILE", version="0.1")
parser.add_option("-o", "--output", help="output file", dest="outfile",
    default="")
parser.add_option("-g", help="create debug file", dest="debug",
    action="store_true", default=0)

opts, args = parser.parse_args()
if len(args) != 1:
    parser.error("wrong number of arguments") # Will exit

infile = args[0]
if not isfile(infile):
    raise SystemExit("can't find %s" % infile)

try:
    commands = parse(infile)
except SyntaxError, e:
    error(e.filename, e.lineno, e.msg)
    raise SystemExit(1)
except Exception, e:
    # Get last traceback and print it
    # Most of this code is taken from traceback.py:print_exception
    etype, value, tb = exc_info()
    while tb: # Find last traceback
        last = tb
        tb = tb.tb_next
    lineno = last.tb_lineno # Line number
    f = last.tb_frame
    co = f.f_code
    error(co.co_filename, lineno, e)
    etype = value = tb = None # Release objects (not sure this is required ...)
    raise SystemExit(1)

a = array("H")
for cmd in commands:
    a.append(cmd.genbits())
if byteorder == "little":
        a.byteswap()
if not opts.outfile:
    opts.outfile = splitext(infile)[0] + ".o"
open(opts.outfile, "wb").write(a.tostring())
if opts.debug: # Emit debug information
    dbg = open(splitext(infile)[0] + ".dbg", "w")
    for cmd in commands:
        print >> dbg, "%s:%s" % (cmd.file, cmd.line)
