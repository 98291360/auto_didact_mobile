import 'package:autodidact_app/screens/audio.dart';
import 'package:flutter/material.dart';

class AlbumListPage extends StatefulWidget {
  @override
  State<AlbumListPage> createState() => _AlbumListPageState();
}

class _AlbumListPageState extends State<AlbumListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end, // Aligne tout à droite
          children: [
            Text(
              "القراءات".toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Kitab',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
          // Contenu de la page
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              itemCount: albums.length, // Nombre total d'albums
              itemBuilder: (context, index) {
                return _buildAlbumCard(albums[index], context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCard(String albumName, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Naviguer vers la page de lecture audio en passant l'album sélectionné
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuranAudioPage(),
          ),
        );
      },
      child: Card(
        color: Colors.white.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Center(
          child: Text(
            albumName,
            style: TextStyle(
              fontFamily: 'Kitab',
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// Liste d'exemple d'albums
final List<String> albums = [
  'Album 1',
  'Album 2',
  'Album 3',
  'Album 4',
];
