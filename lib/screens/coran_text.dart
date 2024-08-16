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

      List<String> pagesList = [];
      StringBuffer buffer = StringBuffer();

      for (var element in document.descendants) {
        if (element.nodeType == xml.XmlNodeType.ELEMENT) {
          final elementName = (element as xml.XmlElement).name.toString();
          if (elementName == 'aya') {
            buffer.write((element as xml.XmlElement)
                .getAttribute('text')); // Get text attribute
            buffer.write(' '); // Add space between verses
          } else if (elementName == 'page_end') {
            if (buffer.isNotEmpty) {
              pagesList.add(buffer.toString().trim());
              buffer.clear();
            }
          }
        }
      }

      // Add the last page if it exists
      if (buffer.isNotEmpty) {
        pagesList.add(buffer.toString().trim());
      }

      setState(() {
        pages = pagesList;
      });
    } catch (e) {
      print('Error loading XML: $e');
    }
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
                _colorOption(Color.fromARGB(255, 85, 191, 210), 'Bleu clair'),
                _colorOption(Colors.blue, 'Bleu'),
                _colorOption(Colors.green, 'Vert'),
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
          /*    IconButton(
            icon: Icon(Icons.more_vert), // Trois points verticaux
            onPressed: _showColorPicker,
          ), */
          PopupMenuButton(
            surfaceTintColor: Colors.white,
            elevation: 2,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  onTap: () => {_showColorPicker},
                  child: Text('Changer la couleur du texte'),
                ),
                PopupMenuItem(
                  onTap: () => {},
                  child: Text('Régler la luminosité'),
                ),
                PopupMenuItem(
                  onTap: () => {},
                  child: Text('Sauvegarder la page'),
                ),
                PopupMenuItem(
                  onTap: () => {},
                  child: Text('Aller à la page'),
                ),
                PopupMenuItem(
                  onTap: () => {},
                  child: Text('Ajouter un décaissement'),
                ),
              ];
            },
          ),
        ],
      ),
      body: pages.isNotEmpty
          ? PageView.builder(
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
                  child: SingleChildScrollView(
                    child: Text(
                      pages[index],
                      style: TextStyle(
                        color: textColor,
                        fontSize: 29.0,
                        fontWeight: FontWeight.normal,
                      ),
                      textAlign:
                          TextAlign.right, // Alignement à droite pour l'arabe
                    ),
                  ),
                );
              },
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
