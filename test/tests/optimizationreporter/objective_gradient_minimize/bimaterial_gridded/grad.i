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
  # [bimaterial]
  #   type = SubdomainBoundingBoxGenerator
  #   input = gmg
  #   block_id = 1
  #   bottom_left = '-100 -100 -100'
  #   top_right = '100 0 100'
  # []
  # [name_blocks]
  #   type = RenameBlockGenerator
  #   input = bimaterial
  #   old_block = '0 1'
  #   new_block = 'top bottom'
  # []
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
[]

[DiracKernels]
  [pt]
    type = ReporterPointSource
    variable = temperature
    x_coord_name = 'misfit/measurement_xcoord'
    y_coord_name = 'misfit/measurement_ycoord'
    z_coord_name = 'misfit/measurement_zcoord'
    value_name = 'misfit/misfit_values'
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

[AuxVariables]
  [forwardAdjoint]
  []
  [temperature_forward]
  []
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
  [grad_Tfx]
    order = CONSTANT
    family = MONOMIAL
  []
  [grad_Tfy]
    order = CONSTANT
    family = MONOMIAL
  []
  [grad_Tfz]
    order = CONSTANT
    family = MONOMIAL
  []
  [gradient]
    order = CONSTANT
    family = MONOMIAL
  []
  [integral_gradient]
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
  [grad_Tfx]
    type = VariableGradientComponent
    component = x
    variable = grad_Tfx
    gradient_variable = temperature_forward
  []
  [grad_Tfy]
    type = VariableGradientComponent
    component = y
    variable = grad_Tfy
    gradient_variable = temperature_forward
  []
  [grad_Tfz]
    type = VariableGradientComponent
    component = z
    variable = grad_Tfz
    gradient_variable = temperature_forward
  []
  [gradient]
    type = ParsedAux
    variable = gradient
    args = 'grad_Tx grad_Ty grad_Tz grad_Tfx grad_Tfy grad_Tfz'
    function = '-grad_Tx*grad_Tfx-grad_Ty*grad_Tfy-grad_Tz*grad_Tfz' #we need to include the material derivative, which can be captured when computing the flux based on the derivative of the material.
  []
  [forwardAdjoint] # I am not sure why do we need this?
    type = ParsedAux
    variable = forwardAdjoint
    args = 'temperature_forward temperature'
    function = 'temperature_forward*temperature'
  []
  # Elemental Lp integration of strain x stress
  [elemental_integral_gradu_gradv]
    type = ElementLpNormAux
    p = 1 # I have modified the code in the Auxkernel to not take the absolute value. this has to be fixed in more appropriate way (TODO)
    variable = integral_gradient
    coupled_variable = gradient
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

[Materials] #same material as what was used in the forward model
  [mat_diff]
    type = GenericFunctionMaterial
    prop_names = diffusivity
    prop_values = diffusivity_values
  []
[]

# [Postprocessors]
#   [d_bot]
#     type = VectorPostprocessorComponent
#     index = 0
#     vectorpostprocessor = vector_pp
#     vector_name = diffusivity_values
#     execute_on = 'linear'
#   []
#   [d_top]
#     type = VectorPostprocessorComponent
#     index = 1
#     vectorpostprocessor = vector_pp
#     vector_name = diffusivity_values
#     execute_on = 'linear'
#   []
#   ############
#   # we need to combine the two in one vector.
#   [grad_bottom] #compute the integral of the gradient variable on the bottom block (first parameter)
#     type = ElementIntegralVariablePostprocessor
#     variable = gradient
#     execute_on = 'final'
#     block = bottom
#   []
#   [grad_top] #compute the integral of the gradient variable on the bottom block (second parameter)
#     type = ElementIntegralVariablePostprocessor
#     variable = gradient
#     execute_on = 'final'
#     block = top
#   []
#   ############
# []
[VectorPostprocessors]
  [gradvec]
    type = ElementValueSampler
    variable = 'integral_gradient'
    sort_by = id
    # outputs = 'element_integral_Lp_norm'
    # execute_on = 'FINAL'
  []
[]
# [VectorPostprocessors]
#   [vector_pp]
#     type = ConstantVectorPostprocessor
#     vector_names = diffusivity_values
#     value = '1.0 10.0' #we need to set initial values (any values)- these will be over-written
#   []
#   [gradvec]
#     type = VectorOfPostprocessors
#     postprocessors = 'grad_bottom grad_top'
#     execute_on = 'final'
#   []
# []
# [Reporters]
#   [misfit]
#     type = OptimizationData
#   []
# []
[Reporters]
  [misfit]
    type = OptimizationData
    execute_on = TIMESTEP_BEGIN
  []
  # [measure_data]
  #   type = OptimizationData
  #   measurement_file = synthetic_data.csv
  #   file_xcoord = x
  #   file_ycoord = y
  #   file_zcoord = z
  #   file_value = temperature
  #   variable = temperature
  #   execute_on = timestep_end
  #   outputs = none
  # []
  [gridData]
    type = GriddedDataReporter
    data_file = 'gridded_material_params_const.txt'
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
  verbose = true
[]

[Outputs]
  # [element_integral_Lp_norm]
  #   file_base = 'grad_computation/'
  #   type = CSV
  #   execute_on = final
  # []
  console = false
  file_base = 'adjoint'
  # csv = true
  # exodus = true
[]
