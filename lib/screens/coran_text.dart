import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class QuranPage extends StatefulWidget {
  @override
  _QuranPageState createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  List<List<Widget>> pages =
      []; // Modifié pour contenir une liste de widgets pour chaque page
  Color textColor = Colors.white;
  int currentPageIndex = 0;
  late PageController _pageController;
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    loadQuranText();
    _pageController = PageController();

    // Écouteur pour mettre à jour l'index de la page courante
    _pageController.addListener(() {
      setState(() {
        currentPageIndex = _pageController.page!.round();
      });
    });
  }

  Future<void> loadQuranText() async {
    try {
      String xmlString =
          await rootBundle.loadString('assets/quran-uthmani.xml');
      final document = xml.XmlDocument.parse(xmlString);

      List<List<Widget>> pagesList = [];
      List<Widget> currentPageWidgets = [];
      String? currentSuraName;
      String? currentSuraIndex;
      String? currentSurateAyat;
      StringBuffer buffer = StringBuffer();

      int verseCount = 0;
      bool isSuraHeaderAdded = false;

      for (var element in document.descendants) {
        if (element.nodeType == xml.XmlNodeType.ELEMENT) {
          final elementName = (element as xml.XmlElement).name.toString();

          if (elementName == 'sura') {
            // Si on a déjà un nom de sourate, on ajoute l'entête de la sourate courante
            /*   if (currentSuraName != null) {
              String suraHeader = _buildSuraHeader(
                  currentSuraName, currentSuraIndex, verseCount);
              currentPageWidgets.add(_buildSuraHeaderWidget(suraHeader));

              // Ajouter Bismillah si ce n'est pas la sourate At-Tawbah (index=9)
              if (currentSuraIndex != '9') {
                currentPageWidgets.add(_buildBismillahWidget());
              }
            } */

            currentSuraName = element.getAttribute('name');
            currentSuraIndex = element.getAttribute('index');
            currentSurateAyat = element.getAttribute('aya') ?? '';
            isSuraHeaderAdded = false; // Réinitialiser le flag
          } else if (elementName == 'aya') {
            // Ajouter l'entête de la sourate au début des versets de cette sourate
            if (!isSuraHeaderAdded && currentSuraName != null) {
              String suraHeader = _buildSuraHeader(
                  currentSuraName, currentSuraIndex, currentSurateAyat);
              currentPageWidgets.add(_buildSuraHeaderWidget(suraHeader));

              // Ajouter Bismillah si ce n'est pas la sourate At-Tawbah (index=9)
              if (currentSuraIndex != '9' && currentSuraIndex != '1') {
                currentPageWidgets.add(_buildBismillahWidget());
              }

              isSuraHeaderAdded = true; // L'entête a été ajoutée
            }

            String verseText = element.getAttribute('text') ?? '';
            String verseIndex = element.getAttribute('index') ?? '';

            Widget formattedVerse = _formatVerse(verseIndex, verseText);
            currentPageWidgets.add(formattedVerse);
            verseCount++;
          } else if (elementName == 'page_end') {
            // Ajouter la page accumulée à la liste des pages
            pagesList.add(List.from(currentPageWidgets));
            currentPageWidgets
                .clear(); // Vider les widgets de la page après un page_end
          }
        }
      }

      if (currentPageWidgets.isNotEmpty) {
        pagesList
            .add(List.from(currentPageWidgets)); // Ajouter la dernière page
      }

      setState(() {
        pages = pagesList;
      });
    } catch (e) {
      print('Error loading XML: $e');
    }
  }

