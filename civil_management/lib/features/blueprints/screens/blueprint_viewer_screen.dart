import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

import '../../../core/widgets/loading_widget.dart';
import '../data/models/blueprint_model.dart';

class BlueprintViewerScreen extends StatelessWidget {
  final Blueprint blueprint;

  const BlueprintViewerScreen({super.key, required this.blueprint});

  @override
  Widget build(BuildContext context) {
    final isPdf = blueprint.fileName.toLowerCase().endsWith('.pdf');

    return Scaffold(
      appBar: AppBar(
        title: Text(blueprint.fileName),
      ),
      body: isPdf ? _buildPdfViewer() : _buildImageViewer(),
    );
  }

  Widget _buildPdfViewer() {
    return const PDF().cachedFromUrl(
      blueprint.publicUrl,
      placeholder: (progress) => LoadingWidget(message: 'Loading PDF... $progress%'),
      errorWidget: (error) => Center(child: Text(error.toString())),
    );
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      panEnabled: true,
      minScale: 0.5,
      maxScale: 4,
      child: Center(
        child: Image.network(
          blueprint.publicUrl,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const LoadingWidget(message: 'Loading Image...');
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Text('Failed to load image: $error'));
          },
        ),
      ),
    );
  }
}
