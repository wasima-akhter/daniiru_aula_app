import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../service/language/language_provider.dart';

/// Helper to generate pure-Dart compliant PDF-1.4 documents for payment receipts.
/// Embeds the official Aula360 logo (assets/images/app_logo.png) with alpha mask transparency,
/// structured executive layout, and clear non-repeating organization according to the selected language.
abstract final class ReceiptPdfBuilder {
  static int? _cachedLogoWidth;
  static int? _cachedLogoHeight;
  static List<int>? _cachedCompressedRgb;
  static List<int>? _cachedCompressedAlpha;

  /// Asynchronously decodes and caches the official app logo (assets/images/app_logo.png),
  /// then builds a high-fidelity PDF-1.4 payment receipt localized according to [languageCode].
  static Future<Uint8List> generate({
    required String invoiceNumber,
    required String studentName,
    required String studentDetails,
    required String period,
    required String date,
    required String paymentMethod,
    required String amount,
    required String status,
    String? languageCode,
    Uint8List? preloadedLogoBytes,
  }) async {
    int? logoWidth = _cachedLogoWidth;
    int? logoHeight = _cachedLogoHeight;
    List<int>? compressedRgb = _cachedCompressedRgb;
    List<int>? compressedAlpha = _cachedCompressedAlpha;

    if (compressedRgb == null) {
      Uint8List? rawLogoBytes = preloadedLogoBytes;
      if (rawLogoBytes == null || rawLogoBytes.isEmpty) {
        try {
          final f = File('assets/images/app_logo.png');
          if (f.existsSync()) {
            rawLogoBytes = await f.readAsBytes();
          }
        } catch (_) {}
        if (rawLogoBytes == null || rawLogoBytes.isEmpty) {
          try {
            final byteData = await rootBundle.load('assets/images/app_logo.png');
            rawLogoBytes = byteData.buffer.asUint8List();
          } catch (_) {}
        }
      }

      if (rawLogoBytes != null && rawLogoBytes.isNotEmpty) {
        try {
          final codec = await ui.instantiateImageCodec(
            rawLogoBytes,
            targetWidth: 380,
          );
          final frame = await codec.getNextFrame();
          final img = frame.image;
          final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);

          if (byteData != null) {
            logoWidth = img.width;
            logoHeight = img.height;
            final rgba = byteData.buffer.asUint8List();

            final rgb = Uint8List(logoWidth * logoHeight * 3);
            final alpha = Uint8List(logoWidth * logoHeight);

            int rgbIdx = 0;
            int aIdx = 0;
            for (int i = 0; i < rgba.length; i += 4) {
              rgb[rgbIdx++] = rgba[i];
              rgb[rgbIdx++] = rgba[i + 1];
              rgb[rgbIdx++] = rgba[i + 2];
              alpha[aIdx++] = rgba[i + 3];
            }

            compressedRgb = zlib.encode(rgb);
            compressedAlpha = zlib.encode(alpha);

            _cachedLogoWidth = logoWidth;
            _cachedLogoHeight = logoHeight;
            _cachedCompressedRgb = compressedRgb;
            _cachedCompressedAlpha = compressedAlpha;
          }
        } catch (_) {}
      }
    }

