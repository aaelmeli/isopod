#laser is focused on aluminum layer and generates heat.
#heat causes metal to be expanded, thus generate some stress.
#since the heat absorption is imeediat, the stress generated is also very fast,
#thus, generating some mechanical waves, surface, longitudinal, and shear waves
#that propagates in the metal. we observe and measure the wavefield far from
#the excitation, i.e. (far field data).
#the way we model this is only to model wave propagation (single physics problem),
#and approximate the push (pressure/forcing function) using some existing published work.
#this force/pressure is either dipole stresses or some concentrated push
#there has been some (simplified) analytical solution for this.
#but the most accurate way, is to consider to model the thermo-elastic behavior,
#by coupling the elastic wave equation to the heat-condution-diffudion quation,
c_l=6200 #longitudinal/compression wave speed
c_s=3100 #shear wave speed
[Mesh]
  type = GeneratedMesh
   dim = 3
   xmin=-0.015
   xmax=0.015
   ymin=-0.015
   ymax=0.015
   zmin=-0.005
   zmax=0
   nx = 150
   ny=150
   nz=50
[]

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]
# [Problem]
#   coord_type = RZ
# []

[Modules/TensorMechanics/DynamicMaster]
  [all]
    add_variables = true
    newmark_beta = 0.25
    newmark_gamma = 0.5
    mass_damping_coefficient = 0.0
    stiffness_damping_coefficient = 0.0
    density = 2600
  []
[]
[DiracKernels]
  [point_source1]
   type = FunctionDiracSource
   variable = disp_x
   function = 'step_func1'
   point = '2e-4 2e-4 0.0'
  []
  [point_source2]
   type = FunctionDiracSource
   variable = disp_y
   function = 'step_func1'
   point = '2e-4 2e-4 0.0'
  []
  [point_source3]
   type = FunctionDiracSource
   variable = disp_x
   function = 'step_func2'
   point = '-2e-4 2e-4 0.0'
  []
  [point_source4]
   type = FunctionDiracSource
   variable = disp_y
   function = 'step_func1'
   point = '-2e-4 2e-4 0.0'
  []
  [point_source5]
   type = FunctionDiracSource
   variable = disp_x
   function = 'step_func2'
   point = '-2e-4 -2e-4 0.0'
  []
  [point_source6]
   type = FunctionDiracSource
   variable = disp_y
   function = 'step_func2'
   point = '-2e-4 -2e-4 0.0'
  []
  [point_source7]
   type = FunctionDiracSource
   variable = disp_x
   function = 'step_func1'
   point = '2e-4 -2e-4 0.0'
  []
  [point_source8]
   type = FunctionDiracSource
   variable = disp_y
   function = 'step_func2'
   point = '2e-4 -2e-4 0.0'
  []
[]

[Functions]
 [step_func1]
    type = ParsedFunction
    value = 'if(t <= .25e-6, sin(2*pi*t*2e6), 0)'
    # value = 'if(t < 0.125001e-6, -1, 0)'
  []
 [step_func2]
    type = ParsedFunction
    value = 'if(t <= .25e-6, -sin(2*pi*t*2e6), 0)'
    # value = 'if(t < 0.125001e-6, 1, 0)'
  []
[]

#  [BCs]
#     # [right_x]
#     #     type = CoupledVarNeumannBC
#     #     variable = disp_x
#     #     boundary = 'right'
#     #     v = vel_x
#     #     coef= ${fparse -2600*c_l}
#     # []
#     # [right_y]
#     #     type = CoupledVarNeumannBC
#     #     variable = disp_y
#     #     boundary = 'right'
#     #     v = vel_y
#     #     coef= ${fparse -2600*c_s}
#     # []
#     # [bottom_x]
#     #     type = CoupledVarNeumannBC
#     #     variable = disp_x
#     #     boundary = 'bottom'
#     #     v = vel_x
#     #     coef= ${fparse -c_s}
#     # []
#     # [bottom_y]
#     #     type = CoupledVarNeumannBC
#     #     variable = disp_y
#     #     boundary = 'bottom'
#     #     v = vel_y
#     #     coef= ${fparse -c_l}
#     # []
#     # [left_x]
#     #     type = CoupledVarNeumannBC
#     #     variable = disp_x
#     #     boundary = 'left'
#     #     v = vel_x
#     #     coef= ${fparse -2600*c_l}
#     # []
#     # [left_y]
#     #     type = CoupledVarNeumannBC
#     #     variable = disp_y
#     #     boundary = 'left'
#     #     v = vel_y
#     #     coef= ${fparse -2600*c_s}
#     # []
# []

[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 6.663e10
    poissons_ratio = 0.33
  []
  # [strain]
  #   type = ComputeSmallStrain
  #   displacements = 'disp_x disp_y'
  # []
  [stress]
    type = ComputeLinearElasticStress
  []
[]
[Executioner]
  type = Transient
  solve_type = 'NEWTON'
  start_time = 0.0
  end_time = 2e-6
  dt = 0.0125e-6
  dtmin = 0.0125e-6
  automatic_scaling = true
  [TimeIntegrator]
    type = NewmarkBeta
  []
[]

[Outputs]
exodus = true
[]