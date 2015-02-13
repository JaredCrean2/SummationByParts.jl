# This file gathers together functions used to build the SBP operators

@doc """
### SummationByParts.bndrynodalexpansion

Computes the transformation matrix that maps the Proriol orthogonal polynomials
to polynomials that are nodal on the boundary nodes, i.e. if E is the
transformation matrix and P is the matrix of Proriol polys, with the polynomials
listed by row, then P*E = I, when restricted to the boundary nodes.

**Inputs**

* `cub`: symmetric cubature rule
* `vtx`: vertices of the right simplex
* `d`: maximum total degree for the Proriol polynomials

**Outputs**

* `E`: transformation matrix

"""->
function bndrynodalexpansion{T}(cub::TriSymCub{T}, vtx::Array{T,2}, d::Int)
  numbndry = SymCubatures.getnumboundarynodes(cub)
  N = convert(Int64, (d+1)*(d+2)/2)
  xaug = zeros(T, N)
  yaug = zeros(T, N)
  x, y = SymCubatures.calcnodes(cub, vtx)
  xaug[1:numbndry] = x[1:numbndry]
  yaug[1:numbndry] = y[1:numbndry]
  # set the augmented interior nodes that make a unisolvent set for polys; use
  # uniform points in the interior for now
  ptr = numbndry+1
  for j = 1:(d-2)
    eta = 2.*j/d-1
    for i = 1:(d-j-1)
      xi = 2.*i/d-1
      xaug[ptr] = xi
      yaug[ptr] = eta
      ptr += 1
    end
  end
  V = zeros(T, (N, N))
  ptr = 1
  for r = 0:d
    for j = 0:r
      i = r-j
      V[:,ptr] = OrthoPoly.proriolpoly(xaug, yaug, i, j)
      ptr += 1
    end
  end
  return inv(V)
end

function bndrynodalexpansion{T}(cub::TetSymCub{T}, vtx::Array{T,2}, d::Int)
  numbndry = SymCubatures.getnumboundarynodes(cub)
  N = convert(Int64, (d+1)*(d+2)*(d+3)/6)
  xaug = zeros(T, N)
  yaug = zeros(T, N)
  zaug = zeros(T, N)
  x, y, z = SymCubatures.calcnodes(cub, vtx)
  xaug[1:numbndry] = x[1:numbndry]
  yaug[1:numbndry] = y[1:numbndry]
  zaug[1:numbndry] = z[1:numbndry]
  # set the augmented interior nodes that make a unisolvent set for polys; use
  # uniform points in the interior for now
  ptr = numbndry+1
  for k = 1:(d-3)
    zeta = 2.*k/d-1
    for j = 1:(d-k-2)
      eta = 2.*j/d-1
      for i = 1:(d-j-k-1)
        xi = 2.*i/d-1
        xaug[ptr] = xi
        yaug[ptr] = eta
        zaug[ptr] = zeta
        ptr += 1
      end
    end
  end
  V = zeros(T, (N, N))
  ptr = 1
  for r = 0:d
    for k = 0:r
      for j = 0:r-k
        i = r-j-k
        V[:,ptr] = OrthoPoly.proriolpoly(xaug, yaug, zaug, i, j, k)
        ptr += 1
      end
    end
  end
  return inv(V)
end

@doc """
### SummationByParts.boundaryoperators

Finds and returns the element mass matrix, `w`, as well as the symmetric part of
the SBP operators, `Ex`, `Ey` (`Ez`).  The latter operators coorespond to
boundary integrals in the divergence theorem, and are related to the mass
matrices of the boundary facets.

**Inputs**

* `cub`: symmetric cubature rule
* `vtx`: vertices of the right simplex
* `d`: maximum total degree for the Proriol polynomials

**Outputs**

* `Ex`, `Ey` (`Ez`): symmetric parts of the SBP first derivative operators

"""->
function boundaryoperators{T}(cub::TriSymCub{T}, vtx::Array{T,2}, d::Int)
  numbndry = SymCubatures.getnumboundarynodes(cub)
  N = convert(Int, (d+1)*(d+2)/2 )
  # compute the derivatives of the ortho polys
  P = zeros(T, (cub.numnodes,N) )
  dPdx = zeros(P)
  dPdy = zeros(P)
  x, y = SymCubatures.calcnodes(cub, vtx)
  ptr = 1
  for r = 0:d
    for j = 0:r
      i = r-j
      P[:,ptr] = OrthoPoly.proriolpoly(x, y, i, j)
      dPdx[:,ptr], dPdy[:,ptr] = OrthoPoly.diffproriolpoly(x, y, i, j)
      ptr += 1
    end
  end
  E = SummationByParts.bndrynodalexpansion(cub, vtx, d)
  P *= E
  dPdx *= E
  dPdy *= E
  # compute and return the boundary operators
  w = SymCubatures.calcweights(cub)
  Ex = zeros(T, (cub.numnodes,cub.numnodes) )
  Ey = zeros(Ex)
  Q = P.'*diagm(w)*dPdx
  Ex[1:numbndry,1:numbndry] = Q[1:numbndry,1:numbndry] + Q[1:numbndry,1:numbndry].'
  Q = P.'*diagm(w)*dPdy
  Ey[1:numbndry,1:numbndry] = Q[1:numbndry,1:numbndry] + Q[1:numbndry,1:numbndry].'
  return Ex, Ey
