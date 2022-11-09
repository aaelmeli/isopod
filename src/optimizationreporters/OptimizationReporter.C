#include "OptimizationReporter.h"
#include "DelimitedFileReader.h"
// this is a base class but is only called in a testing input file
registerMooseObject("isopodTestApp", OptimizationReporter);

InputParameters
OptimizationReporter::validParams()
{
  InputParameters params = OptimizationData::validParams();
  params.addClassDescription("Base class for optimization reporter communication.");
  params.addRequiredParam<std::vector<ReporterValueName>>(
      "parameter_names", "List of parameter names, one for each group of parameters.");
  params.addRequiredParam<std::vector<dof_id_type>>(
      "num_values",
      "Number of parameter values associated with each parameter group in 'parameter_names'.");
  params.addParam<std::vector<Real>>("initial_condition",
                                     "Initial condition for each parameter values, default is 0.");
  params.addParam<std::vector<Real>>(
      "lower_bounds", std::vector<Real>(), "Lower bounds for each parameter value.");
  params.addParam<std::vector<Real>>(
      "upper_bounds", std::vector<Real>(), "Upper bounds for each parameter value.");
  // ABDO:
  params.addParam<ReporterName>("ic_from_reporter",
                                "reporter containing initial value for each point in the grid "
                                "defining the parameter for inversion.  "
                                "This uses the reporter syntax <reporter>/<name>.");

  params.addParam<FileName>(
      "ic_file", "CSV file with initial condition value and coordinates (value, x, y, z).");
  params.addParam<std::string>(
      "file_value", "value", "measurement value column name from csv file being read in");

  return params;
}
// ABDO: test the case when we have multiple parameter names/values like elasticity and viscosity,
// each is a vector of n-values represent the spatial distribution
OptimizationReporter::OptimizationReporter(const InputParameters & parameters)
  : OptimizationData(parameters),
    _parameter_names(getParam<std::vector<ReporterValueName>>("parameter_names")),
    _nparam(_parameter_names.size()),
    _nvalues(getParam<std::vector<dof_id_type>>("num_values")),
    _ndof(std::accumulate(_nvalues.begin(), _nvalues.end(), 0)),
    _lower_bounds(getParam<std::vector<Real>>("lower_bounds")),
    _upper_bounds(getParam<std::vector<Real>>("upper_bounds")),
    _ic_values(declareValueByName<std::vector<Real>>("ic_values", REPORTER_MODE_REPLICATED))
// _initial_condition(getReporterValue<std::vector<Real>>("ic_from_reporter",
// REPORTER_MODE_REPLICATED))

{
 // std::vector<Real> initial_condition;
  if (_parameter_names.size() != _nvalues.size())
    paramError("num_parameters",
               "There should be a number in 'num_parameters' for each name in 'parameter_names'.");
  if (isParamValid("ic_file"))
    readICFromFile();
  else if (isParamValid("initial_condition"))
    _ic_values = getParam<std::vector<Real>>("initial_condition");
  else
    _ic_values = std::vector<Real>(_ndof, 0.0);

  // initial_condition = getReporterValue<std::vector<Real>>("ic_from_reporter",
  // REPORTER_MODE_REPLICATED);
  if (_ic_values.size() != _ndof)
    paramError("initial_condition",
               "Initial condition must be same length as the total number of parameter values.");

  // ABDO: what if we want unconstrained optimization? what whould happen if we still have values
  // for the upper and lower limit? will this affect the optimization process in way or another
  // "affects convergence!"?
  if (_upper_bounds.size() > 0 && _upper_bounds.size() != _ndof)
    paramError("upper_bounds", "Upper bound data is not equal to the total number of parameters.");
  else if (_lower_bounds.size() > 0 && _lower_bounds.size() != _ndof)
    paramError("lower_bounds", "Lower bound data is not equal to the total number of parameters.");
  else if (_lower_bounds.size() != _upper_bounds.size())
    paramError((_lower_bounds.size() == 0 ? "upper_bounds" : "lower_bounds"),
               "Both upper and lower bounds must be specified if bounds are used");

  _parameters.reserve(_nparam);
  unsigned int v = 0;
  for (unsigned int i = 0; i < _parameter_names.size(); ++i)
  {
    _parameters.push_back(
        &declareValueByName<std::vector<Real>>(_parameter_names[i], REPORTER_MODE_REPLICATED));
    _parameters[i]->assign(_ic_values.begin() + v,
                           _ic_values.begin() + v + _nvalues[i]);
    v += _nvalues[i];
  }

  _misfit_values.resize(_measurement_values.size(), 0.0);
}

