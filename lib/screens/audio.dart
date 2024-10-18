import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Singleton AudioService
class AudioService {
  static final AudioService _instance = AudioService._internal();
  final AudioPlayer _audioPlayer = AudioPlayer();

  factory AudioService() {
    return _instance;
  }

  AudioService._internal();

  AudioPlayer get audioPlayer => _audioPlayer;
}

class QuranAudioPage extends StatefulWidget {
  @override
  _QuranAudioPageState createState() => _QuranAudioPageState();
}

class _QuranAudioPageState extends State<QuranAudioPage> {
  final AudioPlayer _audioPlayer =
      AudioService().audioPlayer; // Utilisation de l'instance unique
  bool isPlaying = false;
  bool isRepeating = false;
  double playbackSpeed = 1.0;
  int currentSurahIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedState(); // Charger l'état sauvegardé

    _initAudioPlayer(); // Initialiser l'écouteur de fin de lecture
  }

  // Sauvegarder l'état dans SharedPreferences
  Future<void> _saveState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentSurahIndex', currentSurahIndex);
    await prefs.setDouble('playbackSpeed', playbackSpeed);
    await prefs.setBool('isPlaying', isPlaying);
  }

  // Charger l'état depuis SharedPreferences
  Future<void> _loadSavedState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(() {
        currentSurahIndex = prefs.getInt('currentSurahIndex') ?? 0;
        playbackSpeed = prefs.getDouble('playbackSpeed') ?? 1.0;
        isPlaying = prefs.getBool('isPlaying') ?? false;
      });

    // Si une sourate était en cours de lecture, la reprendre
    /*  if (isPlaying) {
      _playSurah(surahList[currentSurahIndex]['file']!);
      _audioPlayer.setPlaybackRate(playbackSpeed);
    } */
  }

  // Liste des sourates avec leurs fichiers audio
  final List<Map<String, String>> surahList = [
    {'name': 'Al-Fatiha', 'file': 'audio/al_fatiha.mp3'},
    {'name': 'Al-Baqara', 'file': 'audio/al_baqara.mp3'},
    {'name': 'Al-Imrane', 'file': 'audio/al_imrane.mp3'},
    // Ajoute les autres sourates ici...
  ];

  void _playPause(String filePath) async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      _playSurah(filePath); // Call playSurah here instead of directly in onTap
    }
    if (mounted)
      setState(() {
        isPlaying = !isPlaying;
      });
    _saveState(); // Sauvegarder l'état après lecture/pause
  }

  void _playSurah(String filePath) async {
    await _audioPlayer.play(AssetSource(filePath));

    await _audioPlayer.setPlaybackRate(playbackSpeed); // Set playback speed
    if (mounted)
      setState(() {
        isPlaying = true;
      });
    _saveState(); // Sauvegarder l'état après lecture/pause
  }

  void _nextSurah() {
    if (mounted)
      setState(() {
        currentSurahIndex = (currentSurahIndex + 1) % surahList.length;
      });
    _playSurah(surahList[currentSurahIndex]['file']!);

    _saveState(); // Sauvegarder l'état après lecture/pause
  }

  void _previousSurah() {
    if (mounted)
      setState(() {
        currentSurahIndex =
            (currentSurahIndex - 1 + surahList.length) % surahList.length;
      });
    _playSurah(surahList[currentSurahIndex]['file']!);
    _saveState(); // Sauvegarder l'état après lecture/pause
  }

  void _toggleRepeat() {
    if (mounted)
      setState(() {
        isRepeating = !isRepeating;
        print(isRepeating);
        _audioPlayer.setReleaseMode(isRepeating
            ? ReleaseMode.loop
            : ReleaseMode.release); // Active ou désactive la répétition
      });
  }

  void _initAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((event) {
      if (isRepeating) {
        // Si en mode répétition, rejouer la même sourate
        _playSurah(surahList[currentSurahIndex]['file']!);
      } else {
        // Sinon passer à la sourate suivante
        _nextSurah();
      }
    });
  }

  void _changeSpeed(double speed) {
    if (mounted)
      setState(() {
        playbackSpeed = speed;
      });
    _audioPlayer.setPlaybackRate(speed);
    _saveState(); // Sauvegarder l'état après lecture/pause
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Coran Audio',
          style: TextStyle(
            fontFamily: 'Kitab',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF4CADA0),
      ),
      body: Stack(
        children: [
          // Image d'arrière-plan
          Positioned.fill(
            child: Image.asset(
              'assets/background_image.jpg', // Remplace par le chemin de ton image
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.separated(
                  separatorBuilder: (context, index) => Divider(),
                  itemCount: surahList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        surahList[index]['name']!,
                        style: TextStyle(
                          fontFamily: 'Kitab',
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: currentSurahIndex == index && isPlaying
                          ? InkWell(
                              onTap: () {
                                setState(() {
                                  currentSurahIndex = index;
                                  print(currentSurahIndex);
                                });
                                _playPause(surahList[index]['file']!);
                              },
                              child: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.black))
                          : null,
                      onTap: () {
                        setState(() {
                          currentSurahIndex = index;
                        });
                        _playSurah(surahList[index]['file']!);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF4CADA0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.skip_previous),
                onPressed: _previousSurah,
              ),
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () =>
                    _playPause(surahList[currentSurahIndex]['file']!),
              ),
              IconButton(
                icon: Icon(Icons.skip_next),
                onPressed: _nextSurah,
              ),
              IconButton(
                icon: Icon(isRepeating ? Icons.repeat_one : Icons.repeat),
                onPressed: _toggleRepeat,
              ),
              PopupMenuButton<double>(
                onSelected: _changeSpeed,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 0.5,
                    child: Text('0.5x'),
                  ),
                  PopupMenuItem(
                    value: 1.0,
                    child: Text('1.0x'),
                  ),
                  PopupMenuItem(
                    value: 1.5,
                    child: Text('1.5x'),
                  ),
                  PopupMenuItem(
                    value: 2.0,
                    child: Text('2.0x'),
                  ),
                ],
                child: Icon(Icons.speed),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
