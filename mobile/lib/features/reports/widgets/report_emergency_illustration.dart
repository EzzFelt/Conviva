import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/assets_paths.dart';

class ReportEmergencyIllustration extends StatelessWidget {
  const ReportEmergencyIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;

    return Semantics(
      image: true,
      label: 'Ilustração de uma ligação de emergência',
      child: SizedBox(
        height: sizes.xxl * 4.2,
        child: Image.asset(AssetPaths.reportEmergency, fit: BoxFit.contain),
      ),
    );
  }
}
