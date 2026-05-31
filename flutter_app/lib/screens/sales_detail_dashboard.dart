import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../config/theme.dart';
import '../widgets/common_widgets.dart';

class SalesDetailDashboard extends StatelessWidget {
  final String restaurantName;
  final String saleDate;
  final double totalRevenue;
  final List<dynamic> items;

  const SalesDetailDashboard({
    super.key,
    required this.restaurantName,
    required this.saleDate,
    required this.totalRevenue,
    required this.items,
  });

  Future<void> _generatePDF() async {
    final pdf = pw.Document(
      title: '$restaurantName Sales Report - $saleDate',
      author: 'SmartMenu',
      subject: 'Daily sales performance report',
    );

    final totalQuantity = _totalQuantity();
    final avgRevenue = totalQuantity == 0 ? 0.0 : totalRevenue / totalQuantity;
    final generatedAt = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(DateTime.now());
    final rows = _pdfItemRows();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 34, 36, 40),
        header: (context) => _pdfHeader(context),
        footer: (context) => _pdfFooter(context, generatedAt),
        build: (context) => [
          pw.SizedBox(height: 18),
          pw.Text(
            restaurantName,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Daily Sales Report',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey700,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Sales date: ${_displayReportDate(saleDate)}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.blueGrey600,
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              _pdfMetricCard('Total Revenue', _formatPdfMoney(totalRevenue)),
              pw.SizedBox(width: 10),
              _pdfMetricCard('Items Sold', _formatPdfNumber(totalQuantity)),
              pw.SizedBox(width: 10),
              _pdfMetricCard('Avg Revenue / Item', _formatPdfMoney(avgRevenue)),
              pw.SizedBox(width: 10),
              _pdfMetricCard('Dishes', _formatPdfNumber(items.length)),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Items Breakdown',
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.Text(
                '${rows.length} line items',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.blueGrey500,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          _pdfItemsTable(rows),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _pdfHeader(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blueGrey100, width: 0.7),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            restaurantName,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.Text(
            'SmartMenu Sales Report',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.blueGrey500,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfFooter(pw.Context context, String generatedAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.blueGrey100, width: 0.7),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated $generatedAt',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.blueGrey500,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.blueGrey500,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfMetricCard(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: pw.BoxDecoration(
          color: PdfColors.blueGrey50,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: PdfColors.blueGrey100, width: 0.7),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey500,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfItemsTable(List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      headers: const ['#', 'Dish', 'Qty', 'Revenue', 'Avg / Item'],
      data: rows,
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(
          color: PdfColors.blueGrey100,
          width: 0.45,
        ),
        bottom: const pw.BorderSide(color: PdfColors.blueGrey200, width: 0.7),
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 8.5,
        fontWeight: pw.FontWeight.bold,
      ),
      headerHeight: 24,
      cellHeight: 24,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      cellStyle: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      columnWidths: const {
        0: pw.FixedColumnWidth(28),
        1: pw.FlexColumnWidth(3.2),
        2: pw.FixedColumnWidth(52),
        3: pw.FixedColumnWidth(92),
        4: pw.FixedColumnWidth(78),
      },
      headerAlignments: const {
        0: pw.Alignment.centerRight,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      cellAlignments: const {
        0: pw.Alignment.centerRight,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
    );
  }

  List<List<String>> _pdfItemRows() {
    return items.asMap().entries.map((entry) {
      final row = entry.value is Map ? entry.value as Map : const {};
      final dishName =
          row['dish_name']?.toString() ?? 'Dish #${row['dish_id'] ?? 'N/A'}';
      final quantity = (row['quantity_sold'] as num?)?.toInt() ?? 0;
      final revenue = (row['revenue'] as num?)?.toDouble() ?? 0;
      final avgRevenue = quantity == 0 ? 0.0 : revenue / quantity;

      return [
        (entry.key + 1).toString(),
        dishName,
        _formatPdfNumber(quantity),
        _formatPdfMoney(revenue),
        _formatPdfMoney(avgRevenue),
      ];
    }).toList();
  }

  String _formatPdfMoney(num value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'INR ',
      decimalDigits: 2,
    ).format(value);
  }

  String _formatPdfNumber(num value) {
    return NumberFormat.decimalPattern('en_IN').format(value);
  }

  String _displayReportDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  int _totalQuantity() {
    return items.fold<int>(0, (sum, item) {
      final row = item is Map ? item : const {};
      return sum + ((row['quantity_sold'] as num?)?.toInt() ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalQuantity = _totalQuantity();
    final avgRevenue = totalQuantity == 0 ? 0.0 : totalRevenue / totalQuantity;

    return Scaffold(
      appBar: SmartTopBar(
        title: 'Sales Detail',
        showBack: true,
        onLogout: null,
      ),
      body: SmartPage(
        title: 'Sales Dashboard',
        subtitle: saleDate,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        trailing: IconButton.filled(
          onPressed: _generatePDF,
          icon: const Icon(Icons.file_download_outlined),
          tooltip: 'Download PDF',
        ),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                MetricCard(
                  label: 'Total Revenue',
                  value: formatMoney(totalRevenue),
                  icon: Icons.payments_outlined,
                ),
                MetricCard(
                  label: 'Items Sold',
                  value: totalQuantity.toString(),
                  icon: Icons.shopping_cart_outlined,
                ),
                MetricCard(
                  label: 'Avg per Item',
                  value: formatMoney(avgRevenue),
                  icon: Icons.trending_up,
                ),
                MetricCard(
                  label: 'Dishes',
                  value: items.length.toString(),
                  icon: Icons.restaurant_menu,
                ),
              ];
              if (constraints.maxWidth < 760) {
                return Column(
                  children: cards
                      .expand((card) => [card, const SizedBox(height: 12)])
                      .toList(),
                );
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: card,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          SmartCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items Breakdown',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Dish')),
                      DataColumn(label: Text('Quantity')),
                      DataColumn(label: Text('Revenue'), numeric: true),
                    ],
                    rows: items.map((item) {
                      final row = item is Map ? item : const {};
                      final dishName =
                          row['dish_name']?.toString() ??
                          'Dish #${row['dish_id'] ?? 'N/A'}';
                      final qty = row['quantity_sold']?.toString() ?? '0';
                      final rev = (row['revenue'] as num?)?.toDouble() ?? 0;
                      return DataRow(
                        cells: [
                          DataCell(Text(dishName)),
                          DataCell(Text(qty)),
                          DataCell(Text(formatMoney(rev))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _generatePDF,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Download PDF Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
