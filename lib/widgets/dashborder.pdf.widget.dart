
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DashedBorderPdf extends pw.StatelessWidget {
  final pw.Widget child;
  final double dashWidth;
  final double dashSpace;
  final PdfColor color;
  final double strokeWidth;

  DashedBorderPdf({
    required this.child,
    this.dashWidth = 4,
    this.dashSpace = 2,
    this.color = PdfColors.black,
    this.strokeWidth = 1,
  });

  @override
  pw.Widget build(pw.Context context) {
    return pw.CustomPaint(
      painter: ( PdfGraphics canvas, PdfPoint size) {
        canvas.setStrokeColor(color);
        canvas.setLineWidth(strokeWidth);

        // Top border
        double x = 0;
        while (x < size.x) {
          canvas.drawLine(x, size.y, x + dashWidth, size.y);
          x += dashWidth + dashSpace;
        }

        // Bottom border
        x = 0;
        while (x < size.x) {
          canvas.drawLine(x, 0, x + dashWidth, 0);
          x += dashWidth + dashSpace;
        }

        // Left border
        /*double y = 0;
        while (y < size.y) {
          canvas.drawLine(0, y, 0, y + dashWidth);
          y += dashWidth + dashSpace;
        }*/

        // Right border
       /* y = 0;
        while (y < size.y) {
          canvas.drawLine(size.x, y, size.x, y + dashWidth);
          y += dashWidth + dashSpace;
        }*/

        canvas.strokePath();
      },
      child: child,
    );
  }
}
