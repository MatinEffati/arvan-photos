import 'dart:io';
import 'package:arvan_photos/core/di/injection.dart';
import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/features/photos/domain/entities/photo_entity.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/detail/photo_detail_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PhotoDetailScreen extends StatefulWidget {
  const PhotoDetailScreen({
    required this.photos,
    required this.initialIndex,
    super.key,
  });

  final List<PhotoEntity> photos;
  final int initialIndex;

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  Future<void> _editPhoto(PhotoEntity photo) async {
    final response = await http.get(Uri.parse(photo.url));
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/temp_edit.jpg');
    await file.writeAsBytes(response.bodyBytes);

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit Photo',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Edit Photo',
        ),
      ],
    );

    if (croppedFile != null && mounted) {
      context.read<PhotoDetailCubit>().editPhoto(photo.key, File(croppedFile.path));
    }
  }

  void _confirmDelete(PhotoEntity photo) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PhotoDetailCubit>().deletePhoto(photo.key);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PhotoDetailCubit>(),
      child: BlocConsumer<PhotoDetailCubit, PhotoDetailState>(
        listener: (context, state) {
          if (state is PhotoDetailDeleteSuccess || state is PhotoDetailEditSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state is PhotoDetailDeleteSuccess ? 'Deleted' : 'Updated')),
            );
            Navigator.pop(context, true);
          } else if (state is PhotoDetailActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Action failed: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          final currentPhoto = widget.photos[_currentIndex];
          
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                if (state is PhotoDetailActionInProgress)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editPhoto(currentPhoto),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(currentPhoto),
                  ),
                ]
              ],
            ),
            body: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(widget.photos[index].url),
                  initialScale: PhotoViewComputedScale.contained,
                  heroAttributes: PhotoViewHeroAttributes(tag: widget.photos[index].key),
                );
              },
              itemCount: widget.photos.length,
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(),
              ),
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          );
        },
      ),
    );
  }
}
