import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OptimizedImage extends StatelessWidget {
  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate optimal image size based on screen density
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final maxWidth = width ?? MediaQuery.of(context).size.width;
    final maxHeight = height ?? MediaQuery.of(context).size.height;
    
    final cacheWidth = (maxWidth * pixelRatio).round();
    final cacheHeight = (maxHeight * pixelRatio).round();

    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: width,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      placeholder: (context, url) => placeholder ?? const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => errorWidget ?? const Center(
        child: Icon(Icons.error_outline, color: Colors.red),
      ),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
    );
  }
}