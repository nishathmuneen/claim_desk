import '../models/picked_document.dart';
import 'document_upload_service_stub.dart'
    if (dart.library.html) 'document_upload_service_web.dart'
    if (dart.library.io) 'document_upload_service_io.dart';

class DocumentUploadService {
  static Future<PickedDocument?> pickDocument({
    List<String> allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
  }) {
    return DocumentUploadPlatform.pickFile(allowedExtensions: allowedExtensions);
  }
}

