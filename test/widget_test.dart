// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musilingo/app/presentation/view/splash_screen.dart';

void main() {
  testWidgets('SplashScreen shows a progress indicator',
      (WidgetTester tester) async {
    // Envolvemos a SplashScreen em um MaterialApp para que ela tenha o contexto necessário para rodar.
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    // Verifica se o CircularProgressIndicator está presente na tela de splash.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
