import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stock_management_system/core/theme/ui_constants.dart';
import 'package:stock_management_system/core/widgets/common_widgets.dart';
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
      backgroundColor: kSurface,
      appBar: AppAppBar(
        title: widget.title,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.magnifyingGlassMinus()),
            onPressed: () {
              _pdfViewerController.zoomLevel =
                  (_pdfViewerController.zoomLevel - 0.5).clamp(1.0, 5.0);
            },
            tooltip: 'ซูมออก',
          ),
          IconButton(
            icon: Icon(PhosphorIcons.magnifyingGlassPlus()),
            onPressed: () {
              _pdfViewerController.zoomLevel =
                  (_pdfViewerController.zoomLevel + 0.5).clamp(1.0, 5.0);
            },
            tooltip: 'ซูมเข้า',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SfPdfViewerTheme(
        data: SfPdfViewerThemeData(
          backgroundColor: kSurface,
          progressBarColor: kPrimary,
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
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
    );
  }
}
