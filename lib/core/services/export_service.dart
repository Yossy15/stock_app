import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/stock/providers/stock_provider.dart';

class ExportService {
  static Future<Uint8List> generateMonthlyPdf(
      DateTime month, List<StockActivity> activities) async {
    final pdf = pw.Document();
    final monthStr = DateFormat('MMMM yyyy', 'th_TH').format(month);
    final printDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final font = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();

    int totalIn = 0;
    int totalOut = 0;
    for (var a in activities) {
      if (a.diff > 0) totalIn += a.diff;
      if (a.diff < 0) totalOut += a.diff.abs();
    }

    final Map<String, List<StockActivity>> groupedActivities = {};
    for (var a in activities) {
      final dateKey = DateFormat('dd/MM/yyyy').format(a.timestamp.toLocal());
      groupedActivities.putIfAbsent(dateKey, () => []).add(a);
    }
    final sortedDates = groupedActivities.keys.toList()
      ..sort((a, b) => DateFormat('dd/MM/yyyy')
          .parse(b)
          .compareTo(DateFormat('dd/MM/yyyy').parse(a)));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Text('พิมพ์เมื่อ: $printDate',
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey700)),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text('หน้า ${context.pageNumber} จาก ${context.pagesCount}',
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey700)),
        ),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('รายงานสรุปการเคลื่อนไหวสต็อก',
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 28,
                            color: PdfColors.indigo900)),
                    pw.Text('ประจำเดือน $monthStr',
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 16,
                            color: PdfColors.grey800)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.indigo50,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Text('STOCK REPORT',
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 12,
                          color: PdfColors.indigo700)),
                ),
              ],
            ),
            pw.SizedBox(height: 32),
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('ยอดเพิ่มรวม', '+$totalIn',
                      PdfColors.green700, font, fontBold),
                  pw.Container(width: 1, height: 40, color: PdfColors.grey300),
                  _buildSummaryItem('ยอดเบิกรวม', '-$totalOut',
                      PdfColors.red700, font, fontBold),
                  // pw.Container(width: 1, height: 40, color: PdfColors.grey300),
                  // _buildSummaryItem('รายการทั้งหมด', '${activities.length}', PdfColors.indigo700, font, fontBold),
                ],
              ),
            ),
            pw.SizedBox(height: 40),
            ...sortedDates.expand((date) {
              final dateActivities = groupedActivities[date]!;
              return [
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12, top: 8),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.indigo900,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text('วันที่ $date',
                          style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 14,
                              color: PdfColors.white)),
                      pw.Spacer(),
                      pw.Text('${dateActivities.length} รายการ',
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 12,
                              color: PdfColors.indigo100)),
                    ],
                  ),
                ),
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(45),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FixedColumnWidth(55),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FixedColumnWidth(55),
                    5: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                            bottom: pw.BorderSide(
                                color: PdfColors.grey300, width: 0.5)),
                      ),
                      children: [
                        _buildTableHeader('เวลา', fontBold),
                        _buildTableHeader('สินค้า', fontBold),
                        _buildTableHeader('ประเภท', fontBold,
                            alignment: pw.Alignment.center),
                        _buildTableHeader('จำนวน', fontBold,
                            alignment: pw.Alignment.centerRight),
                        _buildTableHeader('คงเหลือ', fontBold,
                            alignment: pw.Alignment.centerRight),
                        _buildTableHeader('ผู้ทำรายการ', fontBold,
                            alignment: pw.Alignment.centerRight),
                      ],
                    ),
                    ...dateActivities.map((a) {
                      final isIn = a.diff > 0;
                      final color =
                          isIn ? PdfColors.green700 : PdfColors.red700;
                      final bgColor =
                          isIn ? PdfColors.green50 : PdfColors.red50;
                      final typeText = isIn ? 'เพิ่ม' : 'เบิก';
                      final symbol = isIn ? '+' : '-';

                      return pw.TableRow(
                        children: [
                          _buildTableCell(
                              DateFormat('HH:mm').format(a.timestamp.toLocal()),
                              font),
                          _buildTableCell(a.stockName, font),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                vertical: 6, horizontal: 4),
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: bgColor,
                                borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(4)),
                              ),
                              child: pw.Center(
                                child: pw.Text(typeText,
                                    style: pw.TextStyle(
                                        font: font,
                                        fontSize: 10,
                                        color: color)),
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            child: pw.Container(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text('$symbol${a.diff.abs()}',
                                  style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 11,
                                      color: color)),
                            ),
                          ),
                          _buildTableCell('${a.finalQty}', font,
                              alignment: pw.Alignment.centerRight,
                              fontSize: 11),
                          _buildTableCell(a.performer, font,
                              fontSize: 10,
                              color: PdfColors.grey700,
                              alignment: pw.Alignment.centerRight),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 24),
              ];
            }),
          ];
        },
      ),
    );
    return pdf.save();
  }

  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color,
      pw.Font font, pw.Font fontBold) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                font: font, fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(font: fontBold, fontSize: 20, color: color)),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text, pw.Font fontBold,
      {pw.Alignment alignment = pw.Alignment.centerLeft}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Container(
        alignment: alignment,
        child: pw.Text(text,
            style: pw.TextStyle(
                font: fontBold, fontSize: 11, color: PdfColors.grey900)),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, pw.Font font,
      {double fontSize = 11,
      PdfColor color = PdfColors.black,
      pw.Alignment alignment = pw.Alignment.centerLeft}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Container(
        alignment: alignment,
        child: pw.Text(text,
            style: pw.TextStyle(font: font, fontSize: fontSize, color: color)),
      ),
    );
  }

  static Future<Uint8List> generateMonthlyExcel(
      DateTime month, List<StockActivity> activities) async {
    var excel = Excel.createExcel();
    String sheetName = 'Activities';
    excel.rename('Sheet1', sheetName);
    Sheet sheetObject = excel[sheetName];

    final monthStr = DateFormat('MMMM yyyy', 'th_TH').format(month);

    CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#6C63FF'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      fontFamily: 'TH Sarabun New',
      fontSize: 14,
    );

    CellStyle dataStyle = CellStyle(fontFamily: 'TH Sarabun New', fontSize: 12);

    sheetObject.appendRow([TextCellValue('ประวัติกิจกรรมสต็อก - $monthStr')]);
    sheetObject.appendRow([
      TextCellValue('วันที่'),
      TextCellValue('เวลา'),
      TextCellValue('สินค้า'),
      TextCellValue('ประเภท'),
      TextCellValue('จำนวน'),
      TextCellValue('ราคา'),
      TextCellValue('ยอดสุทธิ'),
      TextCellValue('ผู้ทำรายการ')
    ]);

    for (int i = 0; i < 8; i++) {
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
          .cellStyle = headerStyle;
    }

    for (var a in activities) {
      sheetObject.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy').format(a.timestamp.toLocal())),
        TextCellValue(DateFormat('HH:mm').format(a.timestamp.toLocal())),
        TextCellValue(a.stockName),
        TextCellValue(_getStatusTitle(a)),
        IntCellValue(a.diff.abs()),
        DoubleCellValue(a.price),
        IntCellValue(a.finalQty),
        TextCellValue(a.performer),
      ]);

      int lastRow = sheetObject.maxRows - 1;
      for (int i = 0; i < 8; i++) {
        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: lastRow))
            .cellStyle = dataStyle;
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  static String _getStatusTitle(StockActivity activity) {
    if (activity.type == ActivityType.create || activity.diff > 0) {
      return 'เพิ่มสินค้า';
    } else if (activity.type == ActivityType.delete || activity.diff < 0) {
      return 'เบิกสินค้า';
    }
    return 'แก้ไขข้อมูล';
  }
}