// Widget pour le Bismillah
// Widget pour afficher le Bismillah
  Widget _buildBismillahWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  // Construction de l'entête de la sourate
  String _buildSuraHeader(String? name, String? index, String? verseCount) {
    return '\nسورة $name\n(آيات: $verseCount)\t\tرقم السورة: $index\n';
  }

  // Widget pour l'entête de la sourate
  Widget _buildSuraHeaderWidget(String headerText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Text(
        headerText,
        style: TextStyle(
            fontSize: 25.0, fontWeight: FontWeight.bold, color: textColor),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  // Fonction pour formater le verset avec le numéro dans un cercle
  Widget _formatVerse(String verseIndex, String verseText) {
    String arabicIndex = _convertToArabicNumeral(verseIndex);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cercle autour du numéro du verset
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: textColor, width: 2.0),
            ),
            child: Center(
              child: Text(
                arabicIndex,
                style: TextStyle(color: textColor, fontSize: 20.0),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          SizedBox(width: 10), // Espace entre le numéro et le texte du verset
          Expanded(
            child: Text(
              verseText,
              style: TextStyle(color: textColor, fontSize: 24.0),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  // Fonction pour convertir les chiffres en arabe
  String _convertToArabicNumeral(String number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.split('').map((digit) {
      return arabicNumerals[int.parse(digit)];
    }).join('');
  }

  List<List<Widget>> _splitTextIntoPages(List<Widget> fullTextList) {
    List<List<Widget>> pagesList = [];
    final screenHeight = MediaQuery.of(context).size.height;
    List<Widget> currentPage = [];

    double currentHeight = 0;

    for (Widget widget in fullTextList) {
      currentHeight +=
          _calculateWidgetHeight(widget); // Calculer la hauteur du widget

      // Si la hauteur actuelle dépasse la hauteur de l'écran, créer une nouvelle page
      if (currentHeight > screenHeight - 32) {
        pagesList.add(List.from(
            currentPage)); // Ajouter la page actuelle à la liste des pages
        currentPage.clear(); // Commencer une nouvelle page
        currentHeight =
            _calculateWidgetHeight(widget); // Réinitialiser la hauteur actuelle
      }

      currentPage.add(widget); // Ajouter le widget à la page en cours
    }

    if (currentPage.isNotEmpty) {
      pagesList.add(
          currentPage); // Ajouter la dernière page si elle contient des widgets
    }

    return pagesList; // Retourner la liste des pages
  }

  // Simuler le calcul de la hauteur d'un widget (approximatif)
  double _calculateWidgetHeight(Widget widget) {
    // Ici, vous pouvez calculer la taille du widget basé sur son type
    return 100.0; // Exemple arbitraire
  }

  Future<void> _loadSavedPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentPageIndex = prefs.getInt('savedPage') ?? 0;
    });

    // Attendre que le widget soit construit avant de sauter à la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pages.isNotEmpty) {
        _pageController
            .jumpToPage(currentPageIndex); // Aller à la page sauvegardée
      }
    });
  }

  Future<void> _saveCurrentPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('savedPage', currentPageIndex);
    Fluttertoast.showToast(msg: 'Page sauvegardée');
    print('Page sauvegardée: $currentPageIndex');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choisissez la couleur du texte'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _colorOption(Colors.white, 'Blanc', setState),
                    _colorOption(Colors.black, 'Noir', setState),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _colorOption(Color color, String colorName, StateSetter setState) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
      ),
      title: Text(colorName),
      onTap: () {
        setState(() {
          textColor = color;
          print('La couleur actuelle du texte est: $textColor');
        });
        Navigator.pop(context); // Fermer le dialogue
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coran'),
        backgroundColor: const Color(0xFF4CADA0),
        actions: [
          PopupMenuButton(
            surfaceTintColor: Colors.transparent,
            elevation: 2,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  onTap: _saveCurrentPage,
                  child: Text('Sauvegarder la page'),
                ),
                PopupMenuItem(
                  child: Text('Couleur du texte'),
                  onTap: () {
                    Future.delayed(
                      Duration(
                          milliseconds:
                              100), // Délai pour permettre au menu de se fermer
                      _showColorPicker,
                    );
                  },
                ),
              ];
            },
          ),
        ],
      ),
      body: pages.isNotEmpty
          ? PageView.builder(
              reverse: true,
              controller: _pageController,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: pages[index]
                          .map((widget) => DefaultTextStyle(
                                style: TextStyle(color: textColor),
                                child: widget,
                              ))
                          .toList(),
                    ),
                  ),
                );
              },
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
