import 'dart:html' as html;

Future<void> downloadBytesWeb(
  List<int> bytes,
  String fileName,
  String mimeType,
) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..style.display = 'none'
    ..download = fileName;

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
