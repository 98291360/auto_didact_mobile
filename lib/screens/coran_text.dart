import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter/services.dart' show rootBundle;

class QuranPage extends StatefulWidget {
  @override
  _QuranPageState createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  List<String> pages = [];
  Color textColor = Colors.white;

  @override
  void initState() {
    super.initState();
    loadQuranText();
  }

  Future<void> loadQuranText() async {
    try {
      String xmlString =
          await rootBundle.loadString('assets/quran-uthmani.xml');
      final document = xml.XmlDocument.parse(xmlString);

      List<String> fullTextList = [];
      StringBuffer buffer = StringBuffer();

      String? currentSuraName;
      String? currentSuraIndex;
      int verseCount = 0;

      for (var element in document.descendants) {
        if (element.nodeType == xml.XmlNodeType.ELEMENT) {
          final elementName = (element as xml.XmlElement).name.toString();
          if (elementName == 'sura') {
            // Start of a new sura
            if (currentSuraName != null) {
              // Add the last sura's verses to the list
              if (buffer.isNotEmpty) {
                fullTextList.add(buffer.toString().trim());
                buffer.clear();
              }
            }
            // Add the sura header immediately
            currentSuraName = element.getAttribute('name');
            currentSuraIndex = element.getAttribute('index');
            verseCount = 0;

            // Add the sura header to the buffer directly
            buffer.write(_buildSuraHeader(
                currentSuraName, currentSuraIndex, verseCount));
          } else if (elementName == 'aya') {
            String verseText = element.getAttribute('text') ?? '';
            String verseIndex = element.getAttribute('index') ?? '';
            buffer.write(verseText);
            buffer.write(' ');
            buffer.write('۞$verseIndex ');
            verseCount++;
          } else if (elementName == 'page_end') {
            if (buffer.isNotEmpty) {
              fullTextList.add(buffer.toString().trim());
              buffer.clear();
            }
          }
        }
      }

      // Add the last part if it exists
      if (buffer.isNotEmpty) {
        fullTextList.add(buffer.toString().trim());
      }

      // Divide text into pages based on screen size
      List<String> pagesList = _splitTextIntoPages(fullTextList);

      setState(() {
        pages = pagesList;
      });
    } catch (e) {
      print('Error loading XML: $e');
    }
  }

  String _buildSuraHeader(String? name, String? index, int verseCount) {
    return '\n\nسورة $name\n(آيات: $verseCount)\t\tرقم السورة: $index\n\n';
  }

  List<String> _splitTextIntoPages(List<String> fullTextList) {
    List<String> pagesList = [];
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );

    StringBuffer buffer = StringBuffer();
    for (String text in fullTextList) {
      textPainter.text = TextSpan(
        text: buffer.toString() + text,
        style: TextStyle(
          fontSize: 29.0,
        ),
      );

      textPainter.layout(maxWidth: screenWidth - 32); // Subtract padding

      if (textPainter.height > screenHeight - 32) {
        pagesList.add(buffer.toString().trim());
        buffer.clear();
      }

      buffer.write(text + ' ');
    }

    if (buffer.isNotEmpty) {
      pagesList.add(buffer.toString().trim());
    }

    return pagesList;
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choisissez la couleur du texte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _colorOption(Colors.white, 'Blanc'),
                _colorOption(Colors.black, 'Noir'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _colorOption(Color color, String colorName) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
      ),
      title: Text(colorName),
      onTap: () {
        setState(() {
          textColor = color;
        });
        Navigator.pop(context); // Close the dialog
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Texte du Coran'),
        backgroundColor: const Color(0xFF4CADA0),
        actions: [
          PopupMenuButton(
            surfaceTintColor: Colors.transparent,
            elevation: 2,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  onTap: _showColorPicker,
                  child: Text('Changer la couleur du texte'),
                ),
                PopupMenuItem(
                  onTap: () {},
                  child: Text('Régler la luminosité'),
                ),
                PopupMenuItem(
                  onTap: () {},
                  child: Text('Sauvegarder la page'),
                ),
                PopupMenuItem(
                  onTap: () {},
                  child: Text('Aller à la page'),
                ),
                PopupMenuItem(
                  onTap: () {},
                  child: Text('Les surates'),
                ),
              ];
            },
          ),
        ],
      ),
      body: pages.isNotEmpty
          ? PageView.builder(
              reverse: true,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4CADA0),
                        const Color(0xFF81C784)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Text(
                    pages[index],
                    style: TextStyle(
                      color: textColor,
                      fontSize: 29.0,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign:
                        TextAlign.right, // Alignement à droite pour l'arabe
                    textDirection: TextDirection.rtl,
                  ),
                );
              },
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
