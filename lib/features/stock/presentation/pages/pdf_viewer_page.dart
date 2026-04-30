import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'dart:typed_data';

class PdfViewerPage extends StatefulWidget {
  final Uint8List pdfData;
  final String title;

  const PdfViewerPage({
    super.key,
    required this.pdfData,
    required this.title,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_rounded),
            onPressed: () {
              _pdfViewerController.zoomLevel =
                  (_pdfViewerController.zoomLevel - 0.5).clamp(1.0, 5.0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded),
            onPressed: () {
              _pdfViewerController.zoomLevel =
                  (_pdfViewerController.zoomLevel + 0.5).clamp(1.0, 5.0);
            },
          ),
        ],
      ),
      body: SfPdfViewerTheme(
        data: SfPdfViewerThemeData(
          backgroundColor: Colors.grey[100],
        ),
        child: SfPdfViewer.memory(
          widget.pdfData,
          controller: _pdfViewerController,
          pageLayoutMode: PdfPageLayoutMode.continuous,
          initialZoomLevel: 1.0,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            _pdfViewerController.jumpToPage(1);
          },
        ),
      ),
    );
  }
}
