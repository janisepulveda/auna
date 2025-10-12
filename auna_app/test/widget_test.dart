// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:auna_app/main.dart';      // <-- asegúrate que 'auna_app' sea el nombre de tu proyecto
import 'package:auna_app/user_provider.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // construimos la app de la misma forma que en main.dart, incluyendo el provider.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => UserProvider(),
        child: const MyApp(),
      ),
    );

    // esta prueba simple solo verifica que la app se inicia correctamente.
    // busca un widget del tipo MyApp y espera encontrar uno.
    expect(find.byType(MyApp), findsOneWidget);
  });
}