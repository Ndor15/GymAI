import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gymai/models/workout_models.dart';
import 'package:gymai/services/firestore_post_service.dart';

class PostCreationDialog extends StatefulWidget {
  final WorkoutSession session;

  const PostCreationDialog({super.key, required this.session});

  @override
  State<PostCreationDialog> createState() => _PostCreationDialogState();
}

class _PostCreationDialogState extends State<PostCreationDialog> {
  final FirestorePostService _postService = FirestorePostService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();

  String? _photoPath;
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<String> _savePhoto(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'workout_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = '${appDir.path}/$fileName';
    await File(sourcePath).copy(savedPath);
    return savedPath;
  }

  Future<void> _pickImage(ImageSource source) async {
    final photo = await _imagePicker.pickImage(source: source);
    if (photo != null) {
      final savedPath = await _savePhoto(photo.path);
      setState(() {
        _photoPath = savedPath;
      });
    }
  }

  Future<void> _publish() async {
    setState(() => _isUploading = true);

    try {
      final post = WorkoutPost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        session: widget.session,
        photoPath: null,
        caption: _captionController.text.trim().isEmpty ? null : _captionController.text.trim(),
        publishedAt: DateTime.now(),
      );

      await _postService.addPost(post, localPhotoPath: _photoPath);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        String errorMsg = 'Erreur lors de la publication';
        if (e.toString().contains('not authenticated')) {
          errorMsg = 'Firebase non configuré. Utilise le mode local pour l\'instant.';
        } else if (e.toString().contains('network')) {
          errorMsg = 'Erreur réseau. Vérifie ta connexion internet.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF5C32E), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.celebration, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Séance terminée !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(Icons.fitness_center, '${widget.session.sets.length}', 'Séries'),
                    _buildStat(Icons.repeat, '${widget.session.totalReps}', 'Reps'),
                    _buildStat(Icons.timer, widget.session.formattedDuration, 'Durée'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Partage ta séance sur ton feed !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Photo section
              if (_photoPath != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_photoPath!),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _photoPath = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildPhotoButton(
                        icon: Icons.camera_alt,
                        label: 'Caméra',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPhotoButton(
                        icon: Icons.photo_library,
                        label: 'Galerie',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Caption field
              TextField(
                controller: _captionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ajoute une légende (optionnel)...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF5C32E)),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Passer',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF5C32E),
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.grey.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isUploading ? null : _publish,
          child: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text('Publier', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFF5C32E), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5C32E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFF5C32E),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFF5C32E), size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF5C32E),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
