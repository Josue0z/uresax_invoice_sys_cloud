import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/toolbutton.widget.dart';
import 'dart:math' as math;
import 'package:public_file_saver/public_file_saver.dart';

enum RotateMode { right, left }

class PdfViewerWidget extends StatefulWidget {
  final File file;

  final PdfPageRotation? rotation;

  PdfViewerWidget({super.key, required this.file, this.rotation});

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  File? file;
  double _scale = 0.8;
  int _rotationSteps = 0; // 0 = 0°, 1 = 90°, 2 = 180°, 3 = 270°

  final GlobalKey _scrollKey = GlobalKey();
  Offset _mousePosition = Offset.zero;

  PdfDocument? _document;

  PdfPageRotation? _currentRotation;

  double minWidth = 500;
  double baseWidth = 1100; // ancho original del PDF o del contenedor

  double maxWidth = 1600;

  double newWidth = 1100;

  late Uint8List bytesPdf;


  List<String> printers = [];
  String? currentPrinter;

  Future<void> loadDefaultPrinter() async {
    if (printers.isNotEmpty) {
      currentPrinter = printers[0];
    }
  }

  Future<void> getPrinters() async {
    try {
      printers = await PrinterHandler.listPrinters();
      print(printers);
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();

    _currentRotation = widget.rotation;

    if (_currentRotation == null) {
      _rotationSteps = 0;
    }
    if (_currentRotation == PdfPageRotation.clockwise90) {
      _rotationSteps = 1;
    }

    if (_currentRotation == PdfPageRotation.clockwise180) {
      _rotationSteps = 2;
    }

    if (_currentRotation == PdfPageRotation.clockwise270) {
      _rotationSteps = 3;
    }
    _loadPdf();

  }

  Future<void> _loadPdf() async {
    await getPrinters();
    await loadDefaultPrinter();
    var dir = await getTemporaryDirectory();
    file = File(path.join(dir.path, 'pdf_view.pdf'));
    await file?.create(recursive: true);
    bytesPdf = await widget.file.readAsBytes();
    await file?.writeAsBytes(bytesPdf);

    var xcurrentPrinter =  localStorage.getItem('CURRENT_PRINTER_PDF_VIEWER');

    if(xcurrentPrinter != null){
      currentPrinter = xcurrentPrinter;
    }

    final doc = await PdfDocument.openFile(file?.path ?? '');

    setState(() {
      _document = doc;
    });
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

      if (isCtrlPressed) {
        setState(() {
          if (event.scrollDelta.dy < 0) {
            _scale += 0.1;
          } else {
            _scale -= 0.1;
          }

          // calcular ancho resultante
          newWidth = baseWidth * _scale;

          // limitar entre minWidth y maxWidth
          newWidth = newWidth.clamp(minWidth, maxWidth);

          // actualizar _scale en función del ancho limitado
          _scale = newWidth / baseWidth;

          print("Scale: $_scale, Width: $newWidth");
        });
      }
    }
  }

