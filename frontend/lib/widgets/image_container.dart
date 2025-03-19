import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum ImageSourceType {
  file,
  network,
  asset,
  memory,
  empty
}

class ImageContainer extends StatelessWidget {
  final ImageSourceType sourceType;
  final dynamic imageSource;
  final double size;
  final BorderRadius? borderRadius;
  final Color borderColor;
  final double borderWidth;
  final Widget? placeholder;
  final Map<String, String>? httpHeaders;
  final String noImageText;

  const ImageContainer.file({
    super.key,
    required File? file,
    required this.size,
    this.borderRadius,
    this.borderColor = Colors.white,
    this.borderWidth = 4,
    this.placeholder,
    this.noImageText = 'No image available',
  }) : sourceType = file != null ? ImageSourceType.file : ImageSourceType.empty,
       imageSource = file, 
       httpHeaders = null;

  ImageContainer.network({
    super.key,
    required String? url,
    required this.size,
    this.borderRadius,
    this.borderColor = Colors.white,
    this.borderWidth = 4,
    this.placeholder,
    this.noImageText = 'No image available',
    this.httpHeaders,
  }) : sourceType = (url != null && url.isNotEmpty) ? ImageSourceType.network : ImageSourceType.empty,
       imageSource = url;

    const ImageContainer.asset({
    super.key,
    required String assetPath,
    required this.size,
    this.borderRadius,
    this.borderColor = Colors.white,
    this.borderWidth = 4,
    this.placeholder,
    this.noImageText = 'No image available',
  }) : sourceType = ImageSourceType.asset,
       imageSource = assetPath, 
       httpHeaders = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius:  borderRadius ?? BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: ClipRRect(
        borderRadius: borderRadius != null
          ? borderRadius!.subtract(BorderRadius.circular(borderWidth))
          : BorderRadius.circular(16),
        child: _buildImage() ?? placeholder ?? Container(color: Colors.grey.shade300) 
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Text(
          noImageText,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget? _buildImage() {
    if (sourceType == ImageSourceType.empty || imageSource == null) {
      _buildNoImagePlaceholder();
    }

    switch (sourceType) {
      case ImageSourceType.file:
        return Image.file(
          imageSource as File,
          fit: BoxFit.cover,
          errorBuilder:(context, error, stackTrace) => placeholder ?? _buildNoImagePlaceholder(),
        );
      case ImageSourceType.network:
        return CachedNetworkImage(
          imageUrl: imageSource as String,
          fit: BoxFit.cover,
          httpHeaders: httpHeaders,
          placeholder: (context, url) => placeholder ?? const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget:(context, error, stackTrace) => placeholder ?? _buildNoImagePlaceholder(),
        );
      case ImageSourceType.asset:
        return Image.asset(
          imageSource as String,
          fit: BoxFit.cover,
          errorBuilder:(context, error, stackTrace) => placeholder ?? _buildNoImagePlaceholder(),
        );
      case ImageSourceType.memory:
      case ImageSourceType.empty:
        return null;
    }
  }
}

class ImagePlaceholder extends StatelessWidget {
  final double size;
  final Color color;

  const ImagePlaceholder({
    super.key,
    required this.size,
    this.color = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: color,
    );
  }
}

