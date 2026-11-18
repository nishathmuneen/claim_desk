import 'dart:async';
import 'dart:html' as html;
import '../models/picked_document.dart';

class DocumentUploadPlatform {
  static Future<PickedDocument?> pickFile({
    List<String> allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
  }) async {
    final completer = Completer<PickedDocument?>();
    final input = html.FileUploadInputElement();

    final acceptList = allowedExtensions.map((ext) {
      if (ext == 'pdf') return 'application/pdf';
      if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) return 'image/$ext';
      return '.$ext';
    }).join(',');

    input.accept = acceptList;
    input.multiple = false;

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      final file = files[0];
      final reader = html.FileReader();

      reader.onLoadEnd.listen((loadEvent) {
        final result = reader.result;
        String? base64;
        if (result is String) {
          base64 = result;
        }

        final fileName = file.name;
        final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
        final isImg = ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
        final isPdf = ext == 'pdf';

        if (!completer.isCompleted) {
          completer.complete(
            PickedDocument(
              name: fileName,
              sizeInBytes: file.size,
              extension: ext,
              base64Data: base64,
              isImage: isImg,
              isPdf: isPdf,
            ),
          );
        }
      });

      reader.onError.listen((errorEvent) {
        if (!completer.isCompleted) completer.complete(null);
      });

      reader.readAsDataUrl(file);
    });

    input.click();
    return completer.future;
  }
}

