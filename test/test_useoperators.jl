facts("Testing SummationByParts Module (useoperators.jl file)...") do

  context("Testing SummationByParts.applyQ! (TriSBP, scalar field method)") do
    # build a two element grid, and verify that Qxi * 1 = 0
    for p = 1:4
      sbp = TriSBP{Float64}(degree=p)
      u = ones(Float64, (sbp.numnodes,2))
      di = 1
      res = zeros(u)
      applyQ!(sbp, di, u, res)
      @fact res[:,1] => roughly(zeros(sbp.numnodes), atol=1e-13)
      @fact res[:,2] => roughly(zeros(sbp.numnodes), atol=1e-13)
    end
  end 

  context("Testing SummationByParts.applyQ! (TetSBP, scalar field method)") do
    # build a single element grid, and verify that Qxi * 1 = 0
    for p = 1:4
      sbp = TetSBP{Float64}(degree=p)
      u = ones(Float64, (sbp.numnodes,1))
      di = 1
      res = zeros(u)
      applyQ!(sbp, di, u, res)
      @fact res[:,1] => roughly(zeros(sbp.numnodes), atol=1e-13)
    end
  end 

  context("Testing SummationByParts.applyQ! (TriSBP, vector field method)") do
    # build a two element grid, and verify that \int (Dxi * x) d\Omega = 1 or 0,
    # depending on orientation of local coordinates
    for p = 1:4
      sbp = TriSBP{Float64}(degree=p)
      vtx = [0. 0.; 1. 0.; 0. 1.]
      x = zeros(Float64, (2,sbp.numnodes,2))
      x[:,:,1] = calcnodes(sbp, vtx)
      vtx = [1. 0.; 1. 1.; 0. 1.]
      x[:,:,2] = calcnodes(sbp, vtx)
      di = 1
      res = zeros(x)
      applyQ!(sbp, di, x, res)
      @fact sum(res[1,:,1]) => roughly(1.0, atol=1e-15)
      @fact sum(res[2,:,1]) => roughly(0.0, atol=1e-15)
      @fact sum(res[1,:,2]) => roughly(0.0, atol=1e-15)
      @fact sum(res[2,:,2]) => roughly(1.0, atol=1e-15)
    end
  end

  context("Testing SummationByParts.applyQ! (TetSBP, vector field method)") do
    # build a single element grid, and verify that \int (Dxi * x) d\Omega = 2/3
    # or 0, depending on orientation of local coordinates
    for p = 1:4
      sbp = TetSBP{Float64}(degree=p)
      vtx = [0. 0. 0.; 1. 0. 0.; 0. 1. 0.; 0. 0. 1.]
      x = zeros(Float64, (3,sbp.numnodes,1))
      x[:,:,1] = calcnodes(sbp, vtx)
      di = 1
      res = zeros(x)
      applyQ!(sbp, di, x, res)
      @fact sum(res[1,:,1]) => roughly(2/3, atol=1e-15)
      @fact sum(res[2,:,1]) => roughly(0.0, atol=1e-15)
      @fact sum(res[3,:,1]) => roughly(0.0, atol=1e-15)
    end
  end

  context("Testing SummationByParts.applyD! (TriSBP, scalar field method)") do
    # build a two element grid, and verify that Dxi * 1 = 0
    for p = 1:4
      sbp = TriSBP{Float64}(degree=p)
      u = ones(Float64, (sbp.numnodes,2))
      di = 1
      res = zeros(u)
      applyD!(sbp, di, u, res)
      @fact res[:,1] => roughly(zeros(sbp.numnodes), atol=1e-13)
      @fact res[:,2] => roughly(zeros(sbp.numnodes), atol=1e-13)
    end
  end 

  context("Testing SummationByParts.applyD! (TetSBP, scalar field method)") do
    # build a single element grid, and verify that Dxi * 1 = 0
    for p = 1:4
      sbp = TetSBP{Float64}(degree=p)
      u = ones(Float64, (sbp.numnodes,1))
      di = 1
      res = zeros(u)
      applyD!(sbp, di, u, res)
      @fact res[:,1] => roughly(zeros(sbp.numnodes), atol=5e-13)
    end
  end 

  context("Testing SummationByParts.applyD! (TriSBP, vector field method)") do
    # build a two element grid, and verify that Dxi*x = 0.5 or 0, depending on
    # orientation of local coordinates
    for p = 1:4
      sbp = TriSBP{Float64}(degree=p)
      vtx = [0. 0.; 1. 0.; 0. 1.]
      x = zeros(Float64, (2,sbp.numnodes,2))
      x[:,:,1] = calcnodes(sbp, vtx)
      vtx = [1. 0.; 1. 1.; 0. 1.]
      x[:,:,2] = calcnodes(sbp, vtx)
      di = 1
      res = zeros(x)
      applyD!(sbp, di, x, res)
      @fact res[1,:,1] => roughly(0.5.*ones(1,sbp.numnodes), atol=1e-13)
      @fact res[2,:,1] => roughly(zeros(1,sbp.numnodes), atol=1e-13)
      @fact res[1,:,2] => roughly(zeros(1,sbp.numnodes), atol=1e-13)
      @fact res[2,:,2] => roughly(0.5.*ones(1,sbp.numnodes), atol=1e-13)
    end
  end

  context("Testing SummationByParts.applyD! (TetSBP, vector field method)") do
    # build a single element grid, and verify that Dxi * x = 0.5 or 0, depending
    # on orientation of local coordinates
    for p = 1:4
      sbp = TetSBP{Float64}(degree=p)
      vtx = [0. 0. 0.; 1. 0. 0.; 0. 1. 0.; 0. 0. 1.]
      x = zeros(Float64, (3,sbp.numnodes,1))
      x[:,:,1] = calcnodes(sbp, vtx)
      di = 1
      res = zeros(x)
      applyD!(sbp, di, x, res)
      @fact res[1,:,1] => roughly(0.5.*ones(1,sbp.numnodes), atol=1e-13)
      @fact res[2,:,1] => roughly(zeros(1,sbp.numnodes), atol=1e-13)
      @fact res[3,:,1] => roughly(zeros(1,sbp.numnodes), atol=1e-13)
    end
  end

  context("Testing SummationByParts.applyH! (TriSBP, scalar field method)") do
    # build a two element grid, and verify that ones*H*ones = vol
    for p = 1:4
      sbp = TriSBP{Float64}(degree=p)
      u = ones(Float64, (sbp.numnodes,2))
      res = zeros(u)
      applyH!(sbp, u, res)
      @fact sum(res[:,1]) => roughly(2.0, atol=1e-14)
      @fact sum(res[:,2]) => roughly(2.0, atol=1e-14)
    end
  end

  context("Testing SummationByParts.applyH! (TetSBP, scalar field method)") do
    # build a single element grid, and verify that ones*H*ones = vol
    for p = 1:4
      sbp = TetSBP{Float64}(degree=p)
      u = ones(Float64, (sbp.numnodes,1))
      res = zeros(u)
      applyH!(sbp, u, res)
      @fact sum(res[:,1]) => roughly(4/3, atol=1e-14)
    end
  end
  
  context("Testing SummationByParts.applyH! (TriSBP, vector field method)") do
    # build a two element grid, and verify that ones^T*H*ones = (1,2)
    for p = 1:4
      sbp = TriSBP{Float64}(degree=p)
      u = ones(Float64, (2,sbp.numnodes,2))
      u[1,:,:] *= 0.5
      res = zeros(u)
      applyH!(sbp, u, res)
      @fact sum(res[1,:,1]) => roughly(1.0, atol=1e-14)
      @fact sum(res[2,:,1]) => roughly(2.0, atol=1e-14)
      @fact sum(res[1,:,2]) => roughly(1.0, atol=1e-14)
      @fact sum(res[2,:,2]) => roughly(2.0, atol=1e-14)
    end
  end

  context("Testing SummationByParts.applyH! (TetSBP, vector field method)") do
    # build a single element grid, and verify that ones*H*ones = (1,2)
    for p = 1:4
      sbp = TetSBP{Float64}(degree=p)
      u = ones(Float64, (2,sbp.numnodes,1))
      u[1,:,:] *= 3/4
      u[2,:,:] *= 3/2
      res = zeros(u)
      applyH!(sbp, u, res)
      @fact sum(res[1,:,1]) => roughly(1.0, atol=1e-14)
      @fact sum(res[2,:,1]) => roughly(2.0, atol=1e-14)
    end
  end

  context("Testing SummationByParts.mappingjacobian! (TriSBP method)") do
    # build a two element grid, and verify components of the Jacobian and its
    # determinant
    for p = 1:4
      sbp = TriSBP{Float64}(degree=p)
      vtx = [0. 0.; 1. 0.; 0. 1.]
      x = zeros(Float64, (2,sbp.numnodes,2))
      x[:,:,1] = calcnodes(sbp, vtx)
      vtx = [1. 0.; 1. 1.; 0. 1.]
      x[:,:,2] = calcnodes(sbp, vtx)
      dxidx = zeros(Float64, (2,2,sbp.numnodes,2))
      jac = zeros(Float64, (sbp.numnodes,2))
      mappingjacobian!(sbp, x, dxidx, jac)
      # verify on element 1
      @fact dxidx[1,1,:,1] => roughly(0.5*ones(1,1,sbp.numnodes), atol=1e-13)
      @fact dxidx[1,2,:,1] => roughly(zeros(1,1,sbp.numnodes), atol=1e-13)
      @fact dxidx[2,2,:,1] => roughly(0.5*ones(1,1,sbp.numnodes), atol=1e-13)
      @fact dxidx[2,1,:,1] => roughly(zeros(1,1,sbp.numnodes), atol=1e-13)
      @fact jac[:,1] => roughly(0.25*ones(sbp.numnodes), atol=1e-13)
      # verify on element 2
      @fact dxidx[1,1,:,2] => roughly(0.5*ones(1,1,sbp.numnodes), atol=1e-13)
      @fact dxidx[1,2,:,2] => roughly(0.5*ones(1,1,sbp.numnodes), atol=1e-13)
      @fact dxidx[2,2,:,2] => roughly(zeros(1,1,sbp.numnodes), atol=1e-13)
      @fact dxidx[2,1,:,2] => roughly(-0.5*ones(1,1,sbp.numnodes), atol=1e-13)
      @fact jac[:,2] => roughly(0.25*ones(sbp.numnodes), atol=1e-13)
    end
  end

  context("Testing SummationByParts.mappingjacobian! (TetSBP method)") do
    # build one element grid, and verify components of the Jacobian and its
    # determinant
    for p = 1:4
      sbp = TetSBP{Float64}(degree=p)
      vtx = [0. 0. 0.; 2. 0. 0.; 0. 2. 0.; 0. 0. 2.]
      x = zeros(Float64, (3,sbp.numnodes,1))
      x[:,:,1] = calcnodes(sbp, vtx)
      dxidx = zeros(Float64, (3,3,sbp.numnodes,1))
      jac = zeros(Float64, (sbp.numnodes,1))
      mappingjacobian!(sbp, x, dxidx, jac)
      # dxi/dx = (1,0,0)
      @fact dxidx[1,1,:,1] => roughly(ones(1,1,sbp.numnodes), atol=1e-12)
      @fact dxidx[1,2,:,1] => roughly(zeros(1,1,sbp.numnodes), atol=1e-12)
      @fact dxidx[1,3,:,1] => roughly(zeros(1,1,sbp.numnodes), atol=1e-12)
      # deta/dx = (0,1,0)
      @fact dxidx[2,1,:,1] => roughly(zeros(1,1,sbp.numnodes), atol=1e-12)
      @fact dxidx[2,2,:,1] => roughly(ones(1,1,sbp.numnodes), atol=1e-12)
      @fact dxidx[2,3,:,1] => roughly(zeros(1,1,sbp.numnodes), atol=1e-12)
      # dzeta/dx = (0,1,0)
      @fact dxidx[3,1,:,1] => roughly(zeros(1,1,sbp.numnodes), atol=1e-12)
      @fact dxidx[3,2,:,1] => roughly(zeros(1,1,sbp.numnodes), atol=1e-12)
      @fact dxidx[3,3,:,1] => roughly(ones(1,1,sbp.numnodes), atol=1e-12)
      # jac = 1
      @fact jac[:,1] => roughly(ones(sbp.numnodes), atol=1e-12)
    end
  end
end