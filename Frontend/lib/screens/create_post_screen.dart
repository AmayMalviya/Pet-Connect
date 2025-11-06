import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  File? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in.');
      }

      String? imageUrl;
      if (_image != null) {
        final imageExtension = _image!.path.split('.').last.toLowerCase();
        final imageBytes = await _image!.readAsBytes();
        final userId = user.id;
        final imagePath = '$userId/posts/${DateTime.now().millisecondsSinceEpoch}.$imageExtension';
        await Supabase.instance.client.storage.from('posts').uploadBinary(
              imagePath,
              imageBytes,
              fileOptions: FileOptions(
                upsert: false,
                contentType: 'image/$imageExtension',
              ),
            );
        imageUrl = Supabase.instance.client.storage.from('posts').getPublicUrl(imagePath);
      }

      await Supabase.instance.client.from('posts').insert({
        'user_id': user.id,
        'content': _contentController.text,
        'image_url': imageUrl,
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            _image != null
                ? Image.file(_image!, height: 150)
                : const Text('No image selected.'),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createPost,
                    child: const Text('Create Post'),
                  ),
          ],
        ),
      ),
    );
  }
}
