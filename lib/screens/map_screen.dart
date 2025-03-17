import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  Position? _currentPosition;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  static const LatLng _defaultPosition = LatLng(50.9375, 6.9603); // Köln als Standardposition

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadFlags();
  }

  Future<void> _loadFlags() async {
    try {
      final flags = await _databaseHelper.getAllFlags();
      setState(() {
        _markers = flags.map((flag) {
          return Marker(
            point: LatLng(flag['latitude'], flag['longitude']),
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () => _showFlagImage(flag),
              child: const Icon(Icons.flag)
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 2000.ms)
                .scale(
                  duration: const Duration(milliseconds: 300),
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.2, 1.2),
                ),
            ),
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Fehler beim Laden der Flaggen: $e');
    }
  }

  void _showFlagImage(Map<String, dynamic> flag) {
    final DateTime createdAt = DateTime.parse(flag['created_at']);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Hero(
                  tag: 'flag-${flag['id']}',
                  child: Image.file(
                    File(flag['image_path']),
                    fit: BoxFit.cover,
                  ).animate()
                  .scale(
                    duration: const Duration(milliseconds: 300),
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.2, 1.2),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ).animate()
                      .shake(duration: 300.ms)
                      .scale(
                        duration: const Duration(milliseconds: 300),
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.2, 1.2),
                      ),
                    onPressed: () => _deleteFlag(flag),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Aufgenommen am ${_dateFormat.format(createdAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Position: ${flag['latitude'].toStringAsFixed(6)}, ${flag['longitude'].toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFlag(Map<String, dynamic> flag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flagge löschen')
          .animate()
          .fadeIn()
          .scale(),
        content: const Text('Möchten Sie diese Flagge wirklich löschen?')
          .animate()
          .fadeIn()
          .slide(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _databaseHelper.deleteFlag(flag['id']);
      if (mounted) {
        Navigator.pop(context);
        _loadFlags();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Flagge wurde gelöscht')
              .animate()
              .fadeIn()
              .slide(),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
      
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        12,
      );
    } catch (e) {
      debugPrint('Fehler beim Abrufen des Standorts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EU-Flaggen Karte')
          .animate()
          .fadeIn()
          .scale(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh)
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 1000.ms),
            onPressed: _loadFlags,
          ),
          IconButton(
            icon: const Icon(Icons.my_location)
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2000.ms),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _defaultPosition,
          initialZoom: 12,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.eu_flag',
          ),
          MarkerLayer(
            markers: _markers,
          ),
        ],
      ),
    );
  }
} 