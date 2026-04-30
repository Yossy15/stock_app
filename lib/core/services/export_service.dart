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

    // Load Thai font
    final font = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ประวัติกิจกรรมสต็อก',
                      style: pw.TextStyle(font: fontBold, fontSize: 24)),
                  pw.Text(monthStr,
                      style: pw.TextStyle(font: font, fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              cellStyle: pw.TextStyle(font: font),
              headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
              headers: [
                'วันที่',
                'เวลา',
                'สินค้า',
                'ประเภท',
                'จำนวน',
                'ยอดสุทธิ',
                'ผู้ทำรายการ'
              ],
              data: activities
                  .map((a) => [
                        DateFormat('dd/MM/yy').format(a.timestamp),
                        DateFormat('HH:mm').format(a.timestamp),
                        a.stockName,
                        _getStatusTitle(a.type),
                        a.diff > 0 ? '+${a.diff}' : '${a.diff}',
                        '${a.finalQty}',
                        a.performer,
                      ])
                  .toList(),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );
    return pdf.save();
  }

  static Future<Uint8List> generateMonthlyExcel(
      DateTime month, List<StockActivity> activities) async {
    var excel = Excel.createExcel();
    // Rename default sheet
    String sheetName = 'Activities';
    excel.rename('Sheet1', sheetName);
    Sheet sheetObject = excel[sheetName];

    final monthStr = DateFormat('MMMM yyyy', 'th_TH').format(month);

    // Styles
    CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#6C63FF'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    // Header
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

    for (var a in activities) {
      sheetObject.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy').format(a.timestamp)),
        TextCellValue(DateFormat('HH:mm').format(a.timestamp)),
        TextCellValue(a.stockName),
        TextCellValue(_getStatusTitle(a.type)),
        IntCellValue(a.diff),
        DoubleCellValue(a.price),
        IntCellValue(a.finalQty),
        TextCellValue(a.performer),
      ]);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  static String _getStatusTitle(ActivityType type) {
    switch (type) {
      case ActivityType.create:
        return 'เริ่มรายการ';
      case ActivityType.update:
        return 'แก้ไขข้อมูล';
      case ActivityType.delete:
        return 'ลบรายการ';
      case ActivityType.qtyChange:
        return 'ปรับปรุงสต็อก';
    }
  }
}
