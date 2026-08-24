import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NeovaApp());
}

// ============================================================
// APPLICATION
// ============================================================

class NeovaApp extends StatelessWidget {
  const NeovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NÉOVA',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const PinPage(),
    );
  }
}

// ============================================================
// OBJECTIF
// ============================================================

class Objectif {
  String nom;
  int cible;
  int epargne;
  DateTime dateDeblocage;

  Objectif({
    required this.nom,
    required this.cible,
    required this.epargne,
    required this.dateDeblocage,
  });

  bool get debloque {
    final maintenant = DateTime.now();

    final aujourdHui = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );

    final date = DateTime(
      dateDeblocage.year,
      dateDeblocage.month,
      dateDeblocage.day,
    );

    return !aujourdHui.isBefore(date);
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'cible': cible,
      'epargne': epargne,
      'dateDeblocage': dateDeblocage.toIso8601String(),
    };
  }

  factory Objectif.fromJson(Map<String, dynamic> json) {
    return Objectif(
      nom: json['nom']?.toString() ?? '',
      cible: json['cible'] is num
          ? (json['cible'] as num).toInt()
          : 0,
      epargne: json['epargne'] is num
          ? (json['epargne'] as num).toInt()
          : 0,
      dateDeblocage: DateTime.tryParse(
            json['dateDeblocage']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

// ============================================================
// OPERATION
// ============================================================

class Operation {
  final String titre;
  final int montant;
  final bool positif;
  final DateTime date;

  Operation({
    required this.titre,
    required this.montant,
    required this.positif,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'titre': titre,
      'montant': montant,
      'positif': positif,
      'date': date.toIso8601String(),
    };
  }

  factory Operation.fromJson(Map<String, dynamic> json) {
    return Operation(
      titre: json['titre']?.toString() ?? '',
      montant: json['montant'] is num
          ? (json['montant'] as num).toInt()
          : 0,
      positif: json['positif'] == true,
      date: DateTime.tryParse(
            json['date']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

// ============================================================
// STOCKAGE NÉOVA
// ============================================================

class NeovaStorage {
  static const String pinKey = 'neova_pin_v3';
  static const String soldeKey = 'neova_solde_v3';
  static const String objectifsKey = 'neova_objectifs_v3';
  static const String historiqueKey = 'neova_historique_v3';

  static Future<SharedPreferences> get preferences async {
    return SharedPreferences.getInstance();
  }

  // ----------------------------------------------------------
  // SAUVEGARDER PIN
  // ----------------------------------------------------------

  static Future<bool> savePin(String pin) async {
    final p = await preferences;

    final resultat = await p.setString(
      pinKey,
      pin,
    );

    await p.reload();

    return resultat && p.getString(pinKey) == pin;
  }

  // ----------------------------------------------------------
  // CHARGER PIN
  // ----------------------------------------------------------

  static Future<String?> loadPin() async {
    final p = await preferences;

    await p.reload();

    return p.getString(pinKey);
  }

  // ----------------------------------------------------------
  // SAUVEGARDER TOUTES LES DONNÉES
  // ----------------------------------------------------------

  static Future<bool> saveData({
    required int solde,
    required List<Objectif> objectifs,
    required List<Operation> historique,
  }) async {
    final p = await preferences;

    final objectifsJson = jsonEncode(
      objectifs
          .map((objectif) => objectif.toJson())
          .toList(),
    );

    final historiqueJson = jsonEncode(
      historique
          .map((operation) => operation.toJson())
          .toList(),
    );

    final okSolde = await p.setInt(
      soldeKey,
      solde,
    );

    final okObjectifs = await p.setString(
      objectifsKey,
      objectifsJson,
    );

    final okHistorique = await p.setString(
      historiqueKey,
      historiqueJson,
    );

    await p.reload();

    final verificationSolde =
        p.getInt(soldeKey) == solde;

    final verificationObjectifs =
        p.getString(objectifsKey) == objectifsJson;

    final verificationHistorique =
        p.getString(historiqueKey) == historiqueJson;

    return okSolde &&
        okObjectifs &&
        okHistorique &&
        verificationSolde &&
        verificationObjectifs &&
        verificationHistorique;
  }

  // ----------------------------------------------------------
  // CHARGER TOUTES LES DONNÉES
  // ----------------------------------------------------------

  static Future<Map<String, dynamic>> loadData() async {
    final p = await preferences;

    await p.reload();

    int solde = p.getInt(soldeKey) ?? 75000;

    final List<Objectif> objectifs = [];

    final objectifsJson =
        p.getString(objectifsKey);

    if (objectifsJson != null &&
        objectifsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(objectifsJson);

        if (decoded is List) {
          for (final element in decoded) {
            if (element is Map) {
              objectifs.add(
                Objectif.fromJson(
                  Map<String, dynamic>.from(element),
                ),
              );
            }
          }
        }
      } catch (_) {}
    }

    final List<Operation> historique = [];

    final historiqueJson =
        p.getString(historiqueKey);

    if (historiqueJson != null &&
        historiqueJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(historiqueJson);

        if (decoded is List) {
          for (final element in decoded) {
            if (element is Map) {
              historique.add(
                Operation.fromJson(
                  Map<String, dynamic>.from(element),
                ),
              );
            }
          }
        }
      } catch (_) {}
    }

    return {
      'solde': solde,
      'objectifs': objectifs,
      'historique': historique,
    };
  }
}

// ============================================================
// PIN
// ============================================================

class PinPage extends StatefulWidget {
  const PinPage({super.key});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final pinController = TextEditingController();
  final confirmationController =
      TextEditingController();

  bool confirmation = false;
  bool chargement = true;
  String? pinEnregistre;

  @override
  void initState() {
    super.initState();
    chargerPin();
  }

  Future<void> chargerPin() async {
    try {
      final pin =
          await NeovaStorage.loadPin();

      if (!mounted) return;

      setState(() {
        pinEnregistre = pin;
        chargement = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        chargement = false;
      });
    }
  }

  void message(String texte) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texte),
      ),
    );
  }

  void continuer() {
    final pin =
        pinController.text.trim();

    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      message(
        'Le PIN doit contenir exactement 4 chiffres.',
      );
      return;
    }

    setState(() {
      confirmation = true;
      confirmationController.clear();
    });
  }

  Future<void> confirmer() async {
    final pin1 =
        pinController.text.trim();

    final pin2 =
        confirmationController.text.trim();

    if (!RegExp(r'^\d{4}$').hasMatch(pin2)) {
      message(
        'Le PIN doit contenir exactement 4 chiffres.',
      );
      return;
    }

    if (pin1 != pin2) {
      message(
        'Les deux PIN ne correspondent pas.',
      );
      return;
    }

    final sauvegarde =
        await NeovaStorage.savePin(pin1);

    if (!sauvegarde) {
      message(
        'Impossible de sauvegarder le PIN.',
      );
      return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const NeovaHome(),
      ),
    );
  }

  Future<void> connecter() async {
    final pin =
        pinController.text.trim();

    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      message(
        'Le PIN doit contenir exactement 4 chiffres.',
      );
      return;
    }

    final pinActuel =
        await NeovaStorage.loadPin();

    if (pinActuel == null) {
      message(
        'Aucun PIN enregistré.',
      );
      return;
    }

    if (pin != pinActuel) {
      message('PIN incorrect.');
      return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const NeovaHome(),
      ),
    );
  }

  @override
  void dispose() {
    pinController.dispose();
    confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (chargement) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final ancienUtilisateur =
        pinEnregistre != null;

    final controller = confirmation
        ? confirmationController
        : pinController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NÉOVA'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.savings,
                size: 80,
              ),
              const SizedBox(height: 25),
              const Text(
                'Bienvenue sur NÉOVA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ancienUtilisateur
                    ? 'Entre ton PIN pour accéder à NÉOVA'
                    : confirmation
                        ? 'Confirme ton PIN'
                        : 'Crée ton PIN à 4 chiffres',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: controller,
                keyboardType:
                    TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration:
                    const InputDecoration(
                  labelText: 'PIN',
                  prefixIcon:
                      Icon(Icons.lock),
                  border:
                      OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: ancienUtilisateur
                      ? connecter
                      : confirmation
                          ? confirmer
                          : continuer,
                  child: Text(
                    ancienUtilisateur
                        ? 'Accéder'
                        : confirmation
                            ? 'Confirmer'
                            : 'Continuer',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ACCUEIL
// ============================================================

class NeovaHome extends StatefulWidget {
  const NeovaHome({super.key});

  @override
  State<NeovaHome> createState() =>
      _NeovaHomeState();
}

class _NeovaHomeState
    extends State<NeovaHome> {
  int solde = 0;

  List<Objectif> objectifs = [];
  List<Operation> historique = [];

  bool chargement = true;
  bool sauvegardeEnCours = false;

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    try {
      final data =
          await NeovaStorage.loadData();

      if (!mounted) return;

      setState(() {
        solde =
            data['solde'] as int;

        objectifs =
            data['objectifs']
                as List<Objectif>;

        historique =
            data['historique']
                as List<Operation>;

        chargement = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        chargement = false;
      });

      message(
        'Erreur lors du chargement des données.',
      );
    }
  }

  Future<bool> sauvegarder() async {
    if (sauvegardeEnCours) {
      return false;
    }

    sauvegardeEnCours = true;

    try {
      final resultat =
          await NeovaStorage.saveData(
        solde: solde,
        objectifs: objectifs,
        historique: historique,
      );

      return resultat;
    } finally {
      sauvegardeEnCours = false;
    }
  }

  int get epargneTotale {
    return objectifs.fold(
      0,
      (total, objectif) =>
          total + objectif.epargne,
    );
  }

  String argent(int valeur) {
    final texte =
        valeur.toString();

    final resultat =
        StringBuffer();

    for (int i = 0;
        i < texte.length;
        i++) {
      if (i > 0 &&
          (texte.length - i) % 3 == 0) {
        resultat.write(' ');
      }

      resultat.write(texte[i]);
    }

    return '${resultat.toString()} FCFA';
  }

  String dateFormat(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void message(String texte) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(texte),
      ),
    );
  }

  // ==========================================================
  // AJOUTER ARGENT
  // ==========================================================

  Future<void> ajouterArgent() async {
    setState(() {
      solde += 10000;

      historique.insert(
        0,
        Operation(
          titre: 'Ajout d’argent',
          montant: 10000,
          positif: true,
          date: DateTime.now(),
        ),
      );
    });

    final ok = await sauvegarder();

    message(
      ok
          ? '10 000 FCFA sauvegardés.'
          : 'Erreur de sauvegarde.',
    );
  }

  // ==========================================================
  // CREER OBJECTIF
  // ==========================================================

  Future<void> creerObjectif() async {
    final nomController =
        TextEditingController();

    final cibleController =
        TextEditingController();

    DateTime? dateChoisie;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Nouvel objectif',
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    TextField(
                      controller:
                          nomController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Nom de l’objectif',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller:
                          cibleController,
                      keyboardType:
                          TextInputType.number,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Montant cible',
                        suffixText:
                            'FCFA',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          () async {
                        final date =
                            await showDatePicker(
                          context:
                              context,
                          firstDate:
                              DateTime.now(),
                          lastDate:
                              DateTime(
                            2100,
                          ),
                          initialDate:
                              DateTime.now(),
                        );

                        if (date !=
                            null) {
                          setDialogState(
                            () {
                              dateChoisie =
                                  date;
                            },
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.calendar_month,
                      ),
                      label: Text(
                        dateChoisie ==
                                null
                            ? 'Choisir la date'
                            : 'Déblocage : ${dateFormat(dateChoisie!)}',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text(
                    'Annuler',
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      () async {
                    final nom =
                        nomController
                            .text
                            .trim();

                    final cible =
                        int.tryParse(
                      cibleController
                          .text
                          .trim(),
                    );

                    if (nom.isEmpty ||
                        cible == null ||
                        cible <= 0 ||
                        dateChoisie ==
                            null) {
                      message(
                        'Remplis toutes les informations.',
                      );
                      return;
                    }

                    setState(() {
                      objectifs.add(
                        Objectif(
                          nom: nom,
                          cible: cible,
                          epargne: 0,
                          dateDeblocage:
                              dateChoisie!,
                        ),
                      );
                    });

                    final ok =
                        await sauvegarder();

                    if (!mounted)
                      return;

                    Navigator.pop(
                      dialogContext,
                    );

                    message(
                      ok
                          ? 'Objectif sauvegardé.'
                          : 'Objectif créé mais sauvegarde échouée.',
                    );
                  },
                  child:
                      const Text(
                    'Créer',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nomController.dispose();
    cibleController.dispose();
  }

  // ==========================================================
  // EPARGNER
  // ==========================================================

  Future<void> epargner(
    Objectif objectif,
  ) async {
    final controller =
        TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Épargner pour ${objectif.nom}',
          ),
          content: TextField(
            controller: controller,
            keyboardType:
                TextInputType.number,
            decoration:
                const InputDecoration(
              labelText: 'Montant',
              suffixText: 'FCFA',
              border:
                  OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed:
                  () async {
                final montant =
                    int.tryParse(
                  controller.text
                      .trim(),
                );

                if (montant == null ||
                    montant <= 0) {
                  message(
                    'Montant invalide.',
                  );
                  return;
                }

                if (montant > solde) {
                  message(
                    'Solde insuffisant.',
                  );
                  return;
                }

                if (objectif.epargne +
                        montant >
                    objectif.cible) {
                  message(
                    'La cible serait dépassée.',
                  );
                  return;
                }

                setState(() {
                  solde -= montant;

                  objectif.epargne +=
                      montant;

                  historique.insert(
                    0,
                    Operation(
                      titre:
                          'Épargne : ${objectif.nom}',
                      montant: montant,
                      positif: false,
                      date:
                          DateTime.now(),
                    ),
                  );
                });

                final ok =
                    await sauvegarder();

                if (!mounted)
                  return;

                Navigator.pop(
                  dialogContext,
                );

                message(
                  ok
                      ? '${argent(montant)} épargnés.'
                      : 'Erreur de sauvegarde.',
                );
              },
              child:
                  const Text('Épargner'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  // ==========================================================
  // RECUPERER
  // ==========================================================

  Future<void> recuperer(
    Objectif objectif,
  ) async {
    if (!objectif.debloque) {
      message(
        'Cet objectif est encore bloqué.',
      );
      return;
    }

    if (objectif.epargne <= 0) {
      message(
        'Aucune épargne à récupérer.',
      );
      return;
    }

    final montant =
        objectif.epargne;

    setState(() {
      solde += montant;

      objectif.epargne = 0;

      historique.insert(
        0,
        Operation(
          titre:
              'Récupération : ${objectif.nom}',
          montant: montant,
          positif: true,
          date: DateTime.now(),
        ),
      );
    });

    final ok =
        await sauvegarder();

    message(
      ok
          ? '${argent(montant)} récupérés.'
          : 'Erreur de sauvegarde.',
    );
  }

  // ==========================================================
  // SUPPRIMER
  // ==========================================================

  Future<void> supprimer(
    Objectif objectif,
  ) async {
    final confirmer =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Supprimer l’objectif ?',
          ),
          content: Text(
            'Voulez-vous supprimer '
            '« ${objectif.nom} » ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmer != true) {
      return;
    }

    setState(() {
      objectifs.remove(objectif);
    });

    final ok =
        await sauvegarder();

    message(
      ok
          ? 'Objectif supprimé.'
          : 'Erreur de sauvegarde.',
    );
  }

  // ==========================================================
  // BUILD ACCUEIL
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (chargement) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NÉOVA',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            creerObjectif,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Objectif',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            'Bonjour 👋',
            style: TextStyle(
              fontSize: 27,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          const Text(
            'Bienvenue dans ton espace NÉOVA.',
          ),
          const SizedBox(
            height: 20,
          ),

          // SOLDE

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    'Solde disponible',
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    argent(solde),
                    style:
                        const TextStyle(
                      fontSize: 31,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        ElevatedButton
                            .icon(
                      onPressed:
                          ajouterArgent,
                      icon: const Icon(
                        Icons.add,
                      ),
                      label:
                          const Text(
                        'Ajouter 10 000 FCFA',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          // STATISTIQUES

          Row(
            children: [
              Expanded(
                child: Card(
                  child:
                      Padding(
                    padding:
                        const EdgeInsets
                            .all(16),
                    child:
                        Column(
                      children: [
                        const Icon(
                          Icons.savings,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        const Text(
                          'Épargne',
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          argent(
                            epargneTotale,
                          ),
                          textAlign:
                              TextAlign
                                  .center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Card(
                  child:
                      Padding(
                    padding:
                        const EdgeInsets
                            .all(16),
                    child:
                        Column(
                      children: [
                        const Icon(
                          Icons.flag,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        const Text(
                          'Objectifs',
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          '${objectifs.length}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          // OBJECTIFS

          Card(
            child: ListTile(
              leading:
                  const CircleAvatar(
                child: Icon(
                  Icons.flag,
                ),
              ),
              title:
                  const Text(
                'Mes objectifs',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              subtitle:
                  const Text(
                'Voir et gérer mes objectifs',
              ),
              trailing:
                  const Icon(
                Icons
                    .arrow_forward_ios,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ObjectifsPage(
                      objectifs:
                          objectifs,
                      argent:
                          argent,
                      dateFormat:
                          dateFormat,
                      onSave:
                          epargner,
                      onRecover:
                          recuperer,
                      onDelete:
                          supprimer,
                      onCreate:
                          creerObjectif,
                    ),
                  ),
                ).then((_) {
                  if (mounted) {
                    setState(
                      () {},
                    );
                  }
                });
              },
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          const Text(
            'Dernières opérations',
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          if (historique.isEmpty)
            const Card(
              child: Padding(
                padding:
                    EdgeInsets.all(
                  20,
                ),
                child: Text(
                  'Aucune opération pour le moment.',
                ),
              ),
            ),

          ...historique
              .take(5)
              .map(
            (operation) {
              return Card(
                child:
                    ListTile(
                  leading:
                      Icon(
                    operation.positif
                        ? Icons
                            .add_circle
                        : Icons
                            .savings,
                  ),
                  title: Text(
                    operation.titre,
                  ),
                  trailing:
                      Text(
                    '${operation.positif ? '+' : '-'}'
                    '${argent(operation.montant)}',
                  ),
                ),
              );
            },
          ),

          const SizedBox(
            height: 100,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAGE OBJECTIFS
// ============================================================

class ObjectifsPage
    extends StatefulWidget {
  final List<Objectif> objectifs;
  final String Function(int)
      argent;
  final String Function(DateTime)
      dateFormat;
  final Future<void> Function()
      onCreate;
  final Future<void> Function(
      Objectif)
      onSave;
  final Future<void> Function(
      Objectif)
      onRecover;
  final Future<void> Function(
      Objectif)
      onDelete;

  const ObjectifsPage({
    super.key,
    required this.objectifs,
    required this.argent,
    required this.dateFormat,
    required this.onCreate,
    required this.onSave,
    required this.onRecover,
    required this.onDelete,
  });

  @override
  State<ObjectifsPage> createState() =>
      _ObjectifsPageState();
}

class _ObjectifsPageState
    extends State<ObjectifsPage> {
  Widget carte(
    Objectif objectif,
  ) {
    double progression = 0;

    if (objectif.cible > 0) {
      progression =
          objectif.epargne /
              objectif.cible;

      if (progression > 1) {
        progression = 1;
      }
    }

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Row(
              children: [
                Icon(
                  objectif.debloque
                      ? Icons
                          .lock_open
                      : Icons.lock,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Text(
                    objectif.nom,
                    style:
                        const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              '${widget.argent(objectif.epargne)} / '
              '${widget.argent(objectif.cible)}',
            ),

            const SizedBox(
              height: 10,
            ),

            LinearProgressIndicator(
              value: progression,
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              'Déblocage : '
              '${widget.dateFormat(objectif.dateDeblocage)}',
            ),

            const SizedBox(
              height: 12,
            ),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      () async {
                    await widget
                        .onSave(
                      objectif,
                    );

                    if (mounted) {
                      setState(
                        () {},
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.savings,
                  ),
                  label:
                      const Text(
                    'Épargner',
                  ),
                ),

                OutlinedButton(
                  onPressed:
                      () async {
                    await widget
                        .onRecover(
                      objectif,
                    );

                    if (mounted) {
                      setState(
                        () {},
                      );
                    }
                  },
                  child: Text(
                    objectif.debloque
                        ? 'Récupérer'
                        : 'Bloqué',
                  ),
                ),

                OutlinedButton(
                  onPressed:
                      () async {
                    await widget
                        .onDelete(
                      objectif,
                    );

                    if (mounted) {
                      setState(
                        () {},
                      );
                    }
                  },
                  child:
                      const Text(
                    'Supprimer',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes objectifs',
        ),
      ),
      floatingActionButton:
          FloatingActionButton
              .extended(
        onPressed:
            () async {
          await widget.onCreate();

          if (mounted) {
            setState(
              () {},
            );
          }
        },
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Nouvel objectif',
        ),
      ),
      body: widget
              .objectifs
              .isEmpty
          ? const Center(
              child: Text(
                'Aucun objectif.\n\n'
                'Appuie sur « Nouvel objectif ».',
                textAlign:
                    TextAlign.center,
              ),
            )
          : ListView(
              padding:
                  const EdgeInsets
                      .all(16),
              children: widget
                  .objectifs
                  .map(carte)
                  .toList(),
            ),
    );
  }
}
