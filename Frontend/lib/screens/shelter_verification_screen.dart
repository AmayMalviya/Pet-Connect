
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pet_connect_app/screens/shelter_home_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:camera/camera.dart';

class ShelterVerificationScreen extends StatefulWidget {
  const ShelterVerificationScreen({super.key});

  @override
  _ShelterVerificationScreenState createState() =>
      _ShelterVerificationScreenState();
}

class _ShelterVerificationScreenState extends State<ShelterVerificationScreen> {
  File? _idImage;
  File? _selfieImage;
  final _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickIdImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _idImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _takeSelfie() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);

    final pickedFile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakePictureScreen(camera: firstCamera),
      ),
    );

    if (pickedFile != null) {
      setState(() {
        _selfieImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _verifyIdentity() async {
    if (_idImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both images.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final idPhotoPath = '/$userId/id_photo.png';
      final selfiePath = '/$userId/selfie.png';

      await Supabase.instance.client.storage.from('user-images').upload(
            idPhotoPath,
            _idImage!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      await Supabase.instance.client.storage.from('user-images').upload(
            selfiePath,
            _selfieImage!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final response = await Supabase.instance.client.functions.invoke(
        'verify-identity',
        body: {
          'idPhotoPath': idPhotoPath,
          'selfiePath': selfiePath,
          'userId': userId,
        },
      );

      if (response.data['success'] == true) {
        Navigator.pushReplacementNamed(context, ShelterHomeScreen.routeName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Verification failed.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
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
        title: const Text('Shelter Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_idImage != null)
              Image.file(_idImage!, height: 150)
            else
              const Text('No ID image selected.'),
            ElevatedButton(
              onPressed: _pickIdImage,
              child: const Text('Upload ID'),
            ),
            const SizedBox(height: 20),
            if (_selfieImage != null)
              Image.file(_selfieImage!, height: 150)
            else
              const Text('No selfie taken.'),
            ElevatedButton(
              onPressed: _takeSelfie,
              child: const Text('Take Selfie'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyIdentity,
                    child: const Text('Verify'),
                  ),
          ],
        ),
      ),
    );
  }
}

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({super.key, required this.camera});

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            Navigator.pop(context, image);
          } catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