  void _handleHover(PointerHoverEvent event) {
    if (event is PointerScrollEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

      if (isCtrlPressed) {
        final box = _scrollKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          setState(() {
            _mousePosition = box.globalToLocal(event.position);
          });
        }
      }
    }
  }

  void _rotatePdf({RotateMode mode = RotateMode.right}) {
    setState(() {
      if (mode == RotateMode.right) {
        _rotationSteps = (_rotationSteps + 1) % 4;
      } else {
        _rotationSteps = (_rotationSteps - 1) % 4;
        if (_rotationSteps < 0) _rotationSteps += 4;
      }
      if (_rotationSteps == 0) {
        _currentRotation = null;
      }
      if (_rotationSteps == 1) {
        _currentRotation = PdfPageRotation.clockwise90;
      }

      if (_rotationSteps == 2) {
        _currentRotation = PdfPageRotation.clockwise180;
      }

      if (_rotationSteps == 3) {
        _currentRotation = PdfPageRotation.clockwise270;
      }
    });
  }

  String get fileName {
    return path.basename(widget.file.path);
  }

  @override
  Widget build(BuildContext context) {
    final double angle = _rotationSteps * (math.pi / 2);
    // Si rota 90° o 270°, los ejes ancho/alto se invierten visualmente
    final bool isRotated90Or270 = _rotationSteps % 2 != 0;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 221, 221),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(fileName),
        toolbarHeight: kToolbarHeight + kDefaultPadding,
        actions: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runAlignment: WrapAlignment.center,
            children: [
              ToolButtonWidget(
                onTap: () => _rotatePdf(mode: RotateMode.right),
                icon: Icons.rotate_right_sharp,
              ),
              ToolButtonWidget(
                icon: Icons.refresh,
                onTap: () {
                  setState(() {
                    _scale = 0.8;
                    newWidth = 1100;
                    baseWidth = 1100;

                    // recalcular ancho en función de baseWidth
                    newWidth = baseWidth * _scale;

                    _rotationSteps = 0;
                  });
                },
              ),

              ToolButtonWidget(
                icon: Icons.save,
                onTap: () async {
                  final fileSaver = PublicFileSaver();
                  final result = await fileSaver.save(
                    useDialog: true,
                    bytes: bytesPdf,
                    fileName: fileName,
                  );
                },
              ),

              SizedBox(
                width: 400,
                height: 60,
                child: DropdownButtonFormField<String>(
                  initialValue: currentPrinter,
                  isDense: true,
                  isExpanded: true,
                  items: List.generate(printers.length, (i) {
                    var printer = printers[i];
                    return DropdownMenuItem(
                      value: printer,
                      child: Text(printer),
                    );
                  }),
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    hintText: 'Esperando impresora...',
                    filled: true,

                    suffixIcon: IconButton(
                      onPressed: _document == null
                          ? null
                          : () async {
                              try {
                                showLoader(context);
                                // Synchronous — no await, no Isolate
                                if (currentPrinter == null) return;

                                await PrinterHandler.printPdf(
                                  printerName: currentPrinter!,
                                  file: file!,
                                );

                                Navigator.pop(context);
                              } catch (e) {
                                Navigator.pop(context);
                                showTopSnackBar(context, message: e.toString(),color: Colors.red);
                              }
                            },
                      icon: Icon(Icons.print),
                    ),
                  ),
                  onChanged:_document == null ? null : (value) {
                    if (value != null) {
                      currentPrinter = value;
                      localStorage.setItem('CURRENT_PRINTER_PDF_VIEWER',currentPrinter.toString());
                      setState(() {});
                    }
                  },
                ),
              ),

              ToolButtonWidget(
                icon: Icons.close,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),

      body: _document == null
          ? const Center(child: CircularProgressIndicator())
          : Listener(
              onPointerSignal: _handleScroll,
              onPointerHover: _handleHover,

              child: NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  if (HardwareKeyboard.instance.isControlPressed) {
                    // Cancelar desplazamiento
                    return false; // true = consumir notificación, no se propaga
                  }
                  return true;
                },
                child: SingleChildScrollView(
                  key: _scrollKey,
                  clipBehavior: Clip.none,
                  child: PdfDocumentViewBuilder.file(
                    file?.path ?? '',
                    builder: (context, document) => Column(
                      children: List.generate(_document!.pages.length, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,

                          child: Column(
                            children: [
                              // Contenedor que aplica la matriz de zoom hacia el cursor + rotación
                              SizedBox(
                                width: newWidth,
                                child: PdfPageView(
                                  document: _document!,
                                  pageNumber: index + 1,
                                  alignment: Alignment.center,
                                  rotationOverride: _currentRotation,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

Future<T> showPdfViewer<T>(
  BuildContext context,
  File file, [
  PdfPageRotation? rotation,
]) async {
  return await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PdfViewerWidget(file: file, rotation: rotation),
    ),
  );
}
