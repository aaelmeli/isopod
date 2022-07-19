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
c_l=5188.75 #longitudinal/compression wave speed
c_s=3100 #shear wave speed
[Mesh]
  type = GeneratedMesh
   dim = 2
    xmin=0
   xmax=0.01
   ymin=-0.005
   ymax=0
   nx = 200
   ny=50
[]
[GlobalParams]
  displacements = 'disp_x disp_y'
[]
[AuxVariables] # variables that are calculated for output
  [vel_x]
  []
  [vel_y]
  []
  [accel_x]
  []
  [accel_y]
  []  
[]  
[Modules/TensorMechanics/DynamicMaster]
  [all]
    add_variables = true
    newmark_beta = 0.25
    newmark_gamma = 0.5
    mass_damping_coefficient = 0.0
    stiffness_damping_coefficient = 0.0
    density = 1
  []
[]
[DiracKernels]
  [point_source1]
   type = FunctionDiracSource
   variable = disp_x
   function = 'step_func2'
   point = '0.0049 0 0.0'
  []
  [point_source2]
   type = FunctionDiracSource
   variable = disp_x
   function = 'step_func1'
   point = '0.0051 0 0.0'
  []    
[]
[AuxKernels]
  [accel_x] # Calculates and stores acceleration at the end of time step
    type = NewmarkAccelAux
    variable = accel_x
    displacement = disp_x
    velocity = vel_x
    beta = 0.25
    execute_on = timestep_end
  []
  [vel_x] # Calculates and stores velocity at the end of the time step
    type = NewmarkVelAux
    variable = vel_x
    acceleration = accel_x
    gamma = 0.5
    execute_on = timestep_end
  []
  [accel_y]
    type = NewmarkAccelAux
    variable = accel_y
    displacement = disp_y
    velocity = vel_y
    beta = 0.25
    execute_on = timestep_end
  []
  [vel_y]
    type = NewmarkVelAux
    variable = vel_y
    acceleration = accel_y
    gamma = 0.5
    execute_on = timestep_end
  []
 [] 
[Functions]
 [step_func1] #step funtion in time with duration 40 micro-second
    type = ParsedFunction
    # value=1
    #value = 'if(t < 0.25001e-6, sin(2*pi*t*2e6), 0)'
    value = 'if(t < 0.25001e-6, -1, 0)'
    # value = ${fparse sin(2*t*pi*freq)}#this holds the spatial distribution of the youngs_modulus
  []
 [step_func2] #step funtion in time with duration 40 micro-second
    type = ParsedFunction
    # value=1
    #value = 'if(t < 0.25001e-6, sin(2*pi*t*2e6), 0)'
    value = 'if(t < 0.25001e-6, 1, 0)'
    # value = ${fparse sin(2*t*pi*freq)}#this holds the spatial distribution of the youngs_modulus
  []  
[] 

 [BCs]
    [left]
        type = DirichletBC
        variable = 'disp_x'
        boundary = 'left'
        value=0
    []
    [right_x]
        type = CoupledVarNeumannBC
        variable = disp_x
        boundary = 'right'
        v = vel_x
        coef= ${fparse -c_l} #how can I change this during the runtime of matlab wrapper.
    []
    [right_y]
        type = CoupledVarNeumannBC
        variable = disp_y
        boundary = 'right'
        v = vel_y
        coef= ${fparse -c_s} #how can I change this during the runtime of matlab wrapper.
    []
    # [bottom_x]
    #     type = CoupledVarNeumannBC
    #     variable = disp_x
    #     boundary = 'bottom'
    #     v = vel_x
    #     coef= ${fparse -c_s} #how can I change this during the runtime of matlab wrapper.
    # []
    # [bottom_y]
    #     type = CoupledVarNeumannBC
    #     variable = disp_y
    #     boundary = 'bottom'
    #     v = vel_y
    #     coef= ${fparse -c_l} #how can I change this during the runtime of matlab wrapper.
    # []
    [left_x]
        type = CoupledVarNeumannBC
        variable = disp_x
        boundary = 'left'
        v = vel_x
        coef= ${fparse -c_l} #how can I change this during the runtime of matlab wrapper.
    []
    [left_y]
        type = CoupledVarNeumannBC
        variable = disp_y
        boundary = 'left'
        v = vel_y
        coef= ${fparse -c_s} #how can I change this during the runtime of matlab wrapper.
    []                     
[]

[Materials]
  [Elasticity_tensor]
    type = ComputeElasticityTensor
    fill_method = symmetric_isotropic_E_nu
    C_ijkl = '26923076.9231 0.33'
  []
  [stress]
    type = ComputeLinearElasticStress
  []
[]
[Executioner]
  # type = Transient
  # start_time = 0
  # end_time = 5*e-6
  # dt = 0.025*e-6
  type = Transient
  solve_type = 'NEWTON'
  # petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
  # petsc_options_value = 'lu       superlu_dist'
  start_time = 0.0
  end_time = 4e-6
  dt = 0.025e-6
  dtmin = 0.01e-6
  # nl_abs_tol = 1e-8
  # nl_rel_tol = 1e-8
  # l_tol = 1e-8
  # l_max_its = 25
  # timestep_tolerance = 1e-8
  automatic_scaling = true
  [TimeIntegrator]
    type = NewmarkBeta
  []  
[]

[VectorPostprocessors]
#output the epicenter displacement. this is time-harmonic solution.
#if the total history is needed, we may want to sweep over all possible frequencies and then do IFFT
    [ux_point_sample]
        type = PointValueSampler
        variable = 'disp_x' 
        points = '0 -0.005 0'
        sort_by = x
        execute_on='ALWAYS'
        outputs='u_all'
    []
    [uy_point_sample]
        type = PointValueSampler
        variable = 'disp_y'
        points = '0 -0.005 0'
        sort_by = x
        execute_on='ALWAYS'
        outputs='u_all'
    []             
[]
# Note: This output block is out of its normal place (should be at the bottom)
[Outputs]
exodus = true
    # [exodus]
    #     file_base = '_model/'
    #     execute_vector_postprocessors_on = 'final'
    # []
    [u_all]
        file_base = '_model4/'
        type = CSV
        execute_vector_postprocessors_on = 'LINEAR'
    []
        perf_graph = true
[]




