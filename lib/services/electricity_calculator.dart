import '../models/calculator_model.dart';

class ElectricityCalculator {
  // Standar Tarif Dasar Listrik (TDL) PLN per kWh (Golongan rumah tangga standar)
  static const double tariffPerKwh = 1444.70;

  // Fungsi untuk menghitung total estimasi biaya per bulan
  static Map<String, dynamic> calculateTotal(List<ElectronicItem> items) {
    double totalKwhPerMonth = 0.0;
    double totalCostPerMonth = 0.0;
    int totalWattActive = 0;

    for (var item in items) {
      if (item.isSelected && item.quantity > 0) {
        // Rumus: (Watt * Jam per Hari * 30 Hari) / 1000 = kWh per bulan
        double kwh = (item.defaultWatt * item.defaultHoursPerDay * 30 * item.quantity) / 1000.0;
        double cost = kwh * tariffPerKwh;

        totalKwhPerMonth += kwh;
        totalCostPerMonth += cost;
        totalWattActive += (item.defaultWatt * item.quantity);
      }
    }

    return {
      'totalWatt': totalWattActive,
      'totalKwh': totalKwhPerMonth,
      'totalCost': totalCostPerMonth,
    };
  }
}