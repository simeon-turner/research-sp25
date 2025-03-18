"""
Functional level model for the 2x2 matrix multiplier
"""

class matrix_mult:
  def __init__(self, A, B, C, n):
    assert len(A) == n*n
    assert len(B) == n*n
    assert len(C) == n*n
    
    self.A0 = A
    self.B0 = B
    self.C0 = C

    self.n = n

    self.A0_tmp = 0
    self.B0_tmp = 0
    self.C0_tmp = 0

    self.i = 0
    self.j = 0
    self.k = 0
  
  def init_i(self):
    self.i = 0

  def init_j(self):
    self.j = 0

  def init_k(self):
    self.k = 0

  def incr_i(self):
    self.i += 1

  def incr_j(self):
    self.j += 1

  def incr_k(self):
    self.k += 1
  
  def reset_C0_tmp(self):
    self.C0_tmp = 0
  
  def calc_addr(self): # returns a value
    addrA = self.n*self.i + self.k
    addrB = self.n*self.k + self.j

    return addrA, addrB
  
  def write_tmp_regs(self, addrA, addrB):
    self.A0_tmp = self.A0[addrA]
    self.B0_tmp = self.B0[addrB]

  def multiply(self): # returns a value
    return self.A0_tmp * self.B0_tmp

  def update(self, mult_val):
    self.C0_tmp += mult_val

  def write_val(self):
    addr = self.n*self.i + self.j
    self.C0[addr] = self.C0_tmp
  
  def control(self):
    self.init_i()

    for I in range(self.n):
      self.init_j()

      for J in range(self.n):
        self.init_k()
        self.reset_C0_tmp()

        for K in range(self.n):
          addrA, addrB = self.calc_addr()
          self.write_tmp_regs(addrA, addrB)

          mult_val = self.multiply()
          self.update(mult_val)

          self.incr_k()
        self.write_val()
        self.incr_j()
      self.incr_i()


if __name__ == "__main__":

  # For 2x2 matrix
  print("========================= 2x2 =========================")
  print()

  A0 = [1, 1, 1, 1]
  B0 = [15, 4, 3, 8]
  C0 = [0, 0, 0, 0]
  size = 2

  hw = matrix_mult(A0, B0, C0, size)
  print("INPUT MATRICES")
  print(hw.A0)
  print(hw.B0)
  print(hw.C0)
  print()

  hw.control()

  print("OUTPUT MATRICES")
  print(hw.A0)
  print(hw.B0)
  print(hw.C0)

  # For 4x4 matrix
  print()
  print("========================= 4x4 =========================")
  print()

  A0 = [
      1,
      2,
      3,
      4,
      8,
      4,
      5,
      2,
      0,
      0,
      1,
      7,
      13,
      5,
      9,
      7
    ]
  B0 = [
      15,
      4,
      3,
      8,
      5,
      3,
      7,
      9,
      0,
      24,
      4,
      6,
      7,
      3,
      8,
      8
    ]
  C0 = [0 for x in range(16)]
  size = 4

  hw = matrix_mult(A0, B0, C0, size)
  print("INPUT MATRICES")
  print(hw.A0)
  print(hw.B0)
  print(hw.C0)
  print()

  hw.control()

  print("OUTPUT MATRICES")
  print(hw.A0)
  print(hw.B0)
  print(hw.C0)
