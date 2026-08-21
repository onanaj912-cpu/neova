import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const NeovaApp());
}

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
// MODÈLE OBJECTIF
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
      nom: json['nom'] as String,
      cible: json['cible'] as int,
      epargne: json['epargne'] as int,
      dateDeblocage: DateTime.parse(
        json['dateDeblocage'] as String,
      ),
    );
  }
}

// ============================================================
// MODÈLE HISTORIQUE
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
      titre: json['titre'] as String,
      montant: json['montant'] as int,
      positif: json['positif'] as bool,
      date: DateTime.parse(
        json['date'] as String,
      ),
    );
  }
}

// ============================================================
// APPLICATION PRINCIPALE
// ============================================================

class NeovaHome extends StatefulWidget {
  const NeovaHome({super.key});

  @override
  State<NeovaHome> createState() => _NeovaHomeState();
}

class _NeovaHomeState extends State<NeovaHome> {
  int solde = 75000;

  List<Objectif> objectifs = [
    Objectif(
      nom: 'Téléphone',
      cible: 150000,
      epargne: 90000,
      dateDeblocage: DateTime(2026, 12, 30),
    ),
    Objectif(
      nom: 'Maison',
      cible: 1000000,
      epargne: 150000,
      dateDeblocage: DateTime(2028, 12, 30),
    ),
  ];

  List<Operation> historique = [];

  bool chargement = true;

  int get epargneTotale {
    return objectifs.fold(
      0,
      (total, objectif) => total + objectif.epargne,
    );
  }

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  // ==========================================================
  // CHARGER LES DONNÉES
  // ==========================================================

  Future<void> chargerDonnees() async {
    final prefs = await SharedPreferences.getInstance();

    final donneesInitialisees =
        prefs.getBool('neova_donnees_initialisees') ?? false;

    if (donneesInitialisees) {
      final soldeSauvegarde =
          prefs.getInt('neova_solde');

      final objectifsSauvegardes =
          prefs.getString('neova_objectifs');

      final historiqueSauvegarde =
          prefs.getString('neova_historique');

      if (soldeSauvegarde != null) {
        solde = soldeSauvegarde;
      }

      if (objectifsSauvegardes != null) {
        final List<dynamic> liste =
            jsonDecode(objectifsSauvegardes);

        objectifs = liste
            .map(
              (element) => Objectif.fromJson(
                Map<String, dynamic>.from(element),
              ),
            )
            .toList();
      }

      if (historiqueSauvegarde != null) {
        final List<dynamic> liste =
            jsonDecode(historiqueSauvegarde);

        historique = liste
            .map(
              (element) => Operation.fromJson(
                Map<String, dynamic>.from(element),
              ),
            )
            .toList();
      }
    } else {
      await sauvegarderDonnees();
    }

    if (!mounted) return;

    setState(() {
      chargement = false;
    });
  }

  // ==========================================================
  // SAUVEGARDER LES DONNÉES
  // ==========================================================

