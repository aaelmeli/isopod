# This main.i file runs the subapps model.i and grad.i, using an OptimizeFullSolveMultiApp
# The purpose of main.i is to find the two diffusivity_values
# (one in the bottom material of model.i, and one in the top material of model.i)
# such that the misfit between experimental observations (defined in model.i) and MOOSE predictions is minimised.
# The adjoint computed in grad.i is used to compute the gradient for the gradient based LMVM solver in TAO
# PETSc-TAO optimisation is used to perform this inversion
#
[StochasticTools]
[]
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

[OptimizationReporter]
  type = ObjectiveGradientMinimize
  parameter_names = 'diffusivity_values'
  num_values = 64 # diffusivity in the bottom material and in the top material of model.i
  # initial_condition = '4.5 4.5 4.5 4.5 4.5 4.5 4.5 4.5
  #                 4.5 4.5 4.5 4.5 4.5 4.5 4.5 4.5
  #                 4.5 4.5 4.5 4.5 4.5 4.5 4.5 4.5
  #                 4.5 4.5 4.5 4.5 4.5 4.5 4.5 4.5
  #                 9.5 9.5 9.5 9.5 9.5 9.5 9.5 9.5
  #                 9.5 9.5 9.5 9.5 9.5 9.5 9.5 9.5
  #                 9.5 9.5 9.5 9.5 9.5 9.5 9.5 9.5
  #                 9.5 9.5 9.5 9.5 9.5 9.5 9.5 9.5'
  # initial_condition = '1 1 1 1 1 1 1 1
  #                 1 1 1 1 1 1 1 1
  #                 1 1 1 1 1 1 1 1
  #                 1 1 1 1 1 1 1 1
  #                 1 1 1 1 1 1 1 1
  #                 1 1 1 1 1 1 1 1
  #                 1 1 1 1 1 1 1 1
  #                 1 1 1 1 1 1 1 1'
  #   initial_condition = '1 1 1 1 1 1 1 1
  #                   1 1 1 1 1 1 1 1
  #                   1 1 1 1 1 1 1 1
  #                   1 1 1 1 1 1 1 1
  # 5 5 5 5 5 5 5 5
  #   5 5 5 5 5 5 5 5
  #   5 5 5 5 5 5 5 5
  #   5 5 5 5 5 5 5 5'
  ic_file = 'ic.csv'
  file_value = 'ic'
  # ic_from_reporter = 'InitialParameters/parameter'
  # initial_condition = '4 4 4 4 4 4 4 4
  #                 4 4 4 4 4 4 4 4
  #                 4 4 4 4 4 4 4 4
  #                 4 4 4 4 4 4 4 4
  #                 4 4 4 4 4 4 4 4
  #                 4 4 4 4 4 4 4 4
  #                 4 4 4 4 4 4 4 4
  #                 4 4 4 4 4 4 4 4'
  # initial_condition = '5 5 5 5 5 5 5 5
  # 5 5 5 5 5 5 5 5
  # 5 5 5 5 5 5 5 5
  # 5 5 5 5 5 5 5 5
  # 10 10 10 10 10 10 10 10
  # 10 10 10 10 10 10 10 10
  # 10 10 10 10 10 10 10 10
  # 10 10 10 10 10 10 10 10'
  lower_bounds = '1 1 1 1 1 1 1 1
                  1 1 1 1 1 1 1 1
                  1 1 1 1 1 1 1 1
                  1 1 1 1 1 1 1 1
                  1 1 1 1 1 1 1 1
                  1 1 1 1 1 1 1 1
                  1 1 1 1 1 1 1 1
                  1 1 1 1 1 1 1 1'
  upper_bounds = '5 5 5 5 5 5 5 5
  5 5 5 5 5 5 5 5
  5 5 5 5 5 5 5 5
  5 5 5 5 5 5 5 5
  10 10 10 10 10 10 10 10
  10 10 10 10 10 10 10 10
  10 10 10 10 10 10 10 10
  10 10 10 10 10 10 10 10'
  measurement_file = 'synthetic_data.csv'
  # file_value = 'temperature'
[]

[Executioner]
  type = Optimize
  tao_solver = taoblmvm
  # petsc_options_iname = '-tao_fd_gradient -tao_gatol -tao_fd_delta '
  # petsc_options_value = ' true            0.00001 1e-6'
  # type = Optimize
  # tao_solver = taoblmvm
  petsc_options_iname = '-tao_gatol'
  petsc_options_value = '1e-5'
  ## THESE OPTIONS ARE FOR TESTING THE ADJOINT GRADIENT
  # petsc_options_iname = '-tao_max_it -tao_fd_test -tao_test_gradient -tao_fd_gradient -tao_fd_delta -tao_gatol'
  # petsc_options_value = '10 true true false 1e-6 0.00001'
  # petsc_options = '-tao_test_gradient_view'
  verbose = true
[]
[AuxVariables]
  [temperature_forward]
  []
[]
[MultiApps]
  [forward]
    type = OptimizeFullSolveMultiApp
    input_files = model.i
    execute_on = "FORWARD"
    # clone_parent_mesh = true
    ignore_solve_not_converge = false
  []
  [adjoint]
    type = OptimizeFullSolveMultiApp
    input_files = grad.i #write this input file to compute the adjoint solution and the gradient
    execute_on = "ADJOINT"
    # clone_parent_mesh = true
    ignore_solve_not_converge = false
  []
  # [homogeneous_forward]
  #   type = OptimizeFullSolveMultiApp
  #   input_files = forward_const.i
  #   execute_on = "HOMOGENEOUS_FORWARD"
  # []  
[]

[Transfers]
  [diffusivity_to_forward] #update the model with the new parameters
    type = MultiAppReporterTransfer
    to_multi_app = forward
    from_reporters = 'OptimizationReporter/diffusivity_values'
    to_reporters = 'gridData/parameter'
  []
  [from_forward2]
    type = MultiAppReporterTransfer
    from_multi_app = forward
    from_reporters = 'measure_data/misfit_values
                      measure_data/simulation_values
                      measure_data/measurement_values'
    to_reporters = 'OptimizationReporter/misfit_values
                      OptimizationReporter/simulation_values
                      OptimizationReporter/measurement_values'
  []
  # [toForward_measument] #pass the coordinates where we knew the measurements to the forward model to do the extraction of the simulation data at the location of the measurements to compute the misfit
  #   type = MultiAppReporterTransfer
  #   to_multi_app = forward
  #   from_reporters = 'OptimizationReporter/measurement_xcoord OptimizationReporter/measurement_ycoord OptimizationReporter/measurement_zcoord OptimizationReporter/measurement_values'
  #   to_reporters = 'measure_data/measurement_xcoord measure_data/measurement_ycoord measure_data/measurement_zcoord measure_data/measurement_values'
  # []
  [from_forward] #get the simulation values
    type = MultiAppReporterTransfer
    from_multi_app = forward
    from_reporters = 'data_pt/temperature'
    to_reporters = 'OptimizationReporter/simulation_values'
  []
  #############
  #copy the temprature variable - we will need this for the compuation of the gradient
  [fromforwardMesh]
    type = MultiAppCopyTransfer
    from_multi_app = forward
    source_variable = 'temperature'
    variable = 'temperature_forward'
  []
  [toAdjointMesh]
    type = MultiAppCopyTransfer
    to_multi_app = adjoint
    source_variable = 'temperature_forward'
    variable = 'temperature_forward'
  []
  #############
  [diffusivity_to_adjoint] #update the adjoint with the new parameters
    type = MultiAppReporterTransfer
    to_multi_app = adjoint
    from_reporters = 'OptimizationReporter/diffusivity_values'
    to_reporters = 'gridData/parameter'
  []
  [toAdjoint] #pass the misfit to the adjoint
    type = MultiAppReporterTransfer
    to_multi_app = adjoint
    from_reporters = 'OptimizationReporter/measurement_xcoord OptimizationReporter/measurement_ycoord OptimizationReporter/measurement_zcoord'
    to_reporters = 'misfit/measurement_xcoord misfit/measurement_ycoord misfit/measurement_zcoord'
  []
  [toAdjoint2] #pass the misfit to the adjoint
    type = MultiAppReporterTransfer
    to_multi_app = adjoint
    from_reporters = 'OptimizationReporter/misfit_values'
    to_reporters = 'misfit/misfit_values'
  []
  [fromadjoint]
    type = MultiAppReporterTransfer
    from_multi_app = adjoint
    from_reporters = 'gradvec/integral_gradient'
    to_reporters = 'OptimizationReporter/adjoint'
  []
[]
# [Reporters]
#   [InitialParameters]
#     type = GriddedDataReporter
#     data_file = 'gridded_material_params_const.dat'
#     execute_on = ALWAYS
#   []
# []
[Outputs]
  console = true
  csv = true
[]