    return _buildPdf(
      invoiceNumber: invoiceNumber,
      studentName: studentName,
      studentDetails: studentDetails,
      period: period,
      date: date,
      paymentMethod: paymentMethod,
      amount: amount,
      status: status,
      languageCode: languageCode,
      logoWidth: logoWidth,
      logoHeight: logoHeight,
      compressedRgb: compressedRgb,
      compressedAlpha: compressedAlpha,
    );
  }

  /// Synchronous fallback when async image decoding is not available.
  static Uint8List generateSync({
    required String invoiceNumber,
    required String studentName,
    required String studentDetails,
    required String period,
    required String date,
    required String paymentMethod,
    required String amount,
    required String status,
    String? languageCode,
  }) {
    return _buildPdf(
      invoiceNumber: invoiceNumber,
      studentName: studentName,
      studentDetails: studentDetails,
      period: period,
      date: date,
      paymentMethod: paymentMethod,
      amount: amount,
      status: status,
      languageCode: languageCode,
      logoWidth: _cachedLogoWidth,
      logoHeight: _cachedLogoHeight,
      compressedRgb: _cachedCompressedRgb,
      compressedAlpha: _cachedCompressedAlpha,
    );
  }

  static Uint8List _buildPdf({
    required String invoiceNumber,
    required String studentName,
    required String studentDetails,
    required String period,
    required String date,
    required String paymentMethod,
    required String amount,
    required String status,
    String? languageCode,
    int? logoWidth,
    int? logoHeight,
    List<int>? compressedRgb,
    List<int>? compressedAlpha,
  }) {
    final effectiveLang = languageCode ?? LanguageNotifier.activeLanguageCode;
    final isEs = effectiveLang.toLowerCase().startsWith('es');

    final hasLogo = logoWidth != null &&
        logoHeight != null &&
        compressedRgb != null &&
        compressedAlpha != null;

    final objects = <int, List<int>>{};

    // 1: Catalog
    objects[1] = '/Type /Catalog /Pages 2 0 R'.codeUnits;
    // 2: Pages
    objects[2] = '/Type /Pages /Kids [3 0 R] /Count 1'.codeUnits;

    // 3: Page (Standard A4: 595 x 842 pt)
    final resourceDict = hasLogo
        ? '/Resources << /Font << /F1 5 0 R /F2 6 0 R >> /XObject << /ImLogo 7 0 R >> >>'
        : '/Resources << /Font << /F1 5 0 R /F2 6 0 R >> >>';
    objects[3] =
        '/Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R $resourceDict'
            .codeUnits;

    // 5: Font Helvetica-Bold with WinAnsiEncoding
    objects[5] =
        '/Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding'
            .codeUnits;
    // 6: Font Helvetica with WinAnsiEncoding
    objects[6] =
        '/Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding'
            .codeUnits;

    if (hasLogo) {
      // 7: Logo Image XObject
      final imgDict =
          '<< /Type /XObject /Subtype /Image /Width $logoWidth /Height $logoHeight /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode /SMask 8 0 R /Length ${compressedRgb.length} >>\nstream\n';
      final imgPost = '\nendstream';
      objects[7] = [
        ...imgDict.codeUnits,
        ...compressedRgb,
        ...imgPost.codeUnits,
      ];

      // 8: Logo Alpha Mask XObject
      final alphaDict =
          '<< /Type /XObject /Subtype /Image /Width $logoWidth /Height $logoHeight /ColorSpace /DeviceGray /BitsPerComponent 8 /Filter /FlateDecode /Length ${compressedAlpha.length} >>\nstream\n';
      final alphaPost = '\nendstream';
      objects[8] = [
        ...alphaDict.codeUnits,
        ...compressedAlpha,
        ...alphaPost.codeUnits,
      ];
    }

    final sb = StringBuffer();

    void text(
      String str,
      double x,
      double y, {
      bool bold = false,
      double size = 10,
      double r = 0.1,
      double g = 0.1,
      double b = 0.1,
    }) {
      final font = bold ? '/F1' : '/F2';
      sb.writeln(
        'BT $font $size Tf $r $g $b rg $x $y Td (${_clean(str)}) Tj ET',
      );
    }

    // 1. Header (Y = 730 to 805)
    if (hasLogo) {
      const drawImgWidth = 118.0;
      final drawImgHeight = drawImgWidth * (logoHeight / logoWidth);
      const logoX = 45.0;
      final logoY = 795.0 - drawImgHeight;
      sb.writeln('q');
      sb.writeln('$drawImgWidth 0 0 $drawImgHeight $logoX $logoY cm');
      sb.writeln('/ImLogo Do');
      sb.writeln('Q');
      text(
        isEs
            ? 'CENTRO EDUCATIVO & GESTION ACADEMICA'
            : 'EDUCATIONAL CENTER & ACADEMIC MANAGEMENT',
        45,
        logoY - 12,
        size: 8,
        r: 0.45,
        g: 0.50,
        b: 0.58,
      );
    } else {
      text('AULA 360', 45, 768, bold: true, size: 22, r: 0.07, g: 0.21, b: 0.47);
      text(
        isEs
            ? 'CENTRO EDUCATIVO & GESTION ACADEMICA'
            : 'EDUCATIONAL CENTER & ACADEMIC MANAGEMENT',
        45,
        752,
        size: 8.5,
        r: 0.45,
        g: 0.50,
        b: 0.58,
      );
    }

    text(
      isEs ? 'COMPROBANTE DE PAGO' : 'OFFICIAL PAYMENT RECEIPT',
      330,
      782,
      bold: true,
      size: 14,
      r: 0.07,
      g: 0.21,
      b: 0.47,
    );
    text(
      isEs ? 'N. Recibo: $invoiceNumber' : 'Receipt No.: $invoiceNumber',
      330,
      767,
      bold: true,
      size: 9.5,
      r: 0.20,
      g: 0.25,
      b: 0.35,
    );
    text(
      isEs ? 'Fecha de emision: $date' : 'Issue Date: $date',
      330,
      754,
      size: 8.5,
      r: 0.45,
      g: 0.50,
      b: 0.58,
    );
    text(
      isEs ? 'Curso academico: $period' : 'Academic Period: $period',
      330,
      742,
      size: 8.5,
      r: 0.45,
      g: 0.50,
      b: 0.58,
    );

    // Divider line
    sb.writeln('q 0.85 0.88 0.92 RG 0.8 w 45 726 m 550 726 l S Q');

    // 2. Hero Summary Box (Y = 640 to 715, Height = 75)
    sb.writeln('q 0.97 0.98 0.99 rg 45 640 505 75 re f Q');
    sb.writeln('q 0.82 0.86 0.92 RG 0.8 w 45 640 505 75 re S Q');
    sb.writeln('q 0.07 0.21 0.47 rg 45 640 4 75 re f Q');

    text(
      isEs ? 'CONCEPTO PRINCIPAL' : 'MAIN CONCEPT',
      58,
      693,
      bold: true,
      size: 8.5,
      r: 0.40,
      g: 0.46,
      b: 0.56,
    );
    text(
      isEs
          ? 'Cuota Escolar y Servicios Educativos'
          : 'Tuition & Educational Services',
      58,
      676,
      bold: true,
      size: 12.5,
      r: 0.06,
      g: 0.09,
      b: 0.16,
    );
    text(
      isEs
          ? 'Centro Educativo Aula 360 - Pasarela Oficial de Pagos'
          : 'Aula 360 Academy - Official Payment Gateway',
      58,
      661,
      size: 9,
      r: 0.35,
      g: 0.40,
      b: 0.48,
    );

    // Emerald Status Badge
    sb.writeln('q 0.90 0.98 0.94 rg 415 684 120 20 re f Q');
    sb.writeln('q 0.06 0.72 0.51 RG 0.8 w 415 684 120 20 re S Q');
    text(status, 423, 690, bold: true, size: 8.5, r: 0.02, g: 0.47, b: 0.34);

    // Total Amount
    text(amount, 380, 655, bold: true, size: 20, r: 0.07, g: 0.21, b: 0.47);

    // 3. Two Organized Detail Panels (Y = 490 to 622, Height = 132)
    // Left Panel: Student Information
    sb.writeln('q 1 1 1 rg 45 490 245 132 re f Q');
    sb.writeln('q 0.85 0.88 0.92 RG 0.8 w 45 490 245 132 re S Q');
    sb.writeln('q 0.94 0.96 0.98 rg 45 597 245 25 re f Q');
    text(
      isEs ? 'DATOS DEL ALUMNO' : 'STUDENT INFORMATION',
      57,
      605,
      bold: true,
      size: 9,
      r: 0.07,
      g: 0.21,
      b: 0.47,
    );

    text(
      isEs ? 'Nombre completo:' : 'Full Name:',
      57,
      578,
      size: 8,
      r: 0.45,
      g: 0.50,
      b: 0.58,
    );
    text(
      studentName,
      57,
      563,
      bold: true,
      size: 10.5,
      r: 0.08,
      g: 0.12,
      b: 0.20,
    );

    text(
      isEs ? 'Curso y Grupo:' : 'Grade & Classroom:',
      57,
      542,
      size: 8,
      r: 0.45,
      g: 0.50,
      b: 0.58,
    );
    final detailsText = studentDetails.isNotEmpty
        ? studentDetails
        : (isEs ? 'Matriculado en Aula 360' : 'Enrolled in Aula 360');
    text(detailsText, 57, 529, size: 9.5, r: 0.15, g: 0.20, b: 0.28);

    text(
      isEs ? 'Periodo Lectivo:' : 'Academic Period:',
      57,
      509,
      size: 8,
      r: 0.45,
      g: 0.50,
      b: 0.58,
    );
    text(period, 125, 509, bold: true, size: 9, r: 0.15, g: 0.20, b: 0.28);

    // Right Panel: Transaction Details
    sb.writeln('q 1 1 1 rg 305 490 245 132 re f Q');
    sb.writeln('q 0.85 0.88 0.92 RG 0.8 w 305 490 245 132 re S Q');
    sb.writeln('q 0.94 0.96 0.98 rg 305 597 245 25 re f Q');
    text(
      isEs ? 'DETALLES DE LA TRANSACCION' : 'TRANSACTION DETAILS',
      317,
      605,
      bold: true,
      size: 9,
      r: 0.07,
      g: 0.21,
      b: 0.47,
    );

    text(
      isEs ? 'Metodo de pago:' : 'Payment Method:',
      317,
      578,
      size: 8,
      r: 0.45,
      g: 0.50,
      b: 0.58,
    );
    final payMethodText = paymentMethod.isNotEmpty ? paymentMethod : 'Stripe';
    text(
      payMethodText,
      317,
      563,
      bold: true,
      size: 10.5,
      r: 0.08,
      g: 0.12,
      b: 0.20,
    );

    text(
      isEs ? 'Fecha y hora de liquidacion:' : 'Settlement Date & Time:',
      317,
      542,
      size: 8,
      r: 0.45,
      g: 0.50,
      b: 0.58,
    );
    text(date, 317, 529, size: 9.5, r: 0.15, g: 0.20, b: 0.28);

    text(
      isEs ? 'Referencia:' : 'Reference:',
      317,
      509,
      size: 8,
      r: 0.45,
      g: 0.50,
      b: 0.58,
    );
    text(invoiceNumber, 375, 509, bold: true, size: 9, r: 0.15, g: 0.20, b: 0.28);

    // 4. Breakdown Table (Y = 320 to 468, Height = 148)
    sb.writeln('q 1 1 1 rg 45 320 505 148 re f Q');
    sb.writeln('q 0.85 0.88 0.92 RG 0.8 w 45 320 505 148 re S Q');
    sb.writeln('q 0.07 0.21 0.47 rg 45 443 505 25 re f Q');

    text(
      isEs ? 'DESCRIPCION / CONCEPTO' : 'DESCRIPTION / CONCEPT',
      60,
      451,
      bold: true,
      size: 8.5,
      r: 1,
      g: 1,
      b: 1,
    );
    text(
      isEs ? 'PERIODO' : 'PERIOD',
      330,
      451,
      bold: true,
      size: 8.5,
      r: 1,
      g: 1,
      b: 1,
    );
    text(
      isEs ? 'IMPORTE' : 'AMOUNT',
      475,
      451,
      bold: true,
      size: 8.5,
      r: 1,
      g: 1,
      b: 1,
    );

    // Item row
    text(
      isEs
          ? 'Cuota Academica - Servicios Educativos'
          : 'Academic Tuition - Educational Services',
      60,
      417,
      bold: true,
      size: 9.5,
      r: 0.08,
      g: 0.12,
      b: 0.20,
    );
    text(
      isEs
          ? 'Ensenanza reglada, evaluacion y plataforma Aula 360'
          : 'Curricular education, assessment, and Aula 360 platform',
      60,
      403,
      size: 8,
      r: 0.45,
      g: 0.50,
      b: 0.58,
    );
    text(period, 330, 417, size: 9, r: 0.20, g: 0.25, b: 0.35);
    text(amount, 475, 417, bold: true, size: 10, r: 0.08, g: 0.12, b: 0.20);

    // Divider
    sb.writeln('q 0.90 0.92 0.95 RG 0.6 w 45 388 m 550 388 l S Q');

    // Subtotal row
    text(
      isEs ? 'Base imponible / Subtotal:' : 'Tax Base / Subtotal:',
      330,
      370,
      size: 8.5,
      r: 0.45,
      g: 0.50,
      b: 0.58,
    );
    text(amount, 475, 370, size: 9, r: 0.20, g: 0.25, b: 0.35);

    // Tax row
    text(
      isEs ? 'Impuestos (IVA / Tasas):' : 'Taxes (VAT / Fees):',
      330,
      353,
      size: 8.5,
      r: 0.45,
      g: 0.50,
      b: 0.58,
    );
    text(
      isEs ? '0,00 EUR (Exento)' : '0.00 EUR (Exempt)',
      475,
      353,
      size: 8,
      r: 0.45,
      g: 0.50,
      b: 0.58,
    );

    // Total banner
    sb.writeln('q 0.95 0.97 1.0 rg 45 320 505 24 re f Q');
    sb.writeln('q 0.82 0.86 0.92 RG 0.6 w 45 344 m 550 344 l S Q');
    text(
      isEs ? 'TOTAL LIQUIDADO:' : 'TOTAL SETTLED:',
      330,
      327,
      bold: true,
      size: 9.5,
      r: 0.07,
      g: 0.21,
      b: 0.47,
    );
    text(amount, 475, 327, bold: true, size: 11, r: 0.07, g: 0.21, b: 0.47);

    // 5. Security Notice (Y = 220 to 295, Height = 75)
    sb.writeln('q 0.94 0.99 0.96 rg 45 220 505 75 re f Q');
    sb.writeln('q 0.65 0.92 0.75 RG 0.8 w 45 220 505 75 re S Q');
    sb.writeln('q 0.06 0.72 0.51 rg 45 220 4 75 re f Q');

    text(
      isEs
          ? 'TRANSACCION AUTORIZADA Y VERIFICADA DIGITALMENTE'
          : 'DIGITALLY AUTHORIZED & VERIFIED TRANSACTION',
      60,
      274,
      bold: true,
      size: 9.5,
      r: 0.02,
      g: 0.47,
      b: 0.34,
    );
    text(
      isEs
          ? 'Pago procesado mediante pasarela oficial Stripe con cifrado de nivel bancario (PSD2).'
          : 'Payment processed through official Stripe gateway with bank-grade encryption (PSD2).',
      60,
      258,
      size: 8.5,
      r: 0.15,
      g: 0.20,
      b: 0.28,
    );
    final cleanRef = invoiceNumber.replaceAll('#', '');
    text(
      isEs
          ? 'ID Transaccion: $cleanRef - Estado: Confirmado y emitido'
          : 'Transaction ID: $cleanRef - Status: Confirmed and issued',
      60,
      244,
      size: 8,
      r: 0.35,
      g: 0.42,
      b: 0.50,
    );
    text(
      isEs
          ? 'Este documento cuenta con plena validez como comprobante de pago oficial del centro.'
          : 'This document holds full legal validity as official payment confirmation.',
      60,
      231,
      size: 7.5,
      r: 0.45,
      g: 0.50,
      b: 0.58,
    );

    // 6. Footer (Y = 40 to 95)
    sb.writeln('q 0.85 0.88 0.92 RG 0.6 w 45 92 m 550 92 l S Q');
    text(
      isEs
          ? 'AULA 360 ACADEMY - Centro Educativo de Ensenanza Primaria y Secundaria'
          : 'AULA 360 ACADEMY - Primary & Secondary Educational Center',
      45,
      74,
      bold: true,
      size: 8.5,
      r: 0.25,
      g: 0.30,
      b: 0.40,
    );
    text(
      isEs
          ? 'Secretaria Academica y Facturacion Escolar - Correo de atencion: info@aula360.es'
          : 'Academic Administration & School Billing - Support: info@aula360.es',
      45,
      60,
      size: 7.5,
      r: 0.45,
      g: 0.50,
      b: 0.58,
    );
    text(
      isEs
          ? 'Documento generado electronicamente el $date. Valido para efectos contables y fiscales.'
          : 'Document electronically generated on $date. Valid for accounting and tax purposes.',
      45,
      47,
      size: 7.5,
      r: 0.55,
      g: 0.60,
      b: 0.68,
    );

    final contentStr = sb.toString();
    final contentBytes = utf8.encode(contentStr);
    objects[4] = [
      ...'<< /Length ${contentBytes.length} >>\nstream\n'.codeUnits,
      ...contentBytes,
      ...'\nendstream'.codeUnits,
    ];

    // Assemble PDF binary
    final out = BytesBuilder();
    out.add('%PDF-1.4\n%\xFF\xFF\xFF\xFF\n'.codeUnits);

    final offsets = <int, int>{};
    final sortedKeys = objects.keys.toList()..sort();
    for (final id in sortedKeys) {
      offsets[id] = out.length;
      final body = objects[id]!;
      out.add('$id 0 obj\n'.codeUnits);
      if (id != 4 && id != 7 && id != 8) {
        out.add('<< '.codeUnits);
        out.add(body);
        out.add(' >>\nendobj\n'.codeUnits);
      } else {
        out.add(body);
        out.add('\nendobj\n'.codeUnits);
      }
    }

    final xrefOffset = out.length;
    out.add('xref\n0 ${sortedKeys.length + 1}\n'.codeUnits);
    out.add('0000000000 65535 f \n'.codeUnits);
    for (int i = 1; i <= sortedKeys.length; i++) {
      final off = offsets[i]!;
      final offStr = off.toString().padLeft(10, '0');
      out.add('$offStr 00000 n \n'.codeUnits);
    }

    out.add('trailer\n<< /Size ${sortedKeys.length + 1} /Root 1 0 R >>\n'.codeUnits);
    out.add('startxref\n$xrefOffset\n%%EOF'.codeUnits);

    return out.toBytes();
  }

  static String _clean(String input) {
    var s = input
        .replaceAll('—', ' - ')
        .replaceAll('–', ' - ')
        .replaceAll('•', ' - ')
        .replaceAll('€', 'EUR')
        .replaceAll('"', "'");

    const map = {
      'á': r'\341',
      'é': r'\351',
      'í': r'\355',
      'ó': r'\363',
      'ú': r'\372',
      'ñ': r'\361',
      'Á': r'\301',
      'É': r'\311',
      'Í': r'\315',
      'Ó': r'\323',
      'Ú': r'\332',
      'Ñ': r'\321',
      'º': r'\272',
      'ü': r'\374',
      'Ü': r'\334',
    };

    s = s.replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');
    map.forEach((k, v) {
      s = s.replaceAll(k, v);
    });

    return s;
  }
}
