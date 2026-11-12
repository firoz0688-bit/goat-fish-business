import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class PdfReportService {
  static Future<void> generateFinancialReport({
    required DashboardSummary summary,
    required List<TransactionModel> transactions,
    required List<Investor> investors,
    required Map<String, double> investorTotals,
    required String currency,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('GOAT & FISH FARMING BUSINESS',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                    pw.SizedBox(height: 4),
                    pw.Text('Financial Statement & Partner Ledger',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text('Generated: $dateStr', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.green900),
            pw.SizedBox(height: 12),

            pw.Text('EXECUTIVE SUMMARY', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.green50),
                  children: [
                    _cell('Total Business Investment', isBold: true),
                    _cell('$currency ${summary.totalInvestment.toStringAsFixed(2)}', isBold: true),
                    _cell('Available Balance', isBold: true),
                    _cell('$currency ${summary.remainingBalance.toStringAsFixed(2)}', isBold: true),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _cell('Total Expenses'),
                    _cell('$currency ${summary.totalExpense.toStringAsFixed(2)}'),
                    _cell('Total Income'),
                    _cell('$currency ${summary.totalIncome.toStringAsFixed(2)}'),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _cell('Net Profit / Loss', isBold: true),
                    _cell('$currency ${summary.netProfitLoss.toStringAsFixed(2)}', isBold: true),
                    _cell('Goat / Fish Investments'),
                    _cell('G: $currency${summary.goatInvestment.toInt()} | F: $currency${summary.fishInvestment.toInt()}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            pw.Text('INVESTOR CONTRIBUTION SUMMARY', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
              headers: ['Partner Name', 'Phone', 'Status', 'Total Invested ($currency)'],
              data: investors.map((inv) {
                final total = investorTotals[inv.id] ?? 0.0;
                return [
                  inv.name,
                  inv.phone.isEmpty ? '-' : inv.phone,
                  inv.isActive == 1 ? 'Active' : 'Inactive',
                  total.toStringAsFixed(2),
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Goat_Fish_Farming_Report.pdf',
    );
  }

  static pw.Widget _cell(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }
}
