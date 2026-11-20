import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../services/device_location_service.dart';
import '../services/draft_repository.dart';
import '../services/photo_upload_service.dart';
import 'sensor_demo_page.dart';

class DeviceFeaturePage extends StatefulWidget {
  const DeviceFeaturePage({super.key});

  @override
  State<DeviceFeaturePage> createState() => _DeviceFeaturePageState();
}

class _DeviceFeaturePageState extends State<DeviceFeaturePage> {
  final _titleController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _draftRepository = DraftRepository();
  final _locationService = const DeviceLocationService();
  final _photoUploadService = PhotoUploadService();
  final _geocoding = Geocoding(locale: const Locale('id', 'ID'));

  String? _photoPath;
  String? _locationName;
  Position? _position;
  PhotoUploadResult? _uploadResult;
  bool _isRestoring = true;
  bool _isPickingPhoto = false;
  bool _isGettingLocation = false;
  bool _isResolvingAddress = false;
  bool _isSavingDraft = false;
  bool _isUploading = false;
  bool _isSupabaseConnected = false;
  String? _draftSavedAt;

  @override
  void initState() {
    super.initState();
    _restoreLocalDraft();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _restoreLocalDraft() async {
    try {
      final draft = await _draftRepository.load();
      if (draft != null && mounted) {
        _titleController.text = draft['title']?.toString() ?? '';

        final storedPhotoPath = draft['photoPath']?.toString();
        if (storedPhotoPath != null &&
            storedPhotoPath.isNotEmpty &&
            await File(storedPhotoPath).exists()) {
          _photoPath = storedPhotoPath;
        }

        final latitude = (draft['latitude'] as num?)?.toDouble();
        final longitude = (draft['longitude'] as num?)?.toDouble();
        if (latitude != null && longitude != null) {
          _position = _restoredPosition(latitude, longitude);
          _locationName = draft['locationName']?.toString();
        }
        _draftSavedAt = draft['savedAt']?.toString();
      }

      if (_position != null &&
          (_locationName == null || _locationName!.isEmpty)) {
        await _resolveLocationName(_position!);
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final lostData = await _imagePicker.retrieveLostData();
        if (lostData.exception != null) {
          throw lostData.exception!;
        }
        final recoveredFile = lostData.file;
        if (recoveredFile != null) {
          final permanentPath = await _draftRepository.savePermanentPhoto(
            recoveredFile,
          );
          if (mounted) {
            setState(() {
              _photoPath = permanentPath;
              _uploadResult = null;
            });
          }
        }
      }
    } on Object catch (error) {
      if (mounted) _showMessage('Draft/foto tidak dapat dipulihkan: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
          _isSupabaseConnected = _checkSupabaseSession();
        });
      }
    }
  }

  Position _restoredPosition(double latitude, double longitude) {
    return Position(
      longitude: longitude,
      latitude: latitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  bool _checkSupabaseSession() {
    if (!SupabaseConfig.isConfigured) return false;
    return Supabase.instance.client.auth.currentUser != null;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);
    try {
      final selected = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (selected == null) return;

      final permanentPath = await _draftRepository.savePermanentPhoto(selected);
      if (!mounted) return;
      setState(() {
        _photoPath = permanentPath;
        _uploadResult = null;
      });
      _showMessage(
        'Foto disimpan di perangkat. Simpan draft untuk menyimpan catatan.',
      );
    } on Object catch (error) {
      if (mounted) _showMessage('Foto tidak dapat dipilih: $error');
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _getLocation() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);
    try {
      final position = await _locationService.getPosition();
      if (!mounted) return;
      setState(() => _position = position);
      await _resolveLocationName(position);
      if (mounted) {
        _showMessage(
          _locationName == null || _locationName!.isEmpty
              ? 'Koordinat berhasil diperoleh; nama lokasi tidak tersedia.'
              : 'Lokasi berhasil ditemukan.',
        );
      }
    } on LocationFailure catch (failure) {
      if (mounted) await _showLocationFailure(failure);
    } on Object catch (error) {
      if (mounted) {
        _showMessage('Koordinat gagal diperoleh: $error');
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _resolveLocationName(Position position) async {
    if (mounted) setState(() => _isResolvingAddress = true);
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final placemark = placemarks.firstOrNull;
      final parts =
          [
                placemark?.name,
                placemark?.street,
                placemark?.subLocality,
                placemark?.locality,
                placemark?.subAdministrativeArea,
                placemark?.administrativeArea,
                placemark?.country,
              ]
              .whereType<String>()
              .map((part) => part.trim())
              .where((part) => part.isNotEmpty);
      final uniqueParts = <String>[];
      for (final part in parts) {
        if (uniqueParts.isEmpty || uniqueParts.last != part) {
          uniqueParts.add(part);
        }
      }
      if (mounted) {
        setState(() {
          _locationName = uniqueParts.isEmpty
              ? 'Nama lokasi tidak tersedia'
              : uniqueParts.join(', ');
        });
      }
    } on Object catch (error) {
      debugPrint('[LOCATION] Reverse geocoding gagal: $error');
      if (mounted) {
        setState(() => _locationName = 'Nama lokasi tidak tersedia');
      }
    } finally {
      if (mounted) setState(() => _isResolvingAddress = false);
    }
  }

  Future<void> _showLocationFailure(LocationFailure failure) async {
    final canOpenAppSettings =
        failure.type == LocationFailureType.deniedForever;
    final canOpenSettings = failure.type != LocationFailureType.denied;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          failure.type == LocationFailureType.serviceDisabled
              ? Icons.location_disabled_rounded
              : Icons.location_off_rounded,
          color: const Color(0xFF1D4ED8),
        ),
        title: const Text('Lokasi belum tersedia'),
        content: Text(failure.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(canOpenSettings ? 'Nanti' : 'Mengerti'),
          ),
          if (canOpenSettings)
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.settings_rounded),
              label: Text(
                canOpenAppSettings ? 'Pengaturan Aplikasi' : 'Pengaturan GPS',
              ),
            ),
        ],
      ),
    );
    if (confirmed != true) return;

    final opened = canOpenAppSettings
        ? await Geolocator.openAppSettings()
        : await Geolocator.openLocationSettings();
    if (!opened && mounted) {
      _showMessage('Pengaturan perangkat tidak dapat dibuka.');
    }
  }

  Future<void> _saveDraft() async {
    if (_isSavingDraft) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSavingDraft = true);
    try {
      final savedAt = DateTime.now().toIso8601String();
      await _draftRepository.save({
        'title': _titleController.text.trim(),
        'photoPath': _photoPath,
        'latitude': _position?.latitude,
        'longitude': _position?.longitude,
        'locationName': _locationName,
        'savedAt': savedAt,
      });
      if (!mounted) return;
      setState(() => _draftSavedAt = savedAt);
      _showMessage('Draft berhasil disimpan di perangkat.');
    } on Object catch (error) {
      if (mounted) _showMessage('Draft gagal disimpan: $error');
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  Future<void> _uploadPhoto() async {
    if (_isUploading) return;
    final photoPath = _photoPath;
    if (photoPath == null) {
      _showMessage('Pilih foto terlebih dahulu sebelum upload.');
      return;
    }
    if (!_checkSupabaseSession()) {
      setState(() => _isSupabaseConnected = false);
      _showMessage('Upload membutuhkan sesi Supabase yang aktif.');
      return;
    }

    setState(() => _isUploading = true);
    try {
      final result = await _photoUploadService.upload(File(photoPath));
      if (!mounted) return;
      setState(() {
        _uploadResult = result;
        _isSupabaseConnected = true;
      });
      _showMessage('Foto berhasil diunggah. Draft lokal tetap tersimpan.');
    } on Object catch (error) {
      if (mounted) {
        _showMessage('Upload gagal; draft lokal tetap aman. $error');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _isSupabaseConnected && _checkSupabaseSession();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitur Perangkat'),
        actions: [
          IconButton(
            tooltip: 'Demo sensor accelerometer',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SensorDemoPage()),
              );
            },
            icon: const Icon(Icons.sensors_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _modeStatusCard(isConnected),
                const SizedBox(height: 14),
                _sectionCard(
                  title: 'Dokumentasi Kelas',
                  subtitle:
                      'Catatan, foto, dan lokasi tersimpan sebagai draft.',
                  icon: Icons.assignment_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Nama lokasi / dokumentasi kelas',
                          hintText: 'Contoh: Praktikum Flutter',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isPickingPhoto
                                  ? null
                                  : () => _pickPhoto(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_rounded),
                              label: const Text('Kamera'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isPickingPhoto
                                  ? null
                                  : () => _pickPhoto(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_rounded),
                              label: const Text('Galeri'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _photoPreview(),
                      const SizedBox(height: 16),
                      _locationPanel(),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  title: 'Penyimpanan & Sinkronisasi',
                  subtitle:
                      'Draft disimpan lokal, foto dapat diunggah saat online.',
                  icon: Icons.cloud_sync_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _isSavingDraft ? null : _saveDraft,
                          icon: _isSavingDraft
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isSavingDraft
                                ? 'Menyimpan Draft...'
                                : 'Simpan Draft Lokal',
                          ),
                        ),
                      ),
                      if (_draftSavedAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Draft terakhir: ${_formatDate(_draftSavedAt!)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : _uploadPhoto,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(
                            _isUploading
                                ? 'Mengunggah Foto...'
                                : 'Upload Foto ke Supabase Storage',
                          ),
                        ),
                      ),
                      if (_uploadResult != null) ...[
                        const SizedBox(height: 14),
                        _uploadInfo(_uploadResult!),
                      ],
                    ],
                  ),
                ),
                if (_isRestoring) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeStatusCard(bool isConnected) {
    final color = isConnected
        ? const Color(0xFF15803D)
        : const Color(0xFFB45309);
    final background = isConnected
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFFF7ED);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isConnected ? Icons.cloud_done_rounded : Icons.phone_android,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'Supabase terhubung' : 'Mode lokal aktif',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isConnected
                        ? 'Draft tersimpan di perangkat dan siap disinkronkan.'
                        : 'Draft tetap tersimpan di perangkat saat offline.',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: const Color(0xFF1D4ED8)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }

  Widget _photoPreview() {
    final photoPath = _photoPath;
    if (photoPath == null) {
      return Container(
        height: 156,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 34,
              color: Color(0xFF1D4ED8),
            ),
            SizedBox(height: 8),
            Text(
              'Foto dokumentasi akan tampil di sini',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDBEAFE)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photoPath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Text('Pratinjau foto tidak tersedia')),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton.filledTonal(
                tooltip: 'Hapus pilihan foto',
                onPressed: () => setState(() {
                  _photoPath = null;
                  _uploadResult = null;
                }),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationPanel() {
    final position = _position;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFF1D4ED8)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  position == null
                      ? 'Lokasi belum diambil'
                      : 'Lokasi ditemukan',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_isResolvingAddress)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (position != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.place_rounded,
                  size: 19,
                  color: Color(0xFF1D4ED8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationName ??
                        '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 190,
                child: FlutterMap(
                  key: ValueKey('${position.latitude},${position.longitude}'),
                  options: MapOptions(
                    initialCenter: LatLng(
                      position.latitude,
                      position.longitude,
                    ),
                    initialZoom: 15,
                    minZoom: 3,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.flutter_ui_fundamentals',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(position.latitude, position.longitude),
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_pin,
                            color: Color(0xFFDC2626),
                            size: 44,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Peta © OpenStreetMap contributors',
              textAlign: TextAlign.end,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              visualDensity: VisualDensity.compact,
              title: const Text(
                'Lihat koordinat',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    'Lat: ${position.latitude.toStringAsFixed(6)}\nLng: ${position.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isGettingLocation ? null : _getLocation,
            icon: _isGettingLocation
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(
              _isGettingLocation
                  ? 'Mengambil Koordinat...'
                  : 'Ambil Koordinat GPS',
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadInfo(PhotoUploadResult result) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_done_rounded, color: Color(0xFF15803D)),
              SizedBox(width: 8),
              Text(
                'Upload berhasil',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Lokasi objek',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          SelectableText(
            result.storagePath,
            style: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'URL publik',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          SelectableText(
            result.publicUrl,
            style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} ${local.hour}:$minute';
  }
}
