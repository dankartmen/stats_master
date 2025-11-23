import 'distribution_parameters.dart';

/// {@template bayesian_classifier}
/// Модель с деталями расчета ошибки для одного интервала
/// {@endtemplate}
class ErrorCalculationDetails {
  final double start;
  final double end;
  final String losingClass;
  final DistributionParameters distribution;
  final double probability;
  final double errorValue;
  final String calculationFormula;
  final String calculationSteps;

  const ErrorCalculationDetails({
    required this.start,
    required this.end,
    required this.losingClass,
    required this.distribution,
    required this.probability,
    required this.errorValue,
    required this.calculationFormula,
    required this.calculationSteps,
  });
}