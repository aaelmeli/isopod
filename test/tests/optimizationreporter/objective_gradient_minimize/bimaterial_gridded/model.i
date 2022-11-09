# Steady state Heat conduction in a 2D domain with two diffusivities
# The domain is -4 <= x <= 4 and -4 <= y <= 4
# The top-half of the domain (y > 0) has high diffusivity
# The top-half of the domain (y < 0) has low diffusivity

[Mesh]
  [gmg]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 8
    ny = 8
    xmin = -4
    xmax = 4
    ymin = -4
    ymax = 4
  []
[]

[Variables]
  [temperature]
  []
[]

[Kernels]
  [conduction]
    type = MatDiffusion
    diffusivity = diffusivity
    variable = temperature
  []
  # [heat_source]
  #   type = ADMatHeatSource
  #   material_property = volumetric_heat
  #   variable = temperature
  # []
[]

[DiracKernels]
  [point_heat_source]
    type = ConstantPointSource
    point = '2 2 0'
    variable = temperature
    value = 10
  []
[]
[AuxVariables]
  [grad_Tx]
    order = CONSTANT
    family = MONOMIAL
  []
  [grad_Ty]
    order = CONSTANT
    family = MONOMIAL
  []
  [grad_Tz]
    order = CONSTANT
    family = MONOMIAL
  []
  [diffusivity_values]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [grad_Tx]
    type = VariableGradientComponent
    component = x
    variable = grad_Tx
    gradient_variable = temperature
  []
  [grad_Ty]
    type = VariableGradientComponent
    component = y
    variable = grad_Ty
    gradient_variable = temperature
  []
  [grad_Tz]
    type = VariableGradientComponent
    component = z
    variable = grad_Tz
    gradient_variable = temperature
  []
  [diffusivity_values_auxkernel]
    type = FunctionAux
    function = diffusivity_values
    variable = diffusivity_values
    execute_on = initial
  []
[]

[BCs]
  [bottom]
    type = DirichletBC
    variable = temperature
    boundary = bottom
    value = 0
  []
  [top]
    type = DirichletBC
    variable = temperature
    boundary = top
    value = 0
  []
[]

[Functions]
  [diffusivity_values]
    type = PiecewiseMulticonstantFromReporter
    direction = 'left left'
    values_name = 'gridData/parameter'
    grid_name = 'gridData/grid'
    axes_name = 'gridData/axes'
    step_name = 'gridData/step'
    dim_name = 'gridData/dim'
  []
[]

[Materials]
  [mat_diff]
    type = GenericFunctionMaterial
    prop_names = diffusivity
    prop_values = diffusivity_values
  []
  # [volumetric_heat]
  #   type = ADGenericFunctionMaterial
  #   prop_names = 'volumetric_heat'
  #   prop_values = 100
  # []
[]

[VectorPostprocessors]
  [data_pt]
    type = VppPointValueSampler
    variable = temperature
    reporter_name = measure_data
  []
  # [synthetic_data]
  #   type = LineValueSampler
  #   variable = 'temperature'
  #   start_point = '0 -4 0'
  #   end_point = '0 4 0'
  #   num_points = 9
  #   sort_by = id
  # []
  # [synthetic_data]
  #   type = NodalValueSampler
  #   variable = 'temperature'
  #   sort_by = id
  # []
[]

# [Reporters]
#   [measure_data]
#     type = OptimizationData
#     execute_on = timestep_end
#   []
# []

[Reporters]
  [measure_data]
    type = OptimizationData
    measurement_file = synthetic_data.csv
    file_xcoord = x
    file_ycoord = y
    file_zcoord = z
    file_value = temperature
    variable = temperature
    execute_on = timestep_end
    outputs = none
  []
  [gridData]
    type = GriddedDataReporter
    data_file = 'gridded_material_params_const.txt'
    # execute_on = ALWAYS
    # outputs = none
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  nl_forced_its = 1
  line_search = none
  nl_abs_tol = 1e-8
[]

[Outputs]
  file_base = 'forward'
  console = false
  # csv = true
  # exodus = true
[]
