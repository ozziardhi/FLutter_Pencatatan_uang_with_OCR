import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<double?> processImageToAmount(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      List<TextLine> allLines = [];
      for (TextBlock block in recognizedText.blocks) {
        allLines.addAll(block.lines);
      }

      // Kata kunci utama untuk TOTAL
      List<String> totalKeywords = [
        'grand total',
        'total bayar',
        'total akhir',
        'total net',
        'total',
        'jumlah',
        'tagihan',
      ];

      // 1. PRIORITAS UTAMA: Cari kata "GRAND TOTAL" / "TOTAL"
      for (int i = 0; i < allLines.length; i++) {
        final line = allLines[i];
        final textLower = line.text.toLowerCase();

        // ABAIKAN jika baris mengandung kata "kembali" atau "change"
        if (textLower.contains('kembali') || textLower.contains('change')) {
          continue;
        }

        bool matchKeyword = totalKeywords.any((kw) => textLower.contains(kw));

        if (matchKeyword) {
          // A. Cek apakah ada angka nominal di baris yang sama
          double? sameLineNumber = _extractAmountFromString(line.text);
          if (sameLineNumber != null) {
            await textRecognizer.close();
            return sameLineNumber;
          }

          // B. Cek baris lain yang sejajar di sebelah kanan (Y-axis berdekatan)
          final lineBox = line.boundingBox;
          for (final otherLine in allLines) {
            if (otherLine == line) continue;
            final otherTextLower = otherLine.text.toLowerCase();

            // Jangan ambil dari baris kembalian
            if (otherTextLower.contains('kembali') ||
                otherTextLower.contains('change')) {
              continue;
            }

            final otherBox = otherLine.boundingBox;
            bool isSameHeight = (otherBox.top - lineBox.top).abs() < 35;
            bool isToTheRight = otherBox.left >= lineBox.left;

            if (isSameHeight && isToTheRight) {
              double? amount = _extractAmountFromString(otherLine.text);
              if (amount != null) {
                await textRecognizer.close();
                return amount;
              }
            }
          }

          // C. Cek 1 baris tepat di bawahnya (yang TIDAK mengandung kata kembali/bayar)
          if (i + 1 < allLines.length) {
            final nextLineText = allLines[i + 1].text.toLowerCase();
            if (!nextLineText.contains('kembali') &&
                !nextLineText.contains('bayar') &&
                !nextLineText.contains('cash')) {
              double? amountBelow = _extractAmountFromString(
                allLines[i + 1].text,
              );
              if (amountBelow != null) {
                await textRecognizer.close();
                return amountBelow;
              }
            }
          }
        }
      }

      // 2. FALLBACK: Jika tidak ada kata "TOTAL", ambil angka terbesar dari daftar (kecuali kembalian & no hp)
      List<double> candidateAmounts = [];
      for (final line in allLines) {
        final textLower = line.text.toLowerCase();
        if (textLower.contains('kembali') || textLower.contains('change')) {
          continue;
        }

        double? amount = _extractAmountFromString(line.text);
        if (amount != null) {
          candidateAmounts.add(amount);
        }
      }

      await textRecognizer.close();

      if (candidateAmounts.isNotEmpty) {
        candidateAmounts.sort();
        return candidateAmounts.last;
      }
    } catch (e) {
      print("Error OCR: $e");
    } finally {
      textRecognizer.close();
    }

    return null;
  }

  double? _extractAmountFromString(String text) {
    if (text.contains('081') ||
        text.contains('082') ||
        text.contains('085') ||
        text.contains('087') ||
        text.contains('088')) {
      return null;
    }

    String clean = text.replaceAll(RegExp(r'[^\d.,]'), '').trim();
    if (clean.isEmpty) return null;

    if (clean.contains('.') && clean.contains(',')) {
      if (clean.lastIndexOf(',') > clean.lastIndexOf('.')) {
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      } else {
        clean = clean.replaceAll(',', '');
      }
    } else if (clean.contains('.')) {
      List<String> parts = clean.split('.');
      if (parts.last.length == 3 || parts.length > 2) {
        clean = clean.replaceAll('.', '');
      }
    } else if (clean.contains(',')) {
      List<String> parts = clean.split(',');
      if (parts.last.length == 3 || parts.length > 2) {
        clean = clean.replaceAll(',', '');
      }
    }

    RegExp regExp = RegExp(r'\d+');
    Iterable<Match> matches = regExp.allMatches(clean);

    for (Match match in matches) {
      double? val = double.tryParse(match.group(0) ?? '');
      if (val != null && val >= 500 && val <= 50000000) {
        if (match.group(0)!.length <= 8) {
          return val;
        }
      }
    }

    return null;
  }
}
