import 'package:flutter/material.dart';

import '../../core/constants/assets_paths.dart';

/// Mascote do Auri.
///
/// É uma imagem única, igual em todas as paletas. Para trocar o desenho,
/// substitua o arquivo `assets/images/auri/auri.png` (ou aponte
/// `AssetPaths.auri` para o novo arquivo).
class AuriAvatarWidget extends StatelessWidget {
  const AuriAvatarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AssetPaths.auri,
      fit: BoxFit.contain,
      semanticLabel: 'Assistente virtual Auri',
    );
  }
}
