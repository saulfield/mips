from struct import *

# opcodes
OP_RTYPE = 0b000000
OP_BEQ   = 0b000100
OP_LW    = 0b100011
OP_SW    = 0b101011

# registers
reg = {
    '$0': 0,
    '$at': 1,
    '$v0': 2,  '$v1': 3,
    '$a0': 4,  '$a1': 5,  '$a2': 6,  '$a3': 7,
    '$t0': 8,  '$t1': 9,  '$t2': 10, '$t3': 11,
    '$t4': 12, '$t5': 13, '$t6': 14, '$t7': 15,
}

# instruction types
def R_TYPE(op, rs, rt, rd, shamt, funct):
    return ((op << 25) |
            (rs << 20) |
            (rt << 15) |
            (rd << 10) |
            (shamt << 6) |
            (funct))

def I_TYPE(op, rs, rt, imm):
    return ((op << 26) |
            (rs << 21) |
            (rt << 16) |
            (imm))

# instructions
# R-type
def ADD(): pass
    # return R_TYPE(OP_RTYPE)

def SUB(): pass
    # return R_TYPE(OP_RTYPE)

def AND(): pass
    # return R_TYPE(OP_RTYPE)

def OR(): pass
    # return R_TYPE(OP_RTYPE)

def SLT(): pass
    # return R_TYPE(OP_RTYPE)

# I-type
# LW rt, offset(base)
def LW(rt, base, offset):
    return I_TYPE(OP_LW, reg[base], reg[rt], offset)

# SW rt, offset(base)
def SW(rt, base, offset):
    return I_TYPE(OP_SW, reg[base], reg[rt], offset)

def BEQ(): pass
    # return I_TYPE(OP_BEQ)

# lw $t2, 32($0)
# 100011 00000 01010 0000 0000 0010 0000
# 100011 00000 01010 0000 0000 0010 0000

code = [
    LW('$t2', '$0', 1),
    SW('$t2', '$0', 2)
]

binary = False

if binary:
    code_bytes = pack('2I', *code)
    with open('code.bin', 'wb') as f:
        f.write(code_bytes)
else:
    with open('rtl/code.dat', 'w') as f:
        for i in code:
            text = format(i, 'b')
            print(text)
            f.write(text + '\n')