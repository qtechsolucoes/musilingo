// lib/app/presentation/widgets/score_viewer_widget.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ScoreViewerWidget extends StatelessWidget {
  final WebViewController controller;

  const ScoreViewerWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // O SizedBox com tamanho definido é crucial para evitar erros de layout infinito.
    // Ajuste estes valores conforme necessário para o seu design.
    return SizedBox(
      width: 800,
      height: 250,
      child: WebViewWidget(
        controller: controller,
        gestureRecognizers: const {}, // Desativa gestos para evitar conflitos de scroll
      ),
    );
  }
}
