
import 'package:ags_gold/features/user_dashboard/domain/metal_prices.dart';

MetalRetailBreakdown mockMetalRetail({
  required double spot,
  String purity = '24K',
}) {
  final duty = spot * 0.06;
  final afterDuty = spot + duty;
  final gst = afterDuty * 0.03;
  final afterGst = afterDuty + gst;
  final premium = afterGst * 0.0125;
  return MetalRetailBreakdown(
    region: 'Tamil Nadu',
    purity: purity,
    internationalSpot: spot,
    importDutyPercent: 6,
    importDutyAmount: duty,
    gstPercent: 3,
    gstAmount: gst,
    localPremiumPercent: 1.25,
    localPremiumAmount: premium,
    retailPrice: afterGst + premium,
  );
}

MetalQuote mockMetalQuote({
  required MetalType metal,
  required double spotPrice,
  required double changePercent,
  List<MetalPricePoint> trend = const [],
}) {
  final retail = mockMetalRetail(
    spot: spotPrice,
    purity: metal == MetalType.gold ? '24K' : '999',
  );
  return MetalQuote(
    metal: metal,
    unit: 'INR/gm (TN retail)',
    spotPrice: spotPrice,
    changePercent: changePercent,
    retailPrice: retail.retailPrice,
    retail: retail,
    trend: trend,
  );
}
