facts("Testing SummationByParts Module (buildoperators.jl file)...") do

  context("Testing SummationByParts.bndrynodalexpansion (TriSymCub method)") do
    # check that P*E produces the identity matrix on the boundary
    for d = 1:4
      cub, vtx = tricubature(2*d-1, Float64)
      E = SummationByParts.bndrynodalexpansion(cub, vtx, d)
      x, y = SymCubatures.calcnodes(cub, vtx)
      N = convert(Int, (d+1)*(d+2)/2 )
      P = zeros(cub.numnodes, N)
      ptr = 1
      for r = 0:d
        for j = 0:r
          i = r-j
          P[:,ptr] = OrthoPoly.proriolpoly(x, y, i, j)
          ptr += 1
        end
      end
      A = P*E
      numbndry = SymCubatures.getnumboundarynodes(cub)
      @fact A[1:numbndry,1:numbndry] --> roughly(eye(numbndry), atol=1e-15)
    end
  end

  context("Testing SummationByParts.bndrynodalexpansion (TetSymCub method)") do
    # check that P*E produces the identity matrix on the boundary
    for d = 1:4
      cub, vtx = tetcubature(2*d-1, Float64)
      E = SummationByParts.bndrynodalexpansion(cub, vtx, d)
      x, y, z = SymCubatures.calcnodes(cub, vtx)
      N = convert(Int, (d+1)*(d+2)*(d+3)/6 )
      P = zeros(cub.numnodes, N)
      ptr = 1
      for r = 0:d
        for k = 0:r
          for j = 0:r-k
            i = r-j-k
            P[:,ptr] = OrthoPoly.proriolpoly(x, y, z, i, j, k)
          ptr += 1
          end
        end
      end
      A = P*E
      numbndry = SymCubatures.getnumboundarynodes(cub)
      @fact A[1:numbndry,1:numbndry] --> roughly(eye(numbndry), atol=1e-14)
    end
  end

  context("Testing SummationByParts.nodalexpansion (TriSymCub method)") do
    # check that P*E produces the identity matrix at the nodes
    e = [1;3;4;5]
    for d = 1:4
      cub, vtx = tricubature(2*d-1, Float64)
      C = SummationByParts.nodalexpansion(cub, vtx, d, e[d])
      x, y = SymCubatures.calcnodes(cub, vtx)
      N = convert(Int, (e[d]+1)*(e[d]+2)/2 )
      P = zeros(cub.numnodes, N)
      ptr = 1
      for r = 0:e[d]
        for j = 0:r
          i = r-j
          P[:,ptr] = OrthoPoly.proriolpoly(x, y, i, j)
          ptr += 1
        end
      end
      @fact P*C --> roughly(eye(cub.numnodes), atol=1e-14)
    end
  end

  context("Testing SummationByParts.boundaryoperators (TriSymCub method)") do
    # check Ex, Ey by comparing with appropriate integral of divergence
    for d = 1:4
      cub, vtx = tricubature(2*d-1, Float64)
      w = SymCubatures.calcweights(cub)
      Ex, Ey = SummationByParts.boundaryoperators(cub, vtx, d)
      H = diagm(w)
      x, y = SymCubatures.calcnodes(cub, vtx)      
      for r = 0:2*d-1
        for j = 0:r
          i = r-j
          if i > d
            u = x.^d
            dudx = d.*x.^(d-1)
            dudy = zeros(x)
            v = (x.^(i-d)).*(y.^j)
            dvdx = (i-d).*(x.^(i-d-1)).*(y.^j)
            dvdy = (x.^(i-d)).*(j.*y.^max(0,j-1))
          elseif j > d
            u = y.^d
            dudx = zeros(y)
            dudy = d.*y.^(d-1)
            v = (x.^i).*(y.^(j-d))
            dvdx = (i.*x.^max(0,i-1)).*(y.^(j-d))
            dvdy = (x.^i).*((j-d).*y.^(j-d-1))
          else # i <= d, j <= d
            u = x.^i
            dudx = i.*x.^max(0,i-1)
            dudy = zeros(x)
            v = y.^j
            dvdx = zeros(y)
            dvdy = j.*y.^max(0,j-1)
          end
          @fact u.'*Ex*v --> roughly(dudx.'*H*v + u.'*H*dvdx, atol=1e-14)
          @fact u.'*Ey*v --> roughly(dudy.'*H*v + u.'*H*dvdy, atol=1e-14)
        end
      end
    end   
  end

  context("Testing SummationByParts.boundaryoperators (TetSymCub method)") do
    # check Ex, Ey, Ez by comparing with appropriate integral of divergence
    for d = 1:4
      cub, vtx = tetcubature(2*d-1, Float64)
      w = SymCubatures.calcweights(cub)
      Ex, Ey, Ez = SummationByParts.boundaryoperators(cub, vtx, d)
      H = diagm(w)
      x, y, z = SymCubatures.calcnodes(cub, vtx)      
      for r = 0:2*d-1
        for k = 0:r
          for j = 0:r-k
            i = r-j-k
            if i > d
              u = x.^d
              dudx = d.*x.^(d-1)
              dudy = zeros(x)
              dudz = zeros(x)
              v = (x.^(i-d)).*(y.^j).*(z.^k)
              dvdx = (i-d).*(x.^(i-d-1)).*(y.^j).*(z.^k)
              dvdy = (x.^(i-d)).*(j.*y.^max(0,j-1)).*(z.^k)
              dvdz = (x.^(i-d)).*(y.^j).*(k.*z.^max(0,k-1))
            elseif j > d
              u = y.^d
              dudx = zeros(y)
              dudy = d.*y.^(d-1)
              dudz = zeros(y)
              v = (x.^i).*(y.^(j-d)).*(z.^k)
              dvdx = (i.*x.^max(0,i-1)).*(y.^(j-d)).*(z.^k)
              dvdy = (x.^i).*((j-d).*y.^(j-d-1)).*(z.^k)
              dvdz = (x.^i).*(y.^(j-d)).*(k.*z.^max(0,k-1))
            elseif k > d
              u = z.^d
              dudx = zeros(z)
              dudy = zeros(z)
              dudz = d.*z.^(d-1)
              v = (x.^i).*(y.^j).*(z.^(k-d))
              dvdx = (i.*x.^max(0,i-1)).*(y.^j).*(z.^(k-d))
              dvdy = (x.^i).*(j.*y.^max(0,j-1)).*(z.^(k-d))
              dvdz = (x.^i).*(y.^j).*((k-d).*z.^(k-d-1))
            elseif i+j > d
              ku, kv = (i > j ? [0,k] : [k,0])
              u = (x.^i).*(z.^ku)
              dudx = (i.*x.^max(0,i-1)).*(z.^ku)
              dudy = zeros(x)
              dudz = (x.^i).*(ku.*z.^max(0,ku-1))
              v = (y.^j).*(z.^kv)
              dvdx = zeros(y)
              dvdy = (j.*y.^max(0,j-1)).*(z.^kv)
              dvdz = (y.^j).*(kv.*z.^max(0,kv-1))
            elseif i+k > d
              ju, jv = (i > k ? [0,j] : [j,0])
              u = (x.^i).*(y.^ju)
              dudx = (i.*x.^max(0,i-1)).*(y.^ju)
              dudy = (x.^i).*(ju.*y.^max(0,ju-1))              
              dudz = zeros(x)
              v = (z.^k).*(y.^jv)
              dvdx = zeros(z)
              dvdy = (z.^k).*(jv.*y.^max(0,jv-1))
              dvdz = (k.*z.^max(0,k-1)).*(y.^jv)
            else
              iu, iv = (j > k ? [0,i] : [i,0])
              u = (x.^iu).*(y.^j)
              dudx = (iu.*x.^max(0,iu-1)).*(y.^j)
              dudy = (x.^iu).*(j.*y.^max(0,j-1))
              dudz = zeros(x)              
              v = (x.^iv).*(z.^k)
              dvdx = (iv.*x.^max(0,iv-1)).*(z.^k)
              dvdy = zeros(x)
              dvdz = (x.^iv).*(k.*z.^max(0,k-1))
            end
            @fact u.'*Ex*v --> roughly(dudx.'*H*v + u.'*H*dvdx, atol=1e-14)
            @fact u.'*Ey*v --> roughly(dudy.'*H*v + u.'*H*dvdy, atol=1e-14)
            @fact u.'*Ez*v --> roughly(dudz.'*H*v + u.'*H*dvdz, atol=1e-14)
          end
        end
      end   
    end
  end

  context("Testing SummationByParts.boundarymassmatrix (TriSymCub method)") do
    # check that mass matrix can be assembled into Ex and Ey
    for d = 1:4
      cub, vtx = tricubature(2*d-1, Float64)
      Ex, Ey = SummationByParts.boundaryoperators(cub, vtx, d)
      Hbndry, bndindx = SummationByParts.boundarymassmatrix(cub, vtx, d)
      Ex_inject = zeros(Ex)
      Ey_inject = zeros(Ey)
      Ex_inject[bndindx[:,2],bndindx[:,2]] = Hbndry
      Ex_inject[bndindx[:,3],bndindx[:,3]] -= Hbndry
      Ey_inject[bndindx[:,1],bndindx[:,1]] -= Hbndry
      Ey_inject[bndindx[:,2],bndindx[:,2]] += Hbndry
      @fact Ex_inject --> roughly(Ex, atol=1e-15)
      @fact Ey_inject --> roughly(Ey, atol=1e-15)
    end
  end

  context("Testing SummationByParts.boundarymassmatrix (TetSymCub method)") do
    # check that mass matrix can be assembled into Ex and Ey
    for d = 1:4
      cub, vtx = tetcubature(2*d-1, Float64)
      Ex, Ey, Ez = SummationByParts.boundaryoperators(cub, vtx, d)
      Hbndry, bndindx = SummationByParts.boundarymassmatrix(cub, vtx, d)
      Ex_inject = zeros(Ex)
      Ey_inject = zeros(Ey)
      Ez_inject = zeros(Ez)
      Ex_inject[bndindx[:,2],bndindx[:,2]] += Hbndry
      Ex_inject[bndindx[:,3],bndindx[:,3]] -= Hbndry
      Ey_inject[bndindx[:,2],bndindx[:,2]] += Hbndry
      Ey_inject[bndindx[:,4],bndindx[:,4]] -= Hbndry
      Ez_inject[bndindx[:,2],bndindx[:,2]] += Hbndry
      Ez_inject[bndindx[:,1],bndindx[:,1]] -= Hbndry
      @fact Ex_inject --> roughly(Ex, atol=1e-15)
      @fact Ey_inject --> roughly(Ey, atol=1e-15)
      @fact Ez_inject --> roughly(Ez, atol=1e-15)
    end
  end

  context("Testing SummationByParts.accuracyconstraints (TriSymCub method)") do
    # check that the null-space of the constraint Jacobian is the correct size
    # this is not an adequate unit test.
    sizenull = [0, 0, 1, 3]
    for d = 1:4
      cub, vtx = tricubature(2*d-1, Float64)
      A, bx, by = SummationByParts.accuracyconstraints(cub, vtx, d)
      @fact size(nullspace(A),2) --> sizenull[d]
    end
  end
  
  context("Testing SummationByParts.accuracyconstraints (TetSymCub method)") do
    # check that the null-space of the constraint Jacobian is the correct size
    # this is not an adequate unit test.
    sizenull = [0, 0, 6, 45]
    for d = 1:4
      cub, vtx = tetcubature(2*d-1, Float64)
      A, bx, by, bz = SummationByParts.accuracyconstraints(cub, vtx, d)
      @fact size(nullspace(A),2) --> sizenull[d]
    end
  end
  
  context("Testing SummationByParts.commuteerror (TriSymCub method)") do
    reducedsol = (Float64[], Float64[], Float64[0, 0])
    error = [0, 0, 0.5*2.324812265031167] # error based on particular Q
    for d = 1:3
      cub, vtx = tricubature(2*d-1, Float64)
      w = SymCubatures.calcweights(cub)
      Qx, Qy = SummationByParts.boundaryoperators(cub, vtx, d)    
      A, bx, by = SummationByParts.accuracyconstraints(cub, vtx, d)
      # build Q that satisfies the accuracy constraints
      x = A\bx; y = A\by
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
      Z = nullspace(A)
      f, dfdx = SummationByParts.commuteerror(w, Qx, Qy, Z, reducedsol[d])
      @fact f --> roughly(error[d], atol=1e-15)
    end
  end
  
  context("Testing SummationByParts.buildoperators (TriSymCub method)") do
    for d = 1:4
      cub, vtx = tricubature(2*d-1, Float64)
      w, Qx, Qy = SummationByParts.buildoperators(cub, vtx, d)
      Dx = diagm(1./w)*Qx
      Dy = diagm(1./w)*Qy
      x, y = SymCubatures.calcnodes(cub, vtx)  
      for r = 0:d
        for j = 0:r
          i = r-j
          u = (x.^i).*(y.^j)
          dudx = (i.*x.^max(0,i-1)).*(y.^j)
          dudy = (x.^i).*(j.*y.^max(0,j-1))
          @fact Dx*u --> roughly(dudx, atol=1e-13)
          @fact Dy*u --> roughly(dudy, atol=1e-13)
        end
      end
    end
  end

  context("Testing SummationByParts.buildoperators (TetSymCub method)") do
    for d = 1:4
      cub, vtx = tetcubature(2*d-1, Float64)
      w, Qx, Qy, Qz = SummationByParts.buildoperators(cub, vtx, d)
      Dx = diagm(1./w)*Qx
      Dy = diagm(1./w)*Qy
      Dz = diagm(1./w)*Qz
      x, y, z = SymCubatures.calcnodes(cub, vtx)      
      for r = 0:d
        for k = 0:r
          for j = 0:r-k
            i = r-j-k
            u = (x.^i).*(y.^j).*(z.^k)
            dudx = (i.*x.^max(0,i-1)).*(y.^j).*(z.^k)
            dudy = (x.^i).*(j.*y.^max(0,j-1)).*(z.^k)
            dudz = (x.^i).*(y.^j).*(k.*z.^max(0,k-1))
            @fact Dx*u --> roughly(dudx, atol=1e-12)
            @fact Dy*u --> roughly(dudy, atol=1e-12)
            @fact Dz*u --> roughly(dudz, atol=1e-12)
          end
        end
      end
    end
  end

  context("Testing SummationByParts.buildoperators (spectral-element method)") do
    e = [1;3;4;5]
    for d = 1:4
      cub, vtx = tricubature(2*d-1, Float64)
      w, Qx, Qy = SummationByParts.buildoperators(cub, vtx, d, e[d])
      Dx = diagm(1./w)*Qx
      Dy = diagm(1./w)*Qy
      x, y = SymCubatures.calcnodes(cub, vtx)
      for r = 0:d
        for j = 0:r
          i = r-j
          u = (x.^i).*(y.^j)
          dudx = (i.*x.^max(0,i-1)).*(y.^j)
          dudy = (x.^i).*(j.*y.^max(0,j-1))
          @fact Dx*u --> roughly(dudx, atol=1e-13)
          @fact Dy*u --> roughly(dudy, atol=1e-13)
        end
      end
    end
  end

  context("Testing SummationByParts.getnodepermutation (TriSymCub method)") do
    # check that vertices are first and edge nodes are ordered correctly
    for d = 1:4
      cub, vtx = tricubature(2*d-1, Float64)
      perm, faceperm = SummationByParts.getnodepermutation(cub, d)
      x, y = SymCubatures.calcnodes(cub, vtx)
      x = x[perm]
      y = y[perm]
      # check vertices
      @fact x[1:3] --> roughly(vtx[:,1], atol=1e-15)
      @fact y[1:3] --> roughly(vtx[:,2], atol=1e-15)
      ptr = 3
      # check ordering of x nodes on first edge
      @fact issorted(x[ptr+1:ptr+d-1]) --> true
      @fact y[ptr+1:ptr+d-1] --> roughly(-ones(d-1), atol=1e-15)
      ptr += (d-1)
      # check ordering of x and y nodes on second edge
      @fact issorted(x[ptr+1:ptr+d-1], rev=true) --> true
      @fact issorted(y[ptr+1:ptr+d-1]) --> true
      ptr += (d-1)
      # check ordering of y nodes on third edge
      @fact x[ptr+1:ptr+d-1] --> roughly(-ones(d-1), atol=1e-15)
      @fact issorted(y[ptr+1:ptr+d-1], rev=true) --> true
    end
  end

  context("Testing SummationByParts.getnodepermutation (TetSymCub method)") do
    # check that vertices are first, edge nodes are ordered correctly, and face
    # nodes lie on the expected faces
    for d = 1:4
      cub, vtx = tetcubature(2*d-1, Float64)
      perm, faceperm = SummationByParts.getnodepermutation(cub, d)
      x, y, z = SymCubatures.calcnodes(cub, vtx)
      x = x[perm]
      y = y[perm]
      z = z[perm]
      # check vertices
      @fact x[1:4] --> roughly(vtx[:,1], atol=1e-15)
      @fact y[1:4] --> roughly(vtx[:,2], atol=1e-15)
      @fact z[1:4] --> roughly(vtx[:,3], atol=1e-15)
      ptr = 4
      # check ordering of x nodes on first edge
      @fact issorted(x[ptr+1:ptr+d-1]) --> true
      @fact y[ptr+1:ptr+d-1] --> roughly(-ones(d-1), atol=1e-15)
      @fact z[ptr+1:ptr+d-1] --> roughly(-ones(d-1), atol=1e-15)
      ptr += (d-1)
      # check ordering of x and y nodes on second edge
      @fact issorted(x[ptr+1:ptr+d-1], rev=true) --> true
      @fact issorted(y[ptr+1:ptr+d-1]) --> true
      @fact z[ptr+1:ptr+d-1] --> roughly(-ones(d-1), atol=1e-15)
      ptr += (d-1)
      # check ordering of y and z nodes on third edge
      @fact x[ptr+1:ptr+d-1] --> roughly(-ones(d-1), atol=1e-15)
      @fact issorted(y[ptr+1:ptr+d-1], rev=true) --> true
      @fact issorted(z[ptr+1:ptr+d-1]) --> true
      ptr += (d-1)
      # check ordering of z on fourth edge
      @fact x[ptr+1:ptr+d-1] --> roughly(-ones(d-1), atol=1e-15)
      @fact y[ptr+1:ptr+d-1] --> roughly(-ones(d-1), atol=1e-15)
      @fact issorted(z[ptr+1:ptr+d-1]) --> true
      ptr += (d-1)
      # check ordering of y on fifth edge
      @fact x[ptr+1:ptr+d-1] --> roughly(-ones(d-1), atol=1e-15)
      @fact issorted(y[ptr+1:ptr+d-1]) --> true
      @fact z[ptr+1:ptr+d-1] --> roughly(-ones(d-1), atol=1e-15)
      ptr += (d-1)
      # check ordering of x and z on sixth edge
      @fact issorted(x[ptr+1:ptr+d-1], rev=true) --> true
      @fact y[ptr+1:ptr+d-1] --> roughly(-ones(d-1), atol=1e-15)
      @fact issorted(z[ptr+1:ptr+d-1]) --> true
      ptr += (d-1)
      # check that face nodes lie on appropriate faces
      numface = div((d-1)*(d-2),2)
      # check that z = -1 on face 1
      @fact z[ptr+1:ptr+numface] --> roughly(-ones(numface), atol=1e-15)
      ptr += numface
      # check that z = -1 - x - y on face 2
      @fact z[ptr+1:ptr+numface] --> roughly(-ones(numface)
                                            -x[ptr+1:ptr+numface]
                                            -y[ptr+1:ptr+numface], atol=1e-15)
      ptr += numface
      # check that x = -1 on face 3
      @fact x[ptr+1:ptr+numface] --> roughly(-ones(numface), atol=1e-15)
      ptr += numface
      # check that y = -1 on face 4
      @fact y[ptr+1:ptr+numface] --> roughly(-ones(numface), atol=1e-15)
      ptr += numface
    end
  end

end