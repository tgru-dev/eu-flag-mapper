import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../database/database_helper.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  Position? _currentPosition;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte aktivieren Sie die Standortdienste')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Standortberechtigung wurde verweigert')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Standortberechtigungen sind permanent verweigert'),
          ),
        );
      }
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _takePicture() async {
    await _getLocation();
    
    if (_currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konnte den aktuellen Standort nicht ermitteln'),
          ),
        );
      }
      return;
    }
    
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _image = File(photo.path);
      });
      
      try {
        await _databaseHelper.insertFlag(
          photo.path,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Flagge wurde erfolgreich gespeichert!'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Speichern: $e'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EU-Flagge fotografieren'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.file(
                  _image!,
                  height: 300,
                ),
              )
            else
              const Icon(
                Icons.photo_camera,
                size: 100,
                color: Colors.grey,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _takePicture,
              child: const Text('Foto aufnehmen'),
            ),
          ],
        ),
      ),
    );
  }
} 