import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter/services.dart' show rootBundle;

class QuranPage extends StatefulWidget {
  @override
  _QuranPageState createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  String quranText = '';
  List<String> pages = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Texte du Coran'),
        backgroundColor: const Color(0xFF4CADA0),
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
                        color: Colors.white,
                        fontSize: 20.0,
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
