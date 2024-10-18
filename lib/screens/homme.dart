import 'dart:convert';

import 'package:autodidact_app/screens/albums.dart';
import 'package:autodidact_app/screens/coran_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:pray_times/pray_times.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HijriCalendar hijriDate;
  late List<String> prayerTimes = [];
  late String nextPrayerTime = 'Aucune prière disponible';
  double? latitude;
  double? longitude;
  double timezone = 1;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // Vérifie si le service de localisation est activé

  @override
  void initState() {
    super.initState();
    tzData.initializeTimeZones();

    hijriDate = HijriCalendar.now();
    _scheduleImmediateNotification();

    // Charger les heures de prière sauvegardées localement en priorité
    _loadPrayerTimesFromLocal().then((_) async {
      bool serviceEnabled;
      serviceEnabled = await Geolocator.isLocationServiceEnabled();

      // Si les heures de prière sont déjà chargées localement, calculer la prochaine prière
      if (prayerTimes.isNotEmpty && !serviceEnabled) {
        _updateNextPrayerTime();
      } else {
        // Sinon, obtenir la localisation et recalculer
        _getCurrentLocation();
      }
    });
  }

  Future<void> _scheduleImmediateNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'immediate_channel_id',
      'Immediate Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    print(notificationId);
    // Afficher la notification 5 secondes dans le futur
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Il est l\'heure de la prière',
      'C\'est l\'heure',
      tz.TZDateTime.now(tz.local)
          .add(Duration(hours: 1)), // Planifier pour 5 secondes plus tard
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    print(
        'Heure actuelle: ${tz.TZDateTime.now(tz.local).add(Duration(hours: 1))}');
  }

// Charger les heures de prière depuis le stockage local
  Future<void> _loadPrayerTimesFromLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prayerTimes = prefs.getStringList('prayerTimes') ?? [];
    });
  }

  void _updateNextPrayerTime() {
    // Obtenir l'heure actuelle
    DateTime now = DateTime.now();

    // Vérifiez si toutes les prières d'aujourd'hui sont passées
    bool allPrayersPassed = true;
    for (String prayerTime in prayerTimes) {
      DateTime prayerDateTime = _convertTimeToDateTime(prayerTime, now);
      if (prayerDateTime.isAfter(now)) {
        allPrayersPassed = false;
        break; // Une prière n'est pas passée
      }
    }

    // Si toutes les prières d'aujourd'hui sont passées, ajuster pour demain
    DateTime referenceDate = allPrayersPassed
        ? now.add(Duration(days: 1)) // Demain
        : now; // Aujourd'hui

    // Parcourir les heures de prière pour trouver la prochaine prière
    for (String prayerTime in prayerTimes) {
      // Convertir l'heure de prière (format HH:mm) en DateTime pour la date de référence
      DateTime prayerDateTime =
          _convertTimeToDateTime(prayerTime, referenceDate);

      if (prayerDateTime.isAfter(now)) {
        setState(() {
          nextPrayerTime =
              "${_getPrayerName(prayerTime)} à ${prayerDateTime.toLocal().hour.toString().padLeft(2, '0')}:${prayerDateTime.toLocal().minute.toString().padLeft(2, '0')}";

          print('UpdatePrayer: $nextPrayerTime');
        });
        break;
      }
    }
  }

// Méthode pour convertir l'heure de prière (format HH:mm) en DateTime avec une date de référence
  DateTime _convertTimeToDateTime(String prayerTime, DateTime referenceDate) {
    final parts = prayerTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(referenceDate.year, referenceDate.month, referenceDate.day,
        hour, minute);
  }

// Exemple de méthode pour obtenir le nom de la prière en fonction de l'heure
  String _getPrayerName(String prayerTime) {
    List<String> prayerNames = [
      "Fajr",
      "Shrooq",
      "Dhuhr",
      "Asr",
      "Maghrib",
      "Isha"
    ];

    // Trouver l'index de la prière en utilisant la position dans prayerTimes
    int index = prayerTimes.indexOf(prayerTime);
    return prayerNames[index];
  }

  void _scheduleAllPrayerNotifications(List<DateTime> prayerTimes) {
    final prayerNames = ["Fajr", "Shrooq", "Dhuhr", "Asr", "Maghrib", "Isha"];

    for (int i = 0; i < prayerTimes.length; i++) {
      DateTime prayerTime = prayerTimes[i];
      // Vérifier si l'heure de prière est dans le futur
      if (prayerTime.isAfter(DateTime.now())) {
        print('Scheduling notification for ${prayerNames[i]} at $prayerTime');
        _schedulePrayerNotifications(
            prayerTime, prayerNames[i], i); // Passez l'index comme ID unique
      }
    }
  }

  Future<void> _schedulePrayerNotifications(
      DateTime prayerTime, String prayerName, int id) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'prayer_channel_id',
      'Prayer Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, // Utilisez un ID unique pour chaque prière
      'Il est l\'heure de la prière',
      'C\'est l\'heure de $prayerName',
      tz.TZDateTime.from(prayerTime, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Sauvegarder les heures de prière dans le stockage local
  Future<void> _savePrayerTimesToLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('prayerTimes', prayerTimes);
  }

  // Mise à jour des heures de prière et sauvegarde localement
  void _updatePrayerTimes() async {
    // Calcul des heures de prière comme tu l'as déjà
    _calculatePrayerTimes();

    // Sauvegarder les nouvelles heures localement
    await _savePrayerTimesToLocal();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifie si le service de localisation est activé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        nextPrayerTime = 'Service de localisation désactivé';
      });
      return;
    }

    // Vérifie et demande les permissions de localisation
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          nextPrayerTime = 'Permission de localisation refusée';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        nextPrayerTime = 'Permission de localisation refusée en permanence';
      });
      return;
    }

    // Obtient la position actuelle de l'utilisateur
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
      print(latitude);
      print(longitude);
      _calculatePrayerTimes();
    });
  }

  void _calculatePrayerTimes() {
    if (latitude == null || longitude == null) {
      // Si la localisation n'est pas encore disponible, retourner ou afficher un message
      setState(() {
        nextPrayerTime = 'Localisation non disponible';
        print('Aujourd\'hui: $nextPrayerTime');
      });
      return;
    }

    PrayerTimes prayers = PrayerTimes();

    prayers.setTimeFormat(prayers.Time24);
    prayers.setCalcMethod(prayers.MWL);
    prayers.setAsrJuristic(prayers.Shafii);
    prayers.setAdjustHighLats(prayers.AngleBased);

    DateTime now = DateTime.now();

    // Obtenir les heures de prière pour aujourd'hui
    final todayPrayerTimes =
        prayers.getPrayerTimes(now, latitude!, longitude!, timezone);
    print('Aujourd\'hui: $todayPrayerTimes');

    // Vérifiez si toutes les prières d'aujourd'hui sont passées
    bool allPrayersPassed = true;
    for (var prayerTime in todayPrayerTimes) {
      final parts = prayerTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      DateTime prayerDateTime =
          DateTime(now.year, now.month, now.day, hour, minute);

      if (prayerDateTime.isAfter(now)) {
        allPrayersPassed = false;
        break;
      }
    }

    // Si toutes les prières d'aujourd'hui sont passées, obtenir les heures de prière pour demain
    final times = allPrayersPassed
        ? prayers.getPrayerTimes(
            now.add(Duration(days: 1)), latitude!, longitude!, timezone)
        : todayPrayerTimes;

    // Les noms des prières dans l'ordre
    List<String> prayerNames = [
      "Fajr",
      "Shrooq",
      "Dhuhr",
      "Asr",
      "Maghrib",
      "Isha"
    ];

    // Stocker les heures de prières à partir de la liste renvoyée par getPrayerTimes
    prayerTimes = [
      times[0], // Fajr
      times[1], // Shrooq
      times[2], // Dhuhr
      times[3], // Asr
      times[4], // Maghrib
      times[5], // Isha
    ];
    // Utiliser un Set pour éviter les doublons
    Set<String> uniquePrayerTimes = Set<String>();

    // Stocker les heures de prières à partir de la liste renvoyée par getPrayerTimes
    for (var time in times) {
      uniquePrayerTimes
          .add(time); // Ajouter uniquement si ce n'est pas un doublon
    }

    prayerTimes = uniquePrayerTimes.toList(); // Convertir le Set en liste
    print(prayerTimes);

    // Calcul de la prochaine prière
    for (int i = 0; i < prayerTimes.length; i++) {
      final parts = prayerTimes[i].split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      DateTime prayerTime =
          DateTime(now.year, now.month, now.day, hour, minute);

      // Si c'est demain, ajuster l'année, le mois et le jour
      if (allPrayersPassed) {
        prayerTime = prayerTime.add(Duration(days: 1));
      }

      if (prayerTime.isAfter(now)) {
        setState(() {
          nextPrayerTime = "${prayerNames[i]} : ${prayerTimes[i]}";
          print('nextPrayerTime: $nextPrayerTime');
          _savePrayerTimesToLocal();
        });
        break;
      }
    }
  }

  List<String> _calculateDailyPrayerTimes(DateTime date) {
    PrayerTimes prayers = PrayerTimes();

    prayers.setTimeFormat(prayers.Time24);
    prayers.setCalcMethod(prayers.MWL);
    prayers.setAsrJuristic(prayers.Shafii);
    prayers.setAdjustHighLats(prayers.AngleBased);

    if (latitude == null || longitude == null) {
      return ["Localisation non disponible"];
    }

    return prayers.getPrayerTimes(date, latitude!, longitude!, timezone);
  }

  _showMonthlyPrayerTimes() {
    final today = DateTime.now();
    final firstDayOfMonth = DateTime(today.year, today.month, 1);
    final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);

    // Liste des heures de prière pour chaque jour du mois
    List<Map<String, dynamic>> monthlyPrayerTimes = [];

    // Calcule les heures de prières pour chaque jour du mois
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(today.year, today.month, day);
      List<String> times = _calculateDailyPrayerTimes(date);

      // S'assurer qu'il n'y a pas de doublons dans la liste des heures de prières
      times = times.toSet().toList(); // Supprimer les doublons
      if (times.length > 6) {
        times = times.sublist(0, 6); // Tronquer à 6 si plus d'éléments
      }

      // Ajoute les données si le nombre d'heures de prières est correct (6 prières)
      if (times.length == 6) {
        monthlyPrayerTimes.add({
          'date': date,
          'times': times,
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Heures de prières du mois',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4CADA0),
            ),
            textAlign: TextAlign.center,
          ),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: monthlyPrayerTimes.length,
              itemBuilder: (context, index) {
                final dailyTimes = monthlyPrayerTimes[index];
                final date = dailyTimes['date'] as DateTime;
                final prayerTimes = dailyTimes['times'] as List<String>;

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  child: ListTile(
                    title: Text(
                      'Jour ${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        fontFamily: 'Kitab',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CADA0),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        prayerTimes.length,
                        (i) {
                          final prayerName = [
                            "Fajr",
                            "Sunrise",
                            "Dhuhr",
                            "Asr",
                            "Maghrib",
                            "Isha"
                          ][i];

                          final prayerTime = prayerTimes[i];

                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '$prayerName: $prayerTime',
                              style: TextStyle(
                                  fontFamily: 'Kitab',
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w300),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Fermer',
                style: TextStyle(
                  fontFamily: 'Kitab',
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end, // Aligne tout à droite
          children: [
            Text(
              "اقرا".toUpperCase(),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF4CADA0), const Color(0xFF81C784)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 5),
              // Afficher la date Hijri avec un icône
              GestureDetector(
                onTap: _showHijriCalendar, // Affiche le calendrier complet
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.date_range, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      '${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear}',
                      style: TextStyle(
                        fontFamily: 'Kitab',
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Afficher la prochaine prière avec un icône
              GestureDetector(
                onTap: _showMonthlyPrayerTimes, // Affiche les heures du mois
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Prochaine prière',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                            fontFamily: 'Kitab',
                          ),
                        ),
                      ],
                    ),
                    Text(
                      textAlign: TextAlign.center,
                      ' $nextPrayerTime',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        fontFamily: 'Kitab',
                      ),
                    ),
                  ],
                ),
              ),
              /* SizedBox(height: 20),
              Text(
                'Apprenez le Saint Coran et la langue arabe de manière intuitive et efficace, à votre rythme.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18.0,
                ),
                textAlign: TextAlign.center,
              ), */
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Action pour accéder aux cours
                },
                style: ElevatedButton.styleFrom(
                  surfaceTintColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: Text(
                  'Commencer l\'apprentissage',
                  style: TextStyle(
                    fontFamily: 'Kitab',
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Action pour accéder aux cours en ligne
                },
                style: ElevatedButton.styleFrom(
                  surfaceTintColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: Text(
                  'Voir les cours en ligne',
                  style: TextStyle(
                    fontFamily: 'Kitab',
                  ),
                ),
              ),
              SizedBox(height: 40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  children: [
                    _buildCategoryCard(Icons.book, 'Coran', QuranPage()),
                    _buildCategoryCard(Icons.language, 'Langue Arabe', null),
                    _buildCategoryCard(
                        Icons.school, 'Leçons enregistrées', null),
                    _buildCategoryCard(
                        Icons.headset, 'Supports audio', AlbumListPage()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String label, Widget? action) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => action!,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40.0, color: const Color(0xFF4CADA0)),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Kitab',
                fontSize: 16.0,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showHijriCalendar() {
    // Obtenez la date actuelle
    HijriCalendar hijriDate =
        HijriCalendar.now(); // Obtenez la date Hijri actuelle
    final hijriMonth = hijriDate.hMonth; // Utilisez hMonth
    final hijriYear = hijriDate.hYear; // Utilisez hYear

    // Nombre de jours dans chaque mois Hijri (1 à 12)
    List<int> monthDays = [
      30,
      29,
      30,
      29,
      30,
      29,
      30,
      29,
      30,
      29,
      30,
      29
    ]; // Ajustez en fonction des règles du calendrier Hijri

    // Obtenez le nombre de jours dans le mois Hijri actuel
    int daysInMonth = monthDays[
        hijriMonth - 1]; // Supposons un index basé sur 1 pour les mois

    // Créez une liste de dates Hijri avec leurs dates grégoriennes correspondantes
    List<Map<String, String>> hijriDates = [];
    for (int day = 1; day <= daysInMonth; day++) {
      // Conversion en date grégorienne
      DateTime gregorianDate =
          hijriDate.hijriToGregorian(hijriYear, hijriMonth, day);

      hijriDates.add({
        'hijri': '$day ${hijriDate.getLongMonthName()} $hijriYear',
        'gregorian':
            '${gregorianDate.day} - ${gregorianDate.month} - ${gregorianDate.year}'
      });
    }

    // Affichez le calendrier Hijri
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Calendrier Hijri - $hijriYear',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: hijriDates.length,
              itemBuilder: (context, index) {
                return Card(
                  // Utilisation d'une carte pour améliorer l'apparence
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    title: Text(
                      'Hijiri:${hijriDates[index]['hijri']} \nGregorian: ${hijriDates[index]['gregorian']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Kitab',
                      ), // Style de texte
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Fermer',
                style: TextStyle(
                  fontFamily: 'Kitab',
                ),
              ),
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
