import 'package:flutter/material.dart';

import '../demo_data.dart';

/// A photo, as the grid thumbnail and full screen.
class Photo extends StatelessWidget {
  const Photo({super.key, required this.index, this.iconSize = 32});

  final int index;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: photoColor(index),
      child: Center(
        child: Icon(photoIcons[index], size: iconSize, color: Colors.white),
      ),
    );
  }
}

/// A full-screen photo viewer, shown in a DragDismissPageRoute.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Transparent: the route paints the black background, and fades it as
    // the photo is dragged away.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: photoIcons.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (_, index) => Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Photo(index: index, iconSize: 120),
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    '${_index + 1} / ${photoIcons.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Text(
              'Swipe sideways for more photos\n'
              'Drag up or down to close',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