end

function boundaryoperators{T}(cub::TetSymCub{T}, vtx::Array{T,2}, d::Int)
  numbndry = SymCubatures.getnumboundarynodes(cub)
  N = convert(Int, (d+1)*(d+2)*(d+3)/6 )
  # compute the derivatives of the ortho polys
  P = zeros(T, (cub.numnodes,N) )
  dPdx = zeros(P)
  dPdy = zeros(P)
  dPdz = zeros(P)
  x, y, z = SymCubatures.calcnodes(cub, vtx)
  ptr = 1
  for r = 0:d
    for k = 0:r
      for j = 0:r-k
        i = r-j-k
        P[:,ptr] = OrthoPoly.proriolpoly(x, y, z, i, j, k)
        dPdx[:,ptr], dPdy[:,ptr], dPdz[:,ptr] =
          OrthoPoly.diffproriolpoly(x, y, z, i, j, k)
        ptr += 1
      end
    end
  end
  E = SummationByParts.bndrynodalexpansion(cub, vtx, d)
  P *= E
  dPdx *= E
  dPdy *= E
  dPdz *= E
  # compute and return the boundary operators
  w = SymCubatures.calcweights(cub)
  Ex = zeros(T, (cub.numnodes,cub.numnodes) )
  Ey = zeros(Ex)
  Ez = zeros(Ex)
  Q = P.'*diagm(w)*dPdx
  Ex[1:numbndry,1:numbndry] = Q[1:numbndry,1:numbndry] + Q[1:numbndry,1:numbndry].'
  Q = P.'*diagm(w)*dPdy
  Ey[1:numbndry,1:numbndry] = Q[1:numbndry,1:numbndry] + Q[1:numbndry,1:numbndry].'
  Q = P.'*diagm(w)*dPdz
  Ez[1:numbndry,1:numbndry] = Q[1:numbndry,1:numbndry] + Q[1:numbndry,1:numbndry].'
  return Ex, Ey, Ez
end  

@doc """
### SummationByParts.boundarymassmatrix

Returns the (dense) mass matrix for a set of nodes on a reference boundary.
This mass matrix can be used for boundary integration or to impose boundary
conditions weakly.  The array `bndryindices` is also returned, which is a list
of element-node indices for each boundary (see also
SymCubatures.getbndryindices).

**Inputs**

* `cub`: symmetric cubature rule
* `vtx`: vertices of the right simplex
* `d`: maximum total degree for the polynomials

**Outputs**

* `Hbndry`: reference boundary mass matrix
* `bndryindices`: list of nodes that lie on each boundary

"""->
function boundarymassmatrix{T}(cub::TriSymCub{T}, vtx::Array{T,2}, d::Int)
  bndryindices = SymCubatures.getbndryindices(cub)
  numbndrynodes = size(bndryindices,1)
  x, y = SymCubatures.calcnodes(cub, vtx)
  xbndry = x[bndryindices[:,1]]
  P = zeros(T, (numbndrynodes,numbndrynodes))
  for j = 0:d
    P[:,j+1] = OrthoPoly.jacobipoly(xbndry, 0.0, 0.0, j)
  end
  A = inv(P)
  Hbndry = A.'*A
  return Hbndry, bndryindices
end

function boundarymassmatrix{T}(cub::TetSymCub{T}, vtx::Array{T,2}, d::Int)
  bndryindices = SymCubatures.getbndryindices(cub)
  numbndrynodes = size(bndryindices,1)
  x, y, z = SymCubatures.calcnodes(cub, vtx)
  xbndry = x[bndryindices[:,1]]
  ybndry = y[bndryindices[:,1]]
  P = zeros(T, (numbndrynodes,numbndrynodes))
  ptr = 1
  for r = 0:d
    for j = 0:r
      i = r-j
      P[:,ptr] = OrthoPoly.proriolpoly(xbndry, ybndry, i, j)
      ptr += 1
    end
  end
  A = inv(P)
  Hbndry = A.'*A
  return Hbndry, bndryindices
end

