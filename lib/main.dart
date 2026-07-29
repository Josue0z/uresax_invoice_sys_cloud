import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:localstorage/localstorage.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:moment_dart/src/types.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/pages/login_page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/widgets/startup-loader.dart';
import 'package:window_manager/window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();
    await initLocalStorage();

    Moment.setGlobalLocalization(
        MomentLocalizations.byLanguage('es', countryCode: 'DO')!);

    if (eCommerceMode) {
      devicePos = localStorage.getItem('devicePos');
    }

    var packageInfo = await PackageInfo.fromPlatform();

    appVersion = 'Versión: ${packageInfo.version}+${packageInfo.buildNumber}';

    localVersion = packageInfo.version;

    pdfrxFlutterInitialize();
   /* SubscriptionModel.productId =
        kDebugMode ? 'PROD-6JV205632W210245R' : 'PROD-6G003192PN109623E';
    SubscriptionModel.clientId = kDebugMode
        ? 'AS1SCEgA8c2TfYDvRyYm7Fyv741whzVsWpkeSjGVyoBACA6FbhG_hi38oe5kwj2lPz8AhHDajiZB4T_5'
        : 'AV6aMpqVyE8ED3jYsg06frgO4UnC1W7MduM1mlrripuFvyLVDpS1Lp9BQTVLuDosmajs3pmkbQNBZIxG';
    SubscriptionModel.clientSecret = kDebugMode
        ? 'EJJq2E8EkR5jQYdYVNfrDTpbamJ6sJQqSb-Akciezf0_UdzmrH3Hn679o3B0LTH-BKFre9gY30QdOKDO'
        : 'EIXu52Z8VVv60wygFtRNkkTAdO3SVcaRIZw4CjGCAgU3uNJ80xmsz_0IPftzcCrb0yaQSh8TD-7tPO9t';
   // await SqlConector.initialize();
    bool? xhas = false;
    try {
      xhas = await hasInternet();
    } catch (_) {
      xhas = false;
    }

    if (xhas == true) {
      await SubscriptionModel.init();
    }
    var data = await SubscriptionModel.findSubscription();
    var id = data?['subscriptionId'];
    var planId = data?['planId'];
    SubscriptionModel.subscriptionId = id;
    SubscriptionModel.planId = planId;

    if (id != null) {
      try {
        if (xhas == true) {
          await SubscriptionModel.checkIfExistSubscriptionIsActive();
          await SubscriptionModel.updateSubscriptionsStatus();
        }
      } catch (_) {}
    }*/

    List<String> errors = [];
    // Obtener los límites de la pantalla principal
    final screenBounds = await windowManager.getBounds();

    final width = screenBounds.width * 0.8;
    final height = screenBounds.height * 0.92;

    final sizeWindow = Size(width, height);

    WindowOptions windowOptions = WindowOptions(
        size: sizeWindow,
        minimumSize: sizeWindow,
        center: true,
        title: 'URESAX INVOICE SYS');


  
    if (dirPath == null) {
      errors.add('URESAX_INVOICE_STATIC_LOCAL_SERVER_PATH,\n');
    }


    if (errors.isNotEmpty) {
      errors.insert(
          0, 'Faltan las siguientes variables de entorno:\n'.toUpperCase());
      throw errors.join();
    }

    runApp(MyApp());

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setMinimizable(true);
      await windowManager.setMaximizable(true);
    });
  } catch (e) {
    await FlutterPlatformAlert.playAlertSound();

    await FlutterPlatformAlert.showAlert(
        windowTitle: 'ALERTA',
        text: e.toString(),
        alertStyle: AlertButtonStyle.yesNoCancel,
        iconStyle: IconStyle.information);

    await windowManager.close();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool loading = true;
  bool error = false;
  String errorMessage = '';

  _initAsync() async {
    try {
  
      await Future.delayed(const Duration(seconds: 1));
      loading = false;
    } catch (e) {
   
      loading = false;
      error = true;
      errorMessage = e.toString();
      await LogHandler.printError(e.toString());
    }

    setState(() {});
  }

  Widget get content {
    if (loading) {
      return StartupLoader();
    }

    if (error) {
      return Scaffold(
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, size: 90),
              SizedBox(
                height: kDefaultPadding,
              ),
              Text(errorMessage)
            ],
          ),
        ),
      );
    }
    return LoginPage();
  }

  @override
  void initState() {
    _initAsync();
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
        menus: [PlatformMenuItem(label: 'URESAX INVOICE SYS')],
        child: MaterialApp(
          title: 'URESAX INVOICE SYS',
          locale: Locale('es', 'ES'),
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('es', 'ES'),
          ],
          debugShowCheckedModeBanner: false,
          scrollBehavior: ScrollConfiguration.of(context).copyWith(
              physics: Theme.of(context).platform == TargetPlatform.iOS ||
                      Theme.of(context).platform == TargetPlatform.macOS
                  ? const BouncingScrollPhysics()
                  : const ClampingScrollPhysics(),
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.unknown
              }),
          theme: ThemeData(
              primaryColor: const Color(0xFF2196F3),
              primarySwatch: Colors.blue,
              useMaterial3: false,
              scrollbarTheme: ScrollbarThemeData(
                  trackVisibility: WidgetStatePropertyAll(false),
                  thumbVisibility: WidgetStatePropertyAll(false)),
              appBarTheme: AppBarTheme(
                centerTitle: false,
                toolbarHeight: kToolbarHeight * 2.4,
                elevation: 0,
              ),
              dropdownMenuTheme: DropdownMenuThemeData(
                menuStyle: MenuStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(60)),
                  ),
                ),
              ),
              popupMenuTheme: PopupMenuThemeData(
                  shape: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(30))),
              elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ButtonStyle(
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20))))),
              textTheme: TextTheme(
                  displayLarge: TextStyle(fontSize: 24),
                  displayMedium: TextStyle(fontSize: 20),
                  bodyLarge: TextStyle(fontSize: 20),
                  bodyMedium: TextStyle(fontSize: 18),
                  bodySmall: TextStyle(fontSize: 15)),
              inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)))),
          builder: OnscreenKeyboard.builder(
              width: (context) => MediaQuery.sizeOf(context).width / 5,
              layout: numericLayout),
          home: content,
        ));
  }
}