void
OptimizationReporter::readICFromFile()
{
  // std::string xName = getParam<std::string>("file_xcoord");
  // std::string yName = getParam<std::string>("file_ycoord");
  // std::string zName = getParam<std::string>("file_zcoord");
  // std::string tName = getParam<std::string>("file_time");
  std::string valueName = getParam<std::string>("file_value");

  // bool found_x = false;
  // bool found_y = false;
  // bool found_z = false;
  // bool found_t = false;
  bool found_value = false;

  MooseUtils::DelimitedFileReader reader(getParam<FileName>("ic_file"));
  reader.read();

  auto const & names = reader.getNames();
  auto const & data = reader.getData();

  const std::size_t rows = data[0].size();
  for (std::size_t i = 0; i < names.size(); ++i)
  {
    // make sure all data columns have the same length
    if (data[i].size() != rows)
      paramError("file", "Mismatching column lengths in file");

    // if (names[i] == xName)
    // {
    //   // _measurement_xcoord = data[i];
    //   found_x = true;
    // }
    // else if (names[i] == yName)
    // {
    //   // _measurement_ycoord = data[i];
    //   found_y = true;
    // }
    // else if (names[i] == zName)
    // {
    //   // _measurement_zcoord = data[i];
    //   found_z = true;
    // }
    // else if (names[i] == tName)
    // {
    //   // _measurement_time = data[i];
    //   found_t = true;
    // }
    if (names[i] == valueName)
    {
      _ic_values = data[i];
      found_value = true;
    }
  }

  // check if all required columns were found
  // if (!found_x)
  //   paramError("ic_file", "Column with name '", xName, "' missing from measurement file");
  // else if (!found_y)
  //   paramError("ic_file", "Column with name '", yName, "' missing from measurement file");
  // else if (!found_z)
  //   paramError("ic_file", "Column with name '", zName, "' missing from measurement file");
  // else if (!found_t)
  //   _measurement_time.assign(rows, 0);
  // else if (!found_value)
  //   paramError(
  //       "ic_file", "Column with name '", valueName, "' missing from measurement file");
  if (!found_value)
    paramError("ic_file", "Column with name '", valueName, "' missing from measurement file");
}

void
OptimizationReporter::setInitialCondition(libMesh::PetscVector<Number> & x)
{
  x.init(_ndof);

  dof_id_type n = 0;
  for (const auto & param : _parameters)
    for (const auto & val : *param)
      x.set(n++, val);

  x.close();
}

void
OptimizationReporter::updateParameters(const libMesh::PetscVector<Number> & x)
{
  dof_id_type n = 0;
  for (auto & param : _parameters)
    for (auto & val : *param)
      val = x(n++);
}

std::vector<Real>
OptimizationReporter::computeDefaultBounds(Real val)
{
  std::vector<Real> vec;
  vec.resize(_nparam);
  for (auto i : index_range(vec))
    vec[i] = val;
  return vec;
}

Real
OptimizationReporter::computeAndCheckObjective(bool multiapp_passed)
{
  if (!multiapp_passed)
    mooseError("Forward solve multiapp failed!");
  return computeObjective();
}

// ABDO:: we may want to make this function as generic as possible so that the user can insert his
// own objective function of choice
Real
OptimizationReporter::computeObjective()
{
  for (size_t i = 0; i < _measurement_values.size(); ++i)
    _misfit_values[i] = _simulation_values[i] - _measurement_values[i];

  Real val = 0;
  for (auto & misfit : _misfit_values)
    val += misfit * misfit;

  val = 0.5 * val;

  return val;
}

void
OptimizationReporter::setMisfitToSimulatedValues()
{
  for (size_t i = 0; i < _measurement_values.size(); ++i)
    _misfit_values[i] = _simulation_values[i];
}

void
OptimizationReporter::setSimuilationValuesForTesting(std::vector<Real> & data)
{
  _simulation_values.clear();
  _simulation_values = data;
}