  Future<void> sauvegarderDonnees() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      'neova_solde',
      solde,
    );

    await prefs.setString(
      'neova_objectifs',
      jsonEncode(
        objectifs
            .map((objectif) => objectif.toJson())
            .toList(),
      ),
    );

    await prefs.setString(
      'neova_historique',
      jsonEncode(
        historique
            .map((operation) => operation.toJson())
            .toList(),
      ),
    );

    await prefs.setBool(
      'neova_donnees_initialisees',
      true,
    );
  }

  String argent(int valeur) {
    final texte = valeur.toString();
    final resultat = StringBuffer();

    for (int i = 0; i < texte.length; i++) {
      if (i > 0 && (texte.length - i) % 3 == 0) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texte)),
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

    await sauvegarderDonnees();

    message('10 000 FCFA ajoutés.');
  }

  // ==========================================================
  // CRÉER OBJECTIF
  // ==========================================================

  Future<void> creerObjectif() async {
    final nomController = TextEditingController();
    final cibleController = TextEditingController();
    DateTime? dateChoisie;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nouvel objectif'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l’objectif',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cibleController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant cible',
                        suffixText: 'FCFA',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );

                        if (date != null) {
                          setDialogState(() {
                            dateChoisie = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        dateChoisie == null
                            ? 'Choisir la date de déblocage'
                            : 'Déblocage : ${dateFormat(dateChoisie!)}',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nom = nomController.text.trim();

                    final cible = int.tryParse(
                      cibleController.text.trim(),
                    );

                    if (nom.isEmpty ||
                        cible == null ||
                        cible <= 0 ||
                        dateChoisie == null) {
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
                          dateDeblocage: dateChoisie!,
                        ),
                      );
                    });

                    await sauvegarderDonnees();

                    Navigator.pop(dialogContext);
                    message('Objectif créé.');
                  },
                  child: const Text('Créer'),
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
  // ÉPARGNER
  // ==========================================================

  Future<void> epargner(Objectif objectif) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Épargner pour ${objectif.nom}',
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant',
              suffixText: 'FCFA',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final montant = int.tryParse(
                  controller.text.trim(),
                );

                if (montant == null || montant <= 0) {
                  message('Montant invalide.');
                  return;
                }

                if (montant > solde) {
                  message('Solde insuffisant.');
                  return;
                }

                if (objectif.epargne + montant >
                    objectif.cible) {
                  message('La cible serait dépassée.');
                  return;
                }

                setState(() {
                  solde -= montant;
                  objectif.epargne += montant;

                  historique.insert(
                    0,
                    Operation(
                      titre:
                          'Épargne : ${objectif.nom}',
                      montant: montant,
                      positif: false,
                      date: DateTime.now(),
                    ),
                  );
                });

                await sauvegarderDonnees();

                Navigator.pop(dialogContext);

                message(
                  '${argent(montant)} épargnés.',
                );
              },
              child: const Text('Épargner'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  // ==========================================================
  // RÉCUPÉRER
  // ==========================================================

  Future<void> recuperer(Objectif objectif) async {
    if (!objectif.debloque) {
      message('Cet objectif est encore bloqué.');
      return;
    }

    if (objectif.epargne == 0) {
      message('Aucune épargne à récupérer.');
      return;
    }

    final montant = objectif.epargne;

    setState(() {
      solde += montant;
      objectif.epargne = 0;

      historique.insert(
        0,
        Operation(
          titre: 'Récupération : ${objectif.nom}',
          montant: montant,
          positif: true,
          date: DateTime.now(),
        ),
      );
    });

    await sauvegarderDonnees();

    message('${argent(montant)} récupérés.');
  }

  // ==========================================================
  // SUPPRIMER
  // ==========================================================

  Future<void> supprimer(Objectif objectif) async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Supprimer l’objectif ?',
          ),
          content: Text(
            'Voulez-vous supprimer « ${objectif.nom} » ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmer == true) {
      setState(() {
        objectifs.remove(objectif);
      });

      await sauvegarderDonnees();

      message('Objectif supprimé.');
    }
  }

  // ==========================================================
  // PAGE ACCUEIL
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (chargement) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NÉOVA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: creerObjectif,
        icon: const Icon(Icons.add),
        label: const Text('Objectif'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Bonjour 👋',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bienvenue dans ton espace NÉOVA.',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),

          // SOLDE

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Solde disponible',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    argent(solde),
                    style: const TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: ajouterArgent,
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Ajouter 10 000 FCFA',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          // STATISTIQUES

          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.savings,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text('Épargne'),
                        const SizedBox(height: 5),
                        Text(
                          argent(epargneTotale),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.flag,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text('Objectifs'),
                        const SizedBox(height: 5),
                        Text(
                          '${objectifs.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,

                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ACCÈS OBJECTIFS

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.flag),
              ),
              title: const Text(
                'Mes objectifs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Voir et gérer mes objectifs',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ObjectifsPage(
                      objectifs: objectifs,
                      argent: argent,
                      dateFormat: dateFormat,
                      onCreate: creerObjectif,
                      onSave: epargner,
                      onRecover: recuperer,
                      onDelete: supprimer,
                    ),
                  ),
                ).then((_) {
                  setState(() {});
                });
              },
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Dernières opérations',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          if (historique.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Aucune opération pour le moment.',
                ),
              ),
            ),

          ...historique.take(5).map(
            (operation) {
              return Card(
                child: ListTile(
                  leading: Icon(
                    operation.positif
                        ? Icons.add_circle
                        : Icons.savings,
                  ),
                  title: Text(operation.titre),
                  trailing: Text(
                    '${operation.positif ? '+' : '-'}'
                    '${argent(operation.montant)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ============================================================
// PAGE OBJECTIFS
// ============================================================

class ObjectifsPage extends StatefulWidget {
  final List<Objectif> objectifs;
  final String Function(int) argent;
  final String Function(DateTime) dateFormat;
  final Future<void> Function() onCreate;
  final Future<void> Function(Objectif) onSave;
  final Future<void> Function(Objectif) onRecover;
  final Future<void> Function(Objectif) onDelete;

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
  Widget carte(Objectif objectif) {
    double progression = 0;

    if (objectif.cible > 0) {
      progression =
          objectif.epargne / objectif.cible;

      if (progression > 1) {
        progression = 1;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  objectif.debloque
                      ? Icons.lock_open
                      : Icons.lock,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    objectif.nom,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.argent(objectif.epargne)} / '
              '${widget.argent(objectif.cible)}',
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progression,
            ),
            const SizedBox(height: 10),
            Text(
              'Déblocage : '
              '${widget.dateFormat(objectif.dateDeblocage)}',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await widget.onSave(objectif);
                    setState(() {});
                  },
                  icon: const Icon(Icons.savings),
                  label: const Text('Épargner'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await widget.onRecover(objectif);
                    setState(() {});
                  },
                  child: Text(
                    objectif.debloque
                        ? 'Récupérer'
                        : 'Bloqué',
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await widget.onDelete(objectif);
                    setState(() {});
                  },
                  child: const Text('Supprimer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes objectifs'),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () async {
          await widget.onCreate();
          setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvel objectif'),
      ),
      body: widget.objectifs.isEmpty
          ? const Center(
              child: Text(
                'Aucun objectif.\n\n'
                'Appuie sur « Nouvel objectif ».',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: widget.objectifs
                  .map(carte)
                  .toList(),
            ),
    );
  }
}

// ============================================================
// PAGE PIN
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

  // ==========================================================
  // CHARGER LE PIN
  // ==========================================================

  Future<void> chargerPin() async {
    final prefs =
        await SharedPreferences.getInstance();

    final pin = prefs.getString('neova_pin');

    if (!mounted) return;

    setState(() {
      pinEnregistre = pin;
      chargement = false;
    });
  }

  // ==========================================================
  // SAUVEGARDER LE PIN
  // ==========================================================

  Future<void> sauvegarderPin(String pin) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'neova_pin',
      pin,
    );
  }

  void message(String texte) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texte)),
    );
  }

  // ==========================================================
  // PREMIER PIN
  // ==========================================================

  void continuer() {
    final pin = pinController.text.trim();

    if (pin.length != 4 ||
        int.tryParse(pin) == null) {
      message(
        'Le PIN doit contenir exactement 4 chiffres.',
      );
      return;
    }

    setState(() {
      confirmation = true;
    });
  }

  // ==========================================================
  // CONFIRMER LE PREMIER PIN
  // ==========================================================

  Future<void> confirmer() async {
    final pin1 = pinController.text.trim();

    final pin2 =
        confirmationController.text.trim();

    if (pin2.length != 4 ||
        int.tryParse(pin2) == null) {
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

    await sauvegarderPin(pin1);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const NeovaHome(),
      ),
    );
  }

  // ==========================================================
  // CONNEXION AVEC PIN EXISTANT
  // ==========================================================

  Future<void> connecter() async {
    final pin = pinController.text.trim();

    if (pin.length != 4 ||
        int.tryParse(pin) == null) {
      message(
        'Le PIN doit contenir exactement 4 chiffres.',
      );
      return;
    }

    if (pin != pinEnregistre) {
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

    final bool ancienUtilisateur =
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
                style: const TextStyle(
                  fontSize: 17,
                ),
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
