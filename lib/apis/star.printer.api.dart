
import 'dart:convert';
import 'dart:typed_data';

enum xPaperSize {
  mm58,
  mm72,
  mm80,
}

enum Align {
  left,
  center,
  right,
}

enum xFontSize {
  normal,
  doubleHeight,
  doubleWidth,
  doubleBoth,
}
xFontSize _fontSize = xFontSize.normal;

class StarLineBuilder {
  StarLineBuilder({
    this.paperSize = xPaperSize.mm80,
  });

  final xPaperSize paperSize;

  final BytesBuilder _buffer = BytesBuilder();

  int get charsPerLine {
    switch (paperSize) {
      case xPaperSize.mm58:
        return 32;

      case xPaperSize.mm72:
        return 42;

      case xPaperSize.mm80:
        return 48;
    }
  }

  Uint8List build() => _buffer.toBytes();

  void raw(List<int> bytes) {
    _buffer.add(bytes);
  }

  // =====================
  // STAR COMMANDS
  // =====================

  void init() {
    raw([0x1B, 0x40]);
  }

  void cut() {
    raw([0x1B, 0x64, 0x03]);
  }

  void feed([int lines = 3]) {
    raw([0x1B, 0x64, lines]);
  }

  void openDrawer() {
    raw([0x1B, 0x07]);
  }


void fontSize(xFontSize size) {
  _fontSize = size;

  switch (size) {
    case xFontSize.normal:
      raw([0x1B, 0x69, 0x00, 0x00]);
      break;

    case xFontSize.doubleHeight:
      raw([0x1B, 0x69, 0x00, 0x01]);
      break;

    case xFontSize.doubleWidth:
      raw([0x1B, 0x69, 0x01, 0x00]);
      break;

    case xFontSize.doubleBoth:
      raw([0x1B, 0x69, 0x01, 0x01]);
      break;
  }
}

  // =====================
  // ALIGNMENT
  // =====================

  void align(Align align) {
    switch (align) {
      case Align.left:
        raw([0x1B, 0x1D, 0x61, 0x00]);
        break;

      case Align.center:
        raw([0x1B, 0x1D, 0x61, 0x01]);
        break;

      case Align.right:
        raw([0x1B, 0x1D, 0x61, 0x02]);
        break;
    }
  }

  void left() => align(Align.left);

  void center() => align(Align.center);

  void right() => align(Align.right);

  // =====================
  // FONT STYLE
  // =====================

  void bold(bool enable) {
    raw([
      0x1B,
      enable ? 0x45 : 0x46,
    ]);
  }

  void boldOn() => bold(true);

  void boldOff() => bold(false);

  // =====================
  // TEXT
  // =====================

  void text(String text) {
    _buffer.add(utf8.encode(text));
  }

  void ln([int count = 1]) {
    for (var i = 0; i < count; i++) {
      raw([0x0A]);
    }
  }

  void println(String text) {
    this.text(text);
    ln();
  }

  void centered(String text) {
    center();
    println(text);
    left();
  }

  void rightText(String text) {
    right();
    println(text);
    left();
  }

  void boldText(String text) {
    boldOn();
    println(text);
    boldOff();
  }

  // =====================
  // DIVIDER
  // =====================

  void divider([
    String char = '-',
  ]) {
    println(
      List.filled(charsPerLine, char).join(),
    );
  }

  // =====================
  // ROW 2 COLUMNS
  // =====================

  void row(
    String leftText,
    String rightText,
  ) {
    final spaces =
        charsPerLine -
        leftText.length -
        rightText.length;

    println(
      leftText +
          List.filled(
            spaces > 0 ? spaces : 1,
            ' ',
          ).join() +
          rightText,
    );
  }

  // =====================
  // ROW 3 COLUMNS
  // 60% | 15% | 25%
  // =====================

  void row3(
    String col1,
    String col2,
    String col3,
  ) {
    final w1 = (charsPerLine * 0.60).floor();
    final w2 = (charsPerLine * 0.15).floor();
    final w3 = charsPerLine - w1 - w2;

    final c1 = col1.length > w1
        ? col1.substring(0, w1)
        : col1.padRight(w1);

    final c2 = col2.length > w2
        ? col2.substring(0, w2)
        : col2.padLeft(w2);

    final c3 = col3.length > w3
        ? col3.substring(0, w3)
        : col3.padLeft(w3);

    println('$c1$c2$c3');
  }

  // =====================
  // ITEM
  // =====================

  void item({
    required String description,
    required num qty,
    required num total,
  }) {
    row3(
      description,
      qty.toString(),
      total.toStringAsFixed(2),
    );
  }

  // =====================
  // TOTAL
  // =====================

  void total(
    String label,
    num value,
  ) {
    boldOn();

    row(
      label,
      value.toStringAsFixed(2),
    );

    boldOff();
  }
}