final numericMode = KeyboardMode(
  rows: [
    KeyboardRow(keys: [
      OnscreenKeyboardKey.text(primary: '1'),
      OnscreenKeyboardKey.text(primary: '2'),
      OnscreenKeyboardKey.text(primary: '3')
    ]),
    KeyboardRow(keys: [
      OnscreenKeyboardKey.text(primary: '4'),
      OnscreenKeyboardKey.text(primary: '5'),
      OnscreenKeyboardKey.text(primary: '6')
    ]),
    KeyboardRow(keys: [
      OnscreenKeyboardKey.text(primary: '7'),
      OnscreenKeyboardKey.text(primary: '8'),
      OnscreenKeyboardKey.text(primary: '9')
    ]),
    KeyboardRow(keys: [
      OnscreenKeyboardKey.text(primary: '0'),
      OnscreenKeyboardKey.action(name: 'backspace', label: '⌫')
    ])
  ],
);
final numericLayout = KeyboardLayout.custom(
  aspectRatio: 1, // ajusta proporción de teclas
  modes: {'numeric': numericMode},
);

class EsDO extends MomentLocalization {
  EsDO();

  @override
  String get locale => 'es_DO';

  String get name => 'Español República Dominicana';

  @override
  String? get countryCode => 'DO';

  @override
  String get languageCode => 'es';

  @override
  String get languageNameInEnglish => 'Spanish (Dominican Republic)';

  @override
  String get endonym => 'Español';

  @override
  CalenderLocalizationData get calendarData => CalenderLocalizationData(
        relativeDayNames: {
          0: 'hoy', // mismo día
          1: 'mañana', // día siguiente
          -1: 'ayer', // día anterior
          7: 'la próxima semana',
          -7: 'la semana pasada',
        },
        keywords: CalenderLocalizationKeywords(),
      );

  @override
  Map<int, String> get weekdayName => const {
        DateTime.monday: 'lunes',
        DateTime.tuesday: 'martes',
        DateTime.wednesday: 'miércoles',
        DateTime.thursday: 'jueves',
        DateTime.friday: 'viernes',
        DateTime.saturday: 'sábado',
        DateTime.sunday: 'domingo',
      };

  @override
  FormatSetOptional overrideFormatters() {
    return FormatSetOptional();
  }

  @override
  String duration(
    Duration duration, {
    bool round = true,
    bool omitZeros = true,
    bool includeWeeks = false,
    Abbreviation form = Abbreviation.none,
    String? delimiter,
    DurationFormat format = DurationFormat.auto,
    bool dropPrefixOrSuffix = false,
  }) {
    // Ejemplo simple: "2 horas 30 minutos"
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours horas $minutes minutos';
    } else if (hours > 0) {
      return '$hours horas';
    } else {
      return '$minutes minutos';
    }
  }

  @override
  String relative(
    Duration duration, {
    bool dropPrefixOrSuffix = false,
    Abbreviation form = Abbreviation.none,
  }) {
    if (duration.inSeconds.abs() < 60) {
      return 'hace unos segundos';
    } else if (duration.inMinutes.abs() < 60) {
      return 'hace ${duration.inMinutes.abs()} minutos';
    } else if (duration.inHours.abs() < 24) {
      return 'hace ${duration.inHours.abs()} horas';
    } else {
      return 'hace ${duration.inDays.abs()} días';
    }
  }
}