@doc """
### SummationByParts.accuracyconstraints

Returns the accuracy constraints on the asymmetric part of the SBP stiffness
matrices.  These constraints are linear, and for each coordinate-direction
operator (i.e. Qx, Qy,...) the system matrix `A` is the same; only the
right-hand side changes.

The columns in `A` are ordered assuming only the strictly lower triangular part
of the operators are the unknowns.  These unknowns are ordered by row and then
column.  For example, entry Q_21 = -Q_12 is the number 1 variable, and
Q_32 = -Q_23 is the number 3 variable.

**Inputs**

* `cub`: symmetric cubature rule
* `vtx`: vertices of the right simplex
* `d`: maximum total degree for the Proriol polynomials

**Outputs**

* `A`: the system matrix for the linear accuracy constraints
* `bx`,`by` (`bz`): the right-hand-sides of the accuracy constraints

"""->
function accuracyconstraints{T}(cub::TriSymCub{T}, vtx::Array{T,2}, d::Int)
  x, y = SymCubatures.calcnodes(cub, vtx) 
  Ex, Ey = SummationByParts.boundaryoperators(cub, vtx, d)
  w = SymCubatures.calcweights(cub)
  Ex *= 0.5; Ey *= 0.5
  # the number of unknowns for in the skew-symmetric matrices
  numQvars = convert(Int, cub.numnodes*(cub.numnodes-1)/2)
  # the number of accuracy equations
  numeqns = convert(Int, cub.numnodes*(d+1)*(d+2)/2)
  A = zeros(T, (numeqns, numQvars))
  bx = zeros(T, numeqns)
  by = zeros(T, numeqns)
  # loop over ortho polys up to degree d
  ptr = 0
  for r = 0:d
    for j = 0:r
      i = r-j
      P = OrthoPoly.proriolpoly(x, y, i, j)
      dPdx, dPdy = OrthoPoly.diffproriolpoly(x, y, i, j)
      # loop over the lower part of the skew-symmetric matrices
      for row = 2:cub.numnodes
        offset = convert(Int, (row-1)*(row-2)/2)
        for col = 1:row-1
          A[ptr+row, offset+col] += P[col]
          A[ptr+col, offset+col] -= P[row]
        end
      end
      bx[ptr+1:ptr+cub.numnodes] = diagm(w)*dPdx - Ex*P
      by[ptr+1:ptr+cub.numnodes] = diagm(w)*dPdy - Ey*P
      ptr += cub.numnodes
    end
  end
  return A, bx, by
end

function accuracyconstraints{T}(cub::TetSymCub{T}, vtx::Array{T,2}, d::Int)
  x, y, z = SymCubatures.calcnodes(cub, vtx) 
  Ex, Ey, Ez = SummationByParts.boundaryoperators(cub, vtx, d)
  w = SymCubatures.calcweights(cub)
  Ex *= 0.5; Ey *= 0.5; Ez *= 0.5
  # the number of unknowns for both skew-symmetric matrices Qx, Qy, and Qz
  numQvars = convert(Int, cub.numnodes*(cub.numnodes-1)/2)
  # the number of accuracy equations
  numeqns = convert(Int, cub.numnodes*(d+1)*(d+2)*(d+3)/6)
  A = zeros(T, (numeqns, numQvars))
  bx = zeros(T, numeqns)
  by = zeros(T, numeqns)
  bz = zeros(T, numeqns)
  # loop over ortho polys up to degree d
  ptr = 0
  for r = 0:d
    for k = 0:r
      for j = 0:r-k
        i = r-j-k
        P = OrthoPoly.proriolpoly(x, y, z, i, j, k)
        dPdx, dPdy, dPdz = OrthoPoly.diffproriolpoly(x, y, z, i, j, k)
        # loop over the lower part of the skew-symmetric matrices
        for row = 2:cub.numnodes
          offset = convert(Int, (row-1)*(row-2)/2)
          for col = 1:row-1
            A[ptr+row, offset+col] += P[col]
            A[ptr+col, offset+col] -= P[row]
          end
        end
        bx[ptr+1:ptr+cub.numnodes] = diagm(w)*dPdx - Ex*P
        by[ptr+1:ptr+cub.numnodes] = diagm(w)*dPdy - Ey*P
        bz[ptr+1:ptr+cub.numnodes] = diagm(w)*dPdz - Ez*P
        ptr += cub.numnodes
      end
    end
  end
  return A, bx, by, bz
end

@doc """
### SummationByParts.commuteerror

Returns the commute-error objective value.  For 2D SBP operators, this is
defined as ||H*(Dx*Dy - Dy*Dx)||^2, where the norm is the Frobenius norm.  For
3D operators, the error is defined as ||H*(Dx*Dy - Dy*Dx)||^2 + ||H*(Dx*Dz -
Dz*Dx)||^2 + ||H*(Dy*Dz - Dz*Dx||^2.

**Inputs**

* `w`: cubature rule weights
* `Qxpart`,`Qypart` (`Qzpart`): Q operators that satisfy the accuracy conditions
* `Z`: basis for the null space of the accuracy constraints (may be empty)
* `reducedsol`: the weights for `Z`; the first [1:numnodes] elements are for Qx

**Outputs**

* `f`: commute-error objective value

"""->
function commuteerror{T,T2}(w::Array{T}, Qxpart::Array{T,2}, Qypart::Array{T,2},
                            Z::Array{T,2}, reducedsol::Array{T2})
  # build Qx and Qy
  Qx = convert(Array{T2,2}, Qxpart)
  Qy = convert(Array{T2,2}, Qypart)
  numnodes = length(w)
  Qxnull = Z*reducedsol[1:size(Z,2)]
  Qynull = Z*reducedsol[size(Z,2)+1:end]
  for row = 2:numnodes
    offset = convert(Int, (row-1)*(row-2)/2)
    for col = 1:row-1
      Qx[row,col] += Qxnull[offset+col]
      Qx[col,row] -= Qxnull[offset+col]
      Qy[row,col] += Qynull[offset+col]
      Qy[col,row] -= Qynull[offset+col]
    end
  end
  # compute f = Frobenius_norm(H*(Dx*Dy - Dy*Dx)), and its derivatives
  f = zero(T2)
  dfdQx = zeros(Qx)
  dfdQy = zeros(Qy)
  for row = 1:numnodes
    for col = 1:numnodes
      Aij = zero(T2)
      for k = 1:numnodes
        Aij += (Qx[row,k]*Qy[k,col] - Qy[row,k]*Qx[k,col])/w[k]
      end
      f += 0.5*Aij*Aij
      for k = 1:numnodes
        dfdQx[row,k] += Aij*Qy[k,col]/w[k]
        dfdQx[k,col] -= Aij*Qy[row,k]/w[k]
        dfdQy[k,col] += Aij*Qx[row,k]/w[k]
        dfdQy[row,k] -= Aij*Qx[k,col]/w[k]
      end
    end
  end
  dfdQxnull = zeros(Qxnull)
  dfdQynull = zeros(Qynull)
  for row = 2:numnodes
    offset = convert(Int, (row-1)*(row-2)/2)
    for col = 1:row-1
      dfdQxnull[offset+col] += dfdQx[row,col] - dfdQx[col,row]
      dfdQynull[offset+col] += dfdQy[row,col] - dfdQy[col,row]
    end
  end
  dfdreducedsol = [Z.'*dfdQxnull; Z.'*dfdQynull]
  return f, dfdreducedsol
end

@doc """
### SummationByParts.buildoperators

Construct and return the SBP matrix operators, specifically the diagonal norm
matrix and the stiffness matrices.

**Inputs**

* `cub`: symmetric cubature rule
* `vtx`: vertices of the right simplex
* `d`: maximum total degree for the Proriol polynomials

**Outputs**

* `w`: the diagonal norm stored as a 1D array
* `Qx`,`Qy` (`Qz`): the stiffness matrices

"""->
function buildoperators{T}(cub::TriSymCub{T}, vtx::Array{T,2}, d::Int)
  w = SymCubatures.calcweights(cub)
  Qx, Qy = SummationByParts.boundaryoperators(cub, vtx, d)
  A, bx, by = SummationByParts.accuracyconstraints(cub, vtx, d)
  # use the minimum norm least-squares solution
  Afact = qrfact(A)
  x = Afact\bx; y = Afact\by
  Qx *= 0.5; Qy *= 0.5
  for row = 2:cub.numnodes
    offset = convert(Int, (row-1)*(row-2)/2)
    for col = 1:row-1
      Qx[row,col] += x[offset+col]
      Qx[col,row] -= x[offset+col]
      Qy[row,col] += y[offset+col]
      Qy[col,row] -= y[offset+col]
    end
  end
  return w, Qx, Qy
end

function buildoperators{T}(cub::TetSymCub{T}, vtx::Array{T,2}, d::Int)
  w = SymCubatures.calcweights(cub)
  Qx, Qy, Qz = SummationByParts.boundaryoperators(cub, vtx, d)
  A, bx, by, bz = SummationByParts.accuracyconstraints(cub, vtx, d)
  # use the minimum norm least-squares solution
  Afact = qrfact(A)
  x = Afact\bx; y = Afact\by; z = Afact\bz
  Qx *= 0.5; Qy *= 0.5; Qz *= 0.5
  for row = 2:cub.numnodes
    offset = convert(Int, (row-1)*(row-2)/2)
    for col = 1:row-1
      Qx[row,col] += x[offset+col]
      Qx[col,row] -= x[offset+col]
      Qy[row,col] += y[offset+col]
      Qy[col,row] -= y[offset+col]
      Qz[row,col] += z[offset+col]
      Qz[col,row] -= z[offset+col]
    end
  end
  return w, Qx, Qy, Qz
end