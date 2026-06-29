import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptGenerator {
  static Future<void> generateAndShare({
    required String receiptNo,
    required String memberName,
    required String groupName,
    required double amount,
    required String paymentType,
    required String paymentMode,
    required DateTime date,
    String? organizationName,
    String? notes,
  }) async {
    final pdf = pw.Document();

    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final formattedTime =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    organizationName ?? 'Chit Fund Manager',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Payment Receipt',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 8),

                _row('Receipt No', receiptNo),
                _row('Date', formattedDate),
                _row('Time', formattedTime),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.SizedBox(height: 8),

                _row('Member Name', memberName),
                _row('Chit Group', groupName),
                _row('Payment Type', paymentType),
                _row('Payment Mode', paymentMode),
                if (notes != null && notes.isNotEmpty) _row('Notes', notes),

                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 8),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Amount Paid',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs. ${amount.toStringAsFixed(0)}',
                        style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green800)),
                  ],
                ),

                pw.SizedBox(height: 32),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'This is a system-generated receipt.',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'receipt_$receiptNo.pdf',
    );
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}