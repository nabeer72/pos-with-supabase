import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playScanBeep() async {
    try {
      // Trigger haptic feedback
      await HapticFeedback.lightImpact();
      
      // Play custom tune from assets
      await _player.stop(); // Stop any currently playing tune
      await _player.play(AssetSource('tune.wav'));
    } catch (e) {
      print('Error playing custom scan tune: $e');
    }
  }
}
