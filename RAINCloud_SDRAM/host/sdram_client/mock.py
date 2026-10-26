"""Deterministic API mock. Cycle/performance numbers are synthetic, never hardware evidence."""
from .client import Configuration
from dataclasses import astuple

class MockTransport:
    def __init__(self):
        self.regs = {0:0x5344524d, 4:0x10001, 8:0x26101404, 12:0xff,
                     0x10:16, 0x14:0, 0x18:0, 0x1c:50000000, 0x40:0, 0x44:1,
                     0x48:0, 0x4c:0, 0x50:0, 0x54:0, 0x58:1024, 0x5c:0x1000}
        self.regs.update({0x20+4*i:v for i,v in enumerate(astuple(Configuration()))})
        self.memory = {}
        self.ticks = 0
        self.opcode = 0
        self.snapshot = [0]*16
        self.result = [0]*16
        self.log = [0]*16

    def read32(self, address, count=1):
        if address == 0x10 and self.ticks:
            self.ticks -= 1
            self.regs[0x48] += 1
            if not self.ticks: self._finish()
        return [self.snapshot[(a-0x80)//4] if 0x80 <= a < 0xc0 else
                self.log[(a-0x180)//4] if 0x180 <= a < 0x1c0 else self.regs.get(0x1000+a-0x100 if 0x100 <= a < 0x140 else a,0)
                for a in range(address,address+count*4,4)]

    def write32(self, address, values):
        for i,value in enumerate(values):
            a = address+4*i
            if 0x100 <= a < 0x140: a = 0x1000+a-0x100
            if a == 0x14:
                if value == self.regs[0x14]: continue
                self.regs[0x14],self.regs[0x18] = value,0
                op = value & 255
                status = self.regs[0x10]
                if op == 6:
                    if status & 2 and not status & 32: self.regs[0x18] = 1
                    else: self.regs[0x10] |= 32
                elif op == 7:
                    if status & 2: self.regs[0x18] = 1
                    else: self.regs[0x10] &= ~32
                elif op == 2:
                    if status & 2:
                        self.ticks = 0
                        self._finish(stopped=True)
                elif op == 3:
                    self.snapshot = self.result[:]
                    self.snapshot[1] = self.regs[0x10]
                    self.regs[0x4c] += 1
                elif op in (1,4,5):
                    if not status & 32: self.regs[0x18] = 3
                    elif status & 2: self.regs[0x18] = 1
                    else:
                        try:
                            if op == 1: Configuration(*self.read32(0x20,8)).validate()
                            else:
                                from .client import Tester
                                Tester._range(self.regs[0x40],self.regs[0x44])
                        except ValueError:
                            self.regs[0x18] = 2
                            continue
                        self.regs[0x50] += 1
                        self.regs[0x10] = 16|32|2
                        self.ticks,self.opcode = 5,op
                        self.result = [0]*16
                        self.result[0] = self.regs[0x50]
                else: self.regs[0x18] = 4
            elif self.regs[0x10] & 32 and not self.regs[0x10] & 2:
                self.regs[a] = value

    def _finish(self, stopped=False):
        if self.opcode in (4,5):
            addr,count = self.regs[0x40],self.regs[0x44]
            for i in range(count):
                old = self.memory.get(addr+2*i,0)
                value = self.regs.get(0x1000+4*i,0x30000)
                if self.opcode == 5:
                    if value & 0x10000: old = (old & 0xff00) | (value & 0xff)
                    if value & 0x20000: old = (old & 0xff) | (value & 0xff00)
                    self.memory[addr+2*i] = old
                else: self.regs[0x1000+4*i] = old | 0x30000
            ops = count
        else:
            addr,count = self.regs[0x20],self.regs[0x24]
            ops = count*self.regs[0x28]*(7 if self.regs[0x2c] == 6 else 2)
        if stopped: ops = 0
        self.regs[0x10] = 16|32|4|(8 if stopped else 0)
        self.result = [self.regs[0x50], self.regs[0x10], ops & 0xffffffff, 2*ops & 0xffffffff,
                       (2*ops)>>32, ops*20 & 0xffffffff, (ops*20)>>32, 0,0,0,0,ops>>32,
                       self.regs[0x48],addr,count,self.regs[0x2c]]

    def close(self): pass  # Closing the host never resets the FPGA model.
