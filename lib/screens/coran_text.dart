import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran/quran.dart' as quran;

class QuranPage extends StatefulWidget {
  @override
  _QuranPageState createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> with WidgetsBindingObserver {
  List<List<Widget>> pages =
      []; // Modifié pour contenir une liste de widgets pour chaque page
  Color textColor = Colors.black;
  int currentPageIndex = 0;
  int currentPage = 0;

  int indexCurrentSurat = 0;
  Map<int, String> suraIndexes = {};
  late PageController _pageController;
  SharedPreferences? prefs;
  double _fontSize = 25.0; // Taille de police par défaut
  String? currentSuraName;
  String? currentSura;

  bool _isAppBarVisible = false;
  Map<int, String> sourateNames = {};

  Future<void> loadSavedTextColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? savedColor = prefs.getInt('textColor');
    if (savedColor != null) {
      setState(() {
        textColor = Color(savedColor);
      });
    }
  }

  Future<void> loadQuranText() async {
    try {
      String xmlString =
          await rootBundle.loadString('assets/quran-uthmani.xml');
      final document = xml.XmlDocument.parse(xmlString);

      List<List<Widget>> pagesList = [];
      List<Widget> currentPageWidgets = [];
      String? currentSuraIndex;
      String? currentSurateAyat;
      StringBuffer buffer = StringBuffer();

      int verseCount = 0;
      bool isSuraHeaderAdded = false;

      for (var element in document.descendants) {
        if (element.nodeType == xml.XmlNodeType.ELEMENT) {
          final elementName = (element as xml.XmlElement).name.toString();

          if (elementName == 'sura') {
            currentSuraName = element.getAttribute('name');
            currentSuraIndex = element.getAttribute('index');
            currentSurateAyat = element.getAttribute('aya') ?? '';
            indexCurrentSurat = int.parse(element.getAttribute('page')!);

            // Ajoutez l'index de la sourate à la liste
            suraIndexes[indexCurrentSurat] = currentSuraName!;
            isSuraHeaderAdded = false;

            setState(() {
              sourateNames[indexCurrentSurat] = element.getAttribute('name')!;

              if ((currentPageIndex + 1) == indexCurrentSurat) {
                currentSura = element.getAttribute('name');
              }
            });
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

  // Fonction pour obtenir le nom de la sourate en fonction de la page actuelle
  String getCurrentSura(int currentPageIndex) {
    int lastSuraStartPage = 0;

    // Parcours les index de début de chaque sourate
    for (var entry in suraIndexes.entries) {
      int suraStartPage = entry.key;

      // Si la page actuelle est entre la dernière sourate et la suivante
      if (currentPageIndex >= lastSuraStartPage &&
          currentPageIndex < suraStartPage) {
        return suraIndexes[lastSuraStartPage] ?? "Nom de sourate non trouvé";
      }

      // Met à jour le dernier début de sourate
      lastSuraStartPage = suraStartPage;
    }

    // Si la page est après la dernière sourate dans la liste
    return suraIndexes[lastSuraStartPage] ?? "Nom de sourate non trouvé";
  }

  void _onPageChanged(int pageIndex) {
    setState(() {
      currentPageIndex = pageIndex;
      _saveOnLeaveCurrentPage(currentPageIndex + 1);

      // Mettre à jour le nom de la sourate en fonction de la page actuelle
      currentSura = getCurrentSura(currentPageIndex + 1);

      print('Sourate actuelle: $currentSura');
    });
  }

  Future<void> _saveOnLeaveCurrentPage(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('savedOnLeavePage', currentPageIndex);
    print('Page sauvegardée: $currentPageIndex');
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentPageIndex);
    loadSavedTextColor(); // Charger la couleur sauvegardée
    loadQuranText();
    _loadOnLeavePage();
  }

// Widget pour afficher le Bismillah
  Widget _buildBismillahWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        style: TextStyle(
          fontSize: _fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: 'Kitab',
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  int getHizbNumber(int suraIndex, int ayaIndex) {
    // Exemple simplifié, à adapter selon votre logique et structure
    int hizb = ((suraIndex * 286 + ayaIndex) / (6236 / 60)).ceil();
    return hizb;
  }

  // Construction de l'entête de la sourate
  String _buildSuraHeader(String? name, String? index, String? verseCount) {
    return '\nسورة $name\n(آيات: $verseCount)\t\tرقم السورة: $index';
  }

  // Widget pour l'entête de la sourate
  Widget _buildSuraHeaderWidget(String headerText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Text(
        headerText,
        style: TextStyle(
          fontSize: 30.0,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: 'Kitab',
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  // Fonction pour formater le verset avec le numéro dans un cercle
  Widget _formatVerse(String verseIndex, String verseText) {
    String arabicIndex = _convertToArabicNumeral(verseIndex);

    return Padding(
      padding: EdgeInsets.only(top: _isAppBarVisible ? 8.0 : 40, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              verseText,
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: textColor,
                fontSize: _fontSize,
                fontFamily: 'Kitab',
                fontWeight: FontWeight.w300,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(
              width: 10), // Espace entre le numéro et le texte du verset

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
                style: TextStyle(
                  color: textColor,
                  fontSize: 20.0,
                  fontFamily: 'Kitab',
                ),
                textDirection: TextDirection.rtl,
              ),
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
  }

  Future<void> _loadOnLeavePage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentPageIndex = prefs.getInt('savedOnLeavePage') ?? 0;
      print(currentPageIndex);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 1400), () {
        if (pages.isNotEmpty && _pageController.hasClients) {
          _pageController.jumpToPage(currentPageIndex);
        }
      });
    });
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
          title: const Text('Choisissez la couleur du texte'),
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
      onTap: () async {
        setState(() {
          textColor = color;
        });
        // Enregistrer la couleur dans SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('textColor', color.value);
        loadQuranText(); // Recharge le texte du Coran
        Navigator.pop(context); // Fermer le dialogue
      },
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double tempFontSize =
            _fontSize; // Utilisation d'une variable temporaire pour la mise à jour

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Taille des écritures'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ajustez la taille des écritures',
                    style: TextStyle(fontSize: tempFontSize),
                  ),
                  Slider(
                    min: 10.0,
                    max: 40.0,
                    value: tempFontSize,
                    divisions: 10,
                    label: tempFontSize.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        tempFontSize =
                            value; // Met à jour la taille temporaire dans le dialogue
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _fontSize =
                          tempFontSize; // Met à jour la taille globale quand l'utilisateur confirme
                    });
                    loadQuranText();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        setState(() {});
      },
      child: Scaffold(
        appBar: _isAppBarVisible
            ? AppBar(
                title: Text(
                  currentSura ?? 'Coran',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.black87,
                centerTitle: true,
                actions: [
                  PopupMenuButton<int>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ), // Icône des trois points dans l'AppBar
                    elevation: 5,
                    color: Colors.black87,
                    offset: const Offset(0,
                        kToolbarHeight), // Positionner le menu juste en dessous de l'AppBar
                    itemBuilder: (BuildContext context) {
                      return [
                        const PopupMenuItem(
                          value: 1,
                          child: SizedBox(
                            width: 150.0, // Longueur fixe
                            child: ListTile(
                              leading:
                                  Icon(Icons.list_alt, color: Colors.white),
                              title: Text(
                                'Liste des sourates',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 2,
                          child: SizedBox(
                            width: 150.0, // Longueur fixe
                            child: ListTile(
                              leading:
                                  Icon(Icons.bookmark, color: Colors.white),
                              title: Text(
                                'Sauvegarder la page',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 3,
                          child: SizedBox(
                            width: 150.0, // Longueur fixe
                            child: ListTile(
                              leading: Icon(Icons.restore, color: Colors.white),
                              title: Text(
                                'Aller à la page sauvegardée',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 4,
                          child: SizedBox(
                            width: 150.0, // Longueur fixe
                            child: ListTile(
                              leading:
                                  Icon(Icons.menu_book, color: Colors.white),
                              title: Text(
                                'Liste des pages',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const PopupMenuDivider(),

                        // Ajout de l'option "Taille des écritures"
                        const PopupMenuItem(
                          value: 5,
                          child: SizedBox(
                            width: 150.0, // Longueur fixe
                            child: ListTile(
                              leading:
                                  Icon(Icons.text_fields, color: Colors.white),
                              title: Text(
                                'Taille des écritures',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ];
                    },
                    onSelected: (int value) {
                      switch (value) {
                        case 1:
                          _showSuraList(); // Afficher la liste des sourates
                          break;
                        case 2:
                          _saveCurrentPage(); // Sauvegarder la page
                          break;
                        case 3:
                          setState(() {
                            _loadSavedPage(); // Aller à la page sauvegardée
                          });
                          break;
                        case 4:
                          _showPageList();
                          break;
                        case 5:
                          _showFontSizeDialog(); // Afficher la boîte de dialogue de taille des écritures
                          break;
                      }
                    },
                  ),
                ],
              )
            : null,
        body: GestureDetector(
          onTap: () {
            setState(() {
              _isAppBarVisible = !_isAppBarVisible;
            });
          },
          child: pages.isNotEmpty
              ? PageView.builder(
                  reverse: true,
                  onPageChanged: _onPageChanged,
                  controller: _pageController,
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Theme.of(context).colorScheme.background,
                      /*  decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4CADA0), Color(0xFF81C784)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ), */
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: pages[index]
                              .map((widget) => DefaultTextStyle(
                                    style: TextStyle(
                                        color: textColor, fontSize: _fontSize),
                                    child: widget,
                                  ))
                              .toList(),
                        ),
                      ),
                    );
                  },
                )
              : const Center(child: CircularProgressIndicator()),
        ),
        bottomNavigationBar: _isAppBarVisible
            ? BottomAppBar(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Page ${currentPageIndex + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  // Nouvelle méthode pour récupérer la liste des sourates
  Future<List<Map<String, String>>> _loadSuraList() async {
    try {
      String xmlString =
          await rootBundle.loadString('assets/quran-uthmani.xml');
      final document = xml.XmlDocument.parse(xmlString);

      List<Map<String, String>> suraList = [];

      for (var element in document.findAllElements('sura')) {
        String suraIndex = element.getAttribute('index') ?? '';
        String suraName = element.getAttribute('name') ?? '';
        String suraAyat = element.getAttribute('aya') ?? '';
        String pageStart = element.getAttribute('page') ?? '';

        suraList.add({
          'index': suraIndex,
          'name': suraName,
          'ayat': suraAyat,
          'page': pageStart,
        });
      }

      return suraList;
    } catch (e) {
      print('Error loading XML: $e');
      return [];
    }
  }

  void _navigateToSura(int index) {
    print('Navigating to page: $index'); // Ajout d'un log pour le débogage
    print(pages.length);
    if (index >= 0 && index <= pages.length) {
      _pageController.jumpToPage(index - 1);
      Navigator.pop(context); // Ferme le dialogue après la sélection
    } else {
      print('Index hors limites: $index'); // Log pour index hors limites
    }
  }

  void _showSuraList() async {
    List<Map<String, String>> suraList = await _loadSuraList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Liste des sourates'),
          content: Container(
            width: double.maxFinite,
            child: ListView.separated(
              separatorBuilder: (context, index) => Divider(),
              itemCount: suraList.length,
              itemBuilder: (BuildContext context, int index) {
                Map<String, String> sura = suraList[index];
                return ListTile(
                  onTap: () {
                    String? pageValue = suraList[index]['page'];
                    int pageIndex = 0;

                    if (pageValue != null && pageValue.isNotEmpty) {
                      if (int.tryParse(pageValue) != null) {
                        pageIndex = int.parse(pageValue);
                      } else {
                        print(
                            'Erreur : La valeur de la page n\'est pas un nombre valide : $pageValue');
                        return; // Gestion de l'erreur
                      }
                    }
                    _navigateToSura(pageIndex);
                  },
                  leading: Text(
                    sura['index'] ?? '',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontFamily: 'Kitab'),
                  ),
                  title: Text(
                    'سورة ${sura['name'] ?? ''}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontFamily: 'Kitab'),
                  ),
                  subtitle: Text(
                    'Nombre de versets : ${sura['ayat']}\nPage : ${sura['page']}',
                    style: TextStyle(
                      fontFamily: 'Kitab',
                    ),
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Fonction pour naviguer vers une page
  void _navigateToPage(int index) {
    if (index >= 1 && index <= 604) {
      _pageController.jumpToPage(index - 1); // Navigue vers la page
      Navigator.pop(context); // Ferme le dialogue après la sélection
    } else {
      print('Index hors limites: $index'); // Gérer les erreurs d'index
    }
  }

// Fonction pour obtenir le nom de la sourate en fonction de la page actuelle
  String getSuraNameForPage(int pageIndex) {
    String? lastSuraName;
    int lastSuraIndex = 0;

    for (var entry in suraIndexes.entries) {
      int suraStartPage = entry.key;
      if (pageIndex >= lastSuraIndex && pageIndex < suraStartPage) {
        return sourateNames[lastSuraIndex] ?? "Sourate inconnue";
      }
      lastSuraIndex = suraStartPage;
    }

    // Si la page dépasse la dernière sourate dans la liste
    return sourateNames[lastSuraIndex] ?? "Sourate inconnue";
  }

// Fonction pour afficher la liste des pages
  void _showPageList() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Liste des pages'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: 604, // Nombre total de pages dans le Coran
              itemBuilder: (BuildContext context, int index) {
                int pageNumber = index + 1;

                // Obtenir le nom de la sourate pour la page actuelle
                String suraName = getSuraNameForPage(pageNumber);
                String suraIndex = suraIndexes.keys
                    .firstWhere((key) => suraIndexes[key] == suraName)
                    .toString();

                return ListTile(
                  onTap: () {
                    _navigateToPage(
                        pageNumber); // Naviguer vers la page sélectionnée
                  },
                  leading: Text(
                    textAlign: TextAlign.center,
                    'Page $pageNumber',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Kitab'),
                  ),
                  title: Text(
                    textAlign: TextAlign.center,
                    'سورة $suraName',
                    style: TextStyle(
                      fontFamily: 'Kitab',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  /*  subtitle: Text(
                    'Index de la sourate : $suraIndex',
                    style: TextStyle(fontFamily: 'Kitab'),
                  ), */
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
