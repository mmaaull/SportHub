  import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/booking_model.dart';
import '../utils/date_formatter.dart';

class ReceiptService {
  Future<Uint8List> generateReceiptPdf(BookingModel booking) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(36),
        ),
        build: (context) {
          return [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildTitle(),
            pw.SizedBox(height: 18),
            _buildReceiptInfo(booking),
            pw.SizedBox(height: 20),
            _buildBookingTable(booking),
            pw.SizedBox(height: 24),
            _buildStatement(),
            pw.SizedBox(height: 38),
            _buildSignature(booking),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> previewReceipt(BookingModel booking) async {
    final fileName = 'Surat_Tanda_Terima_${booking.receiptNumber}.pdf';

    await Printing.layoutPdf(
      name: fileName,
      onLayout: (PdfPageFormat format) async {
        return generateReceiptPdf(booking);
      },
    );
  }

  Future<void> shareReceipt(BookingModel booking) async {
    final bytes = await generateReceiptPdf(booking);

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Surat_Tanda_Terima_${booking.receiptNumber}.pdf',
    );
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      children: [
        pw.Text(
          'UNIVERSITAS NEGERI SURABAYA',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'UNESA SportHub',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Sistem Informasi dan Booking Fasilitas Olahraga',
          style: const pw.TextStyle(
            fontSize: 11,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 1.2),
      ],
    );
  }

  pw.Widget _buildTitle() {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'SURAT TANDA TERIMA BOOKING',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Fasilitas Olahraga Universitas Negeri Surabaya',
            style: const pw.TextStyle(
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReceiptInfo(BookingModel booking) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          _buildInfoRow('Nomor Tanda Terima', booking.receiptNumber),
          _buildInfoRow(
            'Tanggal Terbit',
            booking.receiptCreatedAt == null
                ? '-'
                : DateFormatter.formatDateTime(booking.receiptCreatedAt!),
          ),
          _buildInfoRow('Status Booking', 'APPROVED'),
        ],
      ),
    );
  }

  pw.Widget _buildBookingTable(BookingModel booking) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey500),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(4),
      },
      children: [
        _buildTableRow('Nama Mahasiswa', booking.userName),
        _buildTableRow('NIM', booking.userNim),
        _buildTableRow('Fasilitas', booking.facilityName),
        _buildTableRow('Jenis Olahraga', booking.sportType),
        _buildTableRow('Kampus', booking.campus),
        _buildTableRow('Tanggal Booking', DateFormatter.formatDayDate(booking.date)),
        _buildTableRow('Waktu Booking', '${booking.startTime} - ${booking.endTime}'),
        _buildTableRow('Jumlah Peserta', '${booking.participantCount} peserta'),
        _buildTableRow('Tujuan Booking', booking.purpose),
        _buildTableRow(
          'Catatan',
          booking.note.trim().isEmpty ? '-' : booking.note,
        ),
      ],
    );
  }

  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: PdfColors.grey200,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            ': ',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatement() {
    return pw.Text(
      'Surat tanda terima ini diterbitkan secara otomatis oleh sistem UNESA SportHub '
      'sebagai bukti bahwa pengajuan booking fasilitas olahraga telah disetujui oleh admin. '
      'Pengguna wajib menggunakan fasilitas sesuai jadwal dan ketentuan yang berlaku.',
      textAlign: pw.TextAlign.justify,
      style: const pw.TextStyle(
        fontSize: 10,
        lineSpacing: 4,
      ),
    );
  }

  pw.Widget _buildSignature(BookingModel booking) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'Surabaya, ${booking.receiptCreatedAt == null ? '-' : DateFormatter.formatDate(booking.receiptCreatedAt!)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Admin Pengelola',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 50),
          pw.Text(
            booking.approvedByName.isEmpty ? 'Admin UNESA SportHub' : booking.approvedByName,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}