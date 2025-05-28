import 'package:flutter/material.dart';
import '../models/item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class MenuService extends ChangeNotifier {
  List<Item> _plats = [];
  List<Item> _entrees = [];
  List<Item> _desserts = [];
  List<Item> _boissons = [];
  List<Item> _accompagnements = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  List<Item> get plats => _plats;
  List<Item> get entrees => _entrees;
  List<Item> get desserts => _desserts;
  List<Item> get boissons => _boissons;
  List<Item> get accompagnements => _accompagnements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> _categoriesApi = [];
  List<Map<String, dynamic>> get categoriesApi => _categoriesApi;

  MenuService() {
    loadMenuData();
  }

  Future<void> loadMenuData() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // 1. Load hardcoded data first (with images)
      await _loadHardcodedData();
      
      // 2. Load API data and merge (without overwriting existing items with images)
      await _loadApiData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur lors du chargement: $e';
      notifyListeners();
      debugPrint('MenuService error: $e');
    }
  }

   Future<void> _loadHardcodedData() async {
    await Future.delayed(const Duration(milliseconds: 300));
        final platsData = [
      {
        'id': '201',
        'nom': 'Couscous Poulet',
        'sous_categorie': 'Couscous',
        'prix': 750,
        'description': 'Semoule et morceaux de poulet',
        'ingredients': 'semoule, poulet fermier, carottes, navets, courgettes, pois chiches, épices',
        'image': 'assets/images/Plats/couscous_poulet.jpg',
        'pointsFidelite': 2,
      },
            {
        'id': '202',
        'nom': 'Couscous Agneau',
        'sous_categorie': 'Couscous',
        'prix': 1000,
        'description': 'Semoule et morceaux d\'agneau',
        'ingredients': 'semoule, agneau, carottes, navets, pois chiches, épices',
        'image': 'assets/images/Plats/couscous_agneau.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '203',
        'nom': 'Couscous Merguez',
        'sous_categorie': 'Couscous',
        'prix': 900,
        'description': 'Semoule et saucisses merguez',
        'ingredients': 'semoule, merguez, pois chiches, légumes, épices',
        'image': 'assets/images/Plats/couscous_merguez.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '204',
        'nom': 'Couscous Poisson',
        'sous_categorie': 'Couscous',
        'prix': 850,
        'description': 'Semoule et poisson en sauce',
        'ingredients': 'semoule, filets de poisson, légumes, épices',
        'image': 'assets/images/Plats/couscous_poisson.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '205',
        'nom': 'Couscous Végétarien',
        'sous_categorie': 'Couscous',
        'prix': 700,
        'description': 'Semoule et légumes variés',
        'ingredients': 'semoule, carottes, courgettes, navets, pois chiches, épices',
        'image': 'assets/images/Plats/couscous_vegetarien.jpg',
        'pointsFidelite': 1,
      },

      // Tagines
      {
        'id': '206',
        'nom': 'Tagine Poulet Citron',
        'sous_categorie': 'Tagine',
        'prix': 3200,
        'description': 'Poulet, citron confit et olives',
        'ingredients': 'poulet, citron confit, olives, ail, oignon, coriandre, épices',
        'image': 'assets/images/Plats/tagine_poulet.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '207',
        'nom': 'Tagine Agneau Pruneaux',
        'sous_categorie': 'Tagine',
        'prix': 3400,
        'description': 'Agneau aux pruneaux et amandes',
        'ingredients': 'agneau, pruneaux, amandes, miel, épices',
        'image': 'assets/images/Plats/tagine_agneau.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '208',
        'nom': 'Tagine Kefta',
        'sous_categorie': 'Tagine',
        'prix': 2900,
        'description': 'Boulettes de viande en sauce tomate',
        'ingredients': 'bœuf haché, oignon, ail, tomates, coriandre, épices',
        'image': 'assets/images/Plats/tagine_kefta.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '209',
        'nom': 'Tagine Poisson',
        'sous_categorie': 'Tagine',
        'prix': 3100,
        'description': 'Poisson aux légumes',
        'ingredients': 'filet de poisson, tomates, poivrons, oignon, ail, coriandre, épices',
        'image': 'assets/images/Plats/tagine_poisson.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '210',
        'nom': 'Tagine Légumes',
        'sous_categorie': 'Tagine',
        'prix': 2500,
        'description': 'Gratin de légumes aux épices',
        'ingredients': 'aubergines, courgettes, carottes, tomates, oignon, épices',
        'image': 'assets/images/Plats/tagine_legumes.jpg',
        'pointsFidelite': 1,
      },

      // Viandes
      {
        'id': '211',
        'nom': 'Steak Haché',
        'sous_categorie': 'Viande',
        'prix': 2200,
        'description': 'Steak de bœuf grillé, sauce au poivre',
        'ingredients': 'bœuf haché, œuf, chapelure, poivre, crème, beurre',
        'image': 'assets/images/Plats/steak_hache.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '212',
        'nom': 'Côtelettes d\'Agneau',
        'sous_categorie': 'Viande',
        'prix': 2800,
        'description': 'Côtelettes marinées',
        'ingredients': 'côtelettes d\'agneau, ail, romarin, huile d\'olive, sel, poivre',
        'image': 'assets/images/Plats/cotelettes_agneau.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '213',
        'nom': 'Brochette de Poulet',
        'sous_categorie': 'Viande',
        'prix': 2000,
        'description': 'Poulet mariné yaourt-épicé',
        'ingredients': 'blanc de poulet, yaourt, paprika, cumin, ail, huile',
        'image': 'assets/images/Plats/brochette_poulet.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '214',
        'nom': 'Brochette de Kefta',
        'sous_categorie': 'Viande',
        'prix': 2200,
        'description': 'Boulettes merguez maison',
        'ingredients': 'viande hachée, paprika, cumin, coriandre, piment',
        'image': 'assets/images/Plats/brochette_kefta.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '215',
        'nom': 'Brochette d\'Agneau',
        'sous_categorie': 'Viande',
        'prix': 2400,
        'description': 'Morceaux d\'agneau grillés',
        'ingredients': 'agneau, ail, herbes, huile d\'olive',
        'image': 'assets/images/Plats/brochette_agneau.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '216',
        'nom': 'Brochette de Dinde',
        'sous_categorie': 'Viande',
        'prix': 1800,
        'description': 'Dinde marinée aux herbes',
        'ingredients': 'dinde, ail, thym, huile d\'olive',
        'image': 'assets/images/Plats/brochette_dinde.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '217',
        'nom': 'Assiette Mixte',
        'sous_categorie': 'Viande',
        'prix': 3000,
        'description': 'Sélection de grillades variées',
        'ingredients': 'agneau, poulet, merguez, épices',
        'image': 'assets/images/Plats/assiette_mixte.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '218',
        'nom': 'Merguez Grillée',
        'sous_categorie': 'Viande',
        'prix': 1200,
        'description': 'Saucisse piquante',
        'ingredients': 'merguez, épices',
        'image': 'assets/images/Plats/merguez.jpg',
        'pointsFidelite': 1,
      },

      // Poissons
      {
        'id': '219',
        'nom': 'Filet de Dorade',
        'sous_categorie': 'Poisson',
        'prix': 1500,
        'description': 'Dorade au four, citron et herbes',
        'ingredients': 'filet de dorade, citron, thym, ail, huile d\'olive',
        'image': 'assets/images/Plats/dorade.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '220',
        'nom': 'Calamars Grillés',
        'sous_categorie': 'Poisson',
        'prix': 2500,
        'description': 'Calamars à l\'ail et persil',
        'ingredients': 'calamars, ail, persil, huile d\'olive, citron',
        'image': 'assets/images/Plats/calamars.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '221',
        'nom': 'Crevettes Chermoula',
        'sous_categorie': 'Poisson',
        'prix': 3200,
        'description': 'Crevettes marinées et grillées',
        'ingredients': 'crevettes, coriandre, persil, cumin, paprika, ail, huile',
        'image': 'assets/images/Plats/crevettes.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '222',
        'nom': 'Saumon Grillé',
        'sous_categorie': 'Poisson',
        'prix': 1800,
        'description': 'Saumon au four, citron et aneth',
        'ingredients': 'saumon, citron, aneth, sel, poivre',
        'image': 'assets/images/Plats/saumon.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '223',
        'nom': 'Tilapia Rôti',
        'sous_categorie': 'Poisson',
        'prix': 1400,
        'description': 'Tilapia et légumes',
        'ingredients': 'tilapia, tomates, oignon, herbes, épices',
        'image': 'assets/images/Plats/tilapia.jpg',
        'pointsFidelite': 2,
      },

      // Végétarien
      {
        'id': '224',
        'nom': 'Moussaka',
        'sous_categorie': 'Végétarien',
        'prix': 1000,
        'description': 'Gratin d\'aubergines et pommes de terre',
        'ingredients': 'aubergines, pommes de terre, tomates, oignon, ail, épices',
        'image': 'assets/images/Plats/moussaka.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '225',
        'nom': 'Shakshouka',
        'sous_categorie': 'Végétarien',
        'prix': 400,
        'description': 'Tomates, poivrons et œufs pochés',
        'ingredients': 'tomates, poivrons, œufs, oignon, ail, cumin, paprika',
        'image': 'assets/images/Plats/shakshouka.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '226',
        'nom': 'Falafel',
        'sous_categorie': 'Végétarien',
        'prix': 700,
        'description': 'Boulettes de pois chiches frites',
        'ingredients': 'pois chiches, oignon, ail, coriandre, persil, épices',
        'image': 'assets/images/Plats/falafel.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '227',
        'nom': 'Couscous Sec',
        'sous_categorie': 'Végétarien',
        'prix': 300,
        'description': 'Semoule nature',
        'ingredients': 'semoule, sel',
        'image': 'assets/images/Plats/couscous_sec.jpg',
        'pointsFidelite': 0,
      },
      {
        'id': '228',
        'nom': 'Gratin Courgettes',
        'sous_categorie': 'Végétarien',
        'prix': 600,
        'description': 'Courgettes gratinées',
        'ingredients': 'courgettes, fromage, crème, herbes',
        'image': 'assets/images/Plats/gratin_courgettes.jpg',
        'pointsFidelite': 1,
      },
      ];
      _plats = platsData.map((data) => Item.fromMap(data)).toList();

    final entreesData = [  // Soupes
      {
        'id': '101',
        'nom': 'Chorba Frik',
        'sous_categorie': 'Soupe',
        'prix': 500,
        'description': 'Soupe de blé vert concassé et viande',
        'ingredients': 'frik (blé vert), agneau haché, oignon, tomates, coriandre, persil, huile d\'olive, sel, poivre, piment',
        'image': 'assets/images/Entrées/chorba_frik.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '102',
        'nom': 'Lablabi',
        'sous_categorie': 'Soupe',
        'prix': 450,
        'description': 'Soupe de pois chiches épicée',
        'ingredients': 'pois chiches, ail, cumin, paprika, huile d\'olive, pain rassis, œuf (optionnel), coriandre',
        'image': 'assets/images/Entrées/lablabi.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '103',
        'nom': 'Harira',
        'sous_categorie': 'Soupe',
        'prix': 500,
        'description': 'Soupe de lentilles et pois chiches',
        'ingredients': 'lentilles, pois chiches, viande de bœuf, oignon, céleri, tomates, coriandre, persil, épices',
        'image': 'assets/images/Entrées/harira.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '104',
        'nom': 'Chorba Beïda',
        'sous_categorie': 'Soupe',
        'prix': 450,
        'description': 'Soupe blanche au poulet et vermicelles',
        'ingredients': 'vermicelles, poulet, oignon, coriandre, persil, épices',
        'image': 'assets/images/Entrées/chorba_beida.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '105',
        'nom': 'Chorba Loubia',
        'sous_categorie': 'Soupe',
        'prix': 450,
        'description': 'Soupe de haricots blancs',
        'ingredients': 'haricots blancs, oignon, tomate, ail, cumin, coriandre',
        'image': 'assets/images/Entrées/chorba_loubia.jpg',
        'pointsFidelite': 2,
      },
      {
        'id': '106',
        'nom': 'Chorba Poisson',
        'sous_categorie': 'Soupe',
        'prix': 500,
        'description': 'Soupe de poisson à l\'algéroise',
        'ingredients': 'filet de poisson, tomates, oignon, ail, persil, épices',
        'image': 'assets/images/Entrées/chorba_poisson.jpg',
        'pointsFidelite': 2,
      },

      // Salades
      {
        'id': '107',
        'nom': 'Salade Mechouia',
        'sous_categorie': 'Salade',
        'prix': 350,
        'description': 'Salade tiède de poivrons et tomates grillés',
        'ingredients': 'poivrons, tomates, ail, coriandre, huile d\'olive, sel',
        'image': 'assets/images/Entrées/salade_mechouia.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '108',
        'nom': 'Salade Fattoush',
        'sous_categorie': 'Salade',
        'prix': 350,
        'description': 'Salade croquante au sumac et pain grillé',
        'ingredients': 'laitue, tomates, concombre, radis, menthe, persil, pain arabe, sumac, huile d\'olive, citron',
        'image': 'assets/images/Entrées/salade_fattoush.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '109',
        'nom': 'Zaalouk',
        'sous_categorie': 'Salade',
        'prix': 600,
        'description': 'Caviar froid d\'aubergines',
        'ingredients': 'aubergines, tomates, ail, coriandre, paprika, huile d\'olive',
        'image': 'assets/images/Entrées/zaalouk.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '110',
        'nom': 'Salade d\'Orange',
        'sous_categorie': 'Salade',
        'prix': 300,
        'description': 'Tranches d\'orange à la cannelle',
        'ingredients': 'oranges, cannelle, sucre',
        'image': 'assets/images/Entrées/salade_orange.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '111',
        'nom': 'Salade de Carottes',
        'sous_categorie': 'Salade',
        'prix': 300,
        'description': 'Carottes râpées assaisonnées',
        'ingredients': 'carottes, citron, huile d\'olive, ail, persil',
        'image': 'assets/images/Entrées/salade_carottes.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '112',
        'nom': 'Salade de Betterave',
        'sous_categorie': 'Salade',
        'prix': 300,
        'description': 'Betteraves marinées au citron',
        'ingredients': 'betteraves, citron, huile d\'olive, sel',
        'image': 'assets/images/Entrées/salade_betterave.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '113',
        'nom': 'Salade Tabbouleh',
        'sous_categorie': 'Salade',
        'prix': 350,
        'description': 'Persil, menthe et boulgour',
        'ingredients': 'persil, menthe, boulgour, tomate, oignon, citron, huile d\'olive',
        'image': 'assets/images/Entrées/tabbouleh.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '114',
        'nom': 'Salade Raïta',
        'sous_categorie': 'Salade',
        'prix': 300,
        'description': 'Yaourt, concombre et menthe',
        'ingredients': 'yaourt, concombre, menthe, sel',
        'image': 'assets/images/Entrées/raita.jpg',
        'pointsFidelite': 1,
      },

      // Feuilletés
      {
        'id': '115',
        'nom': 'Bourek Viande',
        'sous_categorie': 'Feuilleté',
        'prix': 400,
        'description': 'Brick croustillant à la viande hachée',
        'ingredients': 'feuille de brick, viande hachée, oignon, persil, œuf, épices',
        'image': 'assets/images/Entrées/bourek_viande.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '116',
        'nom': 'Bourek Fromage',
        'sous_categorie': 'Feuilleté',
        'prix': 300,
        'description': 'Brick au fromage fondu',
        'ingredients': 'feuille de brick, fromage frais, œuf, beurre',
        'image': 'assets/images/Entrées/bourek_fromage.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '117',
        'nom': 'Brik à l\'Œuf',
        'sous_categorie': 'Feuilleté',
        'prix': 450,
        'description': 'Brik croustillant œuf et thon',
        'ingredients': 'feuille de brick, œuf, thon, câpres, persil',
        'image': 'assets/images/Entrées/brik_oeuf.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '118',
        'nom': 'Mhadjeb',
        'sous_categorie': 'Feuilleté',
        'prix': 250,
        'description': 'Galette semoule farcie légumes',
        'ingredients': 'semoule fine, oignon, poivron, tomate, épices',
        'image': 'assets/images/Entrées/mhadjeb.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '119',
        'nom': 'Bourek Épinards',
        'sous_categorie': 'Feuilleté',
        'prix': 350,
        'description': 'Brick aux épinards et fromage',
        'ingredients': 'feuille de brick, épinards, fromage, ail, huile',
        'image': 'assets/images/Entrées/bourek_epinards.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '120',
        'nom': 'Bourek Pommes de Terre',
        'sous_categorie': 'Feuilleté',
        'prix': 350,
        'description': 'Brick pommes de terre épicées',
        'ingredients': 'feuille de brick, pommes de terre, cumin, sel, huile',
        'image': 'assets/images/Entrées/bourek_pommes.jpg',
        'pointsFidelite': 1,
      },
      {
        'id': '121',
        'nom': 'Dolma Légumes',
        'sous_categorie': 'Feuilleté',
        'prix': 400,
        'description': 'Légumes farcis sauce tomate',
        'ingredients': 'poivron, aubergine, courgette, riz, tomates, herbes',
        'image': 'assets/images/Entrées/dolma.jpg',
        'pointsFidelite': 1,
      },]; 
    _entrees = entreesData.map((data) => Item.fromMap(data)).toList();

    final dessertsData = [
     // Gâteaux
    {
      'id': '301',
      'nom': 'Flan à la Vanille',
      'sous_categorie': 'Gâteau',
      'prix': 450,
      'description': 'Flan maison onctueux',
      'ingredients': 'lait, œufs, sucre, vanille',
      'image': 'assets/images/Desserts/flan_vanille.jpg',
      'pointsFidelite': 1,
    },
    {
      'id': '302',
      'nom': 'Kalb el Louz',
      'sous_categorie': 'Gâteau',
      'prix': 300,
      'description': 'Gâteau aux amandes et semoule',
      'ingredients': 'semoule, amandes, miel, eau de fleur d\'oranger',
      'image': 'assets/images/Desserts/kalb_el_louz.jpg',
      'pointsFidelite': 1,
    },
    {
      'id': '303',
      'nom': 'Mhalbi',
      'sous_categorie': 'Gâteau',
      'prix': 500,
      'description': 'Crème de riz à l\'eau de rose',
      'ingredients': 'riz, eau, sucre, eau de rose, pistaches',
      'image': 'assets/images/Desserts/mhalbi.jpg',
      'pointsFidelite': 2,
    },
    {
      'id': '304',
      'nom': 'Ghribia',
      'sous_categorie': 'Gâteau',
      'prix': 400,
      'description': 'Sablés fondants aux amandes',
      'ingredients': 'farine, sucre, beurre, amandes',
      'image': 'assets/images/Desserts/ghribia.jpg',
      'pointsFidelite': 1,
    },
    {
      'id': '308',
      'nom': 'Baghrir',
      'sous_categorie': 'Gâteau',
      'prix': 400,
      'description': 'Crêpe mille trous sucrée',
      'ingredients': 'semoule, farine, levure, eau, sucre, sel',
      'image': 'assets/images/Desserts/baghrir.jpg',
      'pointsFidelite': 1,
    },

    // Pâtisseries
    {
      'id': '305',
      'nom': 'Baklava',
      'sous_categorie': 'Pâtisserie',
      'prix': 600,
      'description': 'Feuilleté aux noix et miel',
      'ingredients': 'pâte filo, noix, beurre, miel',
      'image': 'assets/images/Desserts/baklava.jpg',
      'pointsFidelite': 2,
    },
    {
      'id': '306',
      'nom': 'Makroud',
      'sous_categorie': 'Pâtisserie',
      'prix': 300,
      'description': 'Gâteau semoule et dattes',
      'ingredients': 'semoule, pâte de dattes, huile, fleur d\'oranger',
      'image': 'assets/images/Desserts/makroud.jpg',
      'pointsFidelite': 1,
    },
    {
      'id': '307',
      'nom': 'Zlabia',
      'sous_categorie': 'Pâtisserie',
      'prix': 300,
      'description': 'Beignet au miel',
      'ingredients': 'farine, levure, sucre, miel',
      'image': 'assets/images/Desserts/zlabia.jpg',
      'pointsFidelite': 1,
    },
    {
      'id': '309',
      'nom': 'Makroud Sésame',
      'sous_categorie': 'Pâtisserie',
      'prix': 400,
      'description': 'Gâteau semoule-sésame',
      'ingredients': 'semoule, tahini, eau, sel',
      'image': 'assets/images/Desserts/makroud_sesame.jpg',
      'pointsFidelite': 1,
    },

    // Glaces
    {
      'id': '310',
      'nom': 'Glace Maison',
      'sous_categorie': 'Glace',
      'prix': 500,
      'description': 'Glace artisanale selon l\'offre',
      'ingredients': 'lait, crème, sucre, arômes saisonniers',
      'image': 'assets/images/Desserts/glace_maison.jpg',
      'pointsFidelite': 2,
    },
    ];
    _desserts = dessertsData.map((data) => Item.fromMap(data)).toList();

    final boissonsData = [
   // Boissons Chaudes
    {
      'id': '501',
      'nom': 'Thé à la Menthe',
      'sous_categorie': 'Chaude',
      'prix': 300,
      'description': 'Thé vert infusé à la menthe',
      'ingredients': 'thé vert, menthe fraîche, sucre, eau',
      'image': 'assets/images/Boissons/the_menthe.jpg',
      'pointsFidelite': 1, // Added points fidelite
    },
    {
      'id': '502',
      'nom': 'Café Turc',
      'sous_categorie': 'Chaude',
      'prix': 350,
      'description': 'Café moulu à la turque',
      'ingredients': 'café turc, eau, sucre (optionnel)',
      'image': 'assets/images/Boissons/cafe_turc.jpg',
      'pointsFidelite': 1, // Added points fidelite
    },
    {
      'id': '503',
      'nom': 'Café Algérien',
      'sous_categorie': 'Chaude',
      'prix': 300,
      'description': 'Café court à l\'algérienne',
      'ingredients': 'café, eau, sucre (optionnel)',
      'image': 'assets/images/Boissons/cafe_algerien.jpg',
      'pointsFidelite': 1, // Added points fidelite
    },
    {
      'id': '504',
      'nom': 'Thé Vert Nature',
      'sous_categorie': 'Chaude',
      'prix': 250,
      'description': 'Thé infusé nature',
      'ingredients': 'thé vert, eau',
      'image': 'assets/images/Boissons/the_vert.jpg',
      'pointsFidelite': 1, // Added points fidelite
    },
    {
      'id': '505',
      'nom': 'Thé à l\'Hibiscus',
      'sous_categorie': 'Chaude',
      'prix': 300,
      'description': 'Thé rouge parfumé',
      'ingredients': 'hibiscus séché, sucre, eau',
      'image': 'assets/images/Boissons/the_hibiscus.jpg',
      'pointsFidelite': 1, // Added points fidelite
    },
    {
      'id': '506',
      'nom': 'Café au Lait',
      'sous_categorie': 'Chaude',
      'prix': 400,
      'description': 'Café au lait chaud',
      'ingredients': 'café, lait, sucre (optionnel)',
      'image': 'assets/images/Boissons/cafe_lait.jpg',
      'pointsFidelite': 1, // Added points fidelite
    },

    // Boissons Froides
    {
      'id': '507',
      'nom': 'Jus d\'Orange Frais',
      'sous_categorie': 'Froide',
      'prix': 400,
      'description': 'Jus pressé minute',
      'ingredients': 'oranges fraîches',
      'image': 'assets/images/Boissons/jus_orange.jpg',
      'pointsFidelite': 2, // Added points fidelite
    },
    {
      'id': '508',
      'nom': 'Jus de Pomme',
      'sous_categorie': 'Froide',
      'prix': 400,
      'description': 'Jus naturel de pomme',
      'ingredients': 'pommes',
      'image': 'assets/images/Boissons/jus_pomme.jpg',
      'pointsFidelite': 2, // Added points fidelite
    },
    {
      'id': '509',
      'nom': 'Jus de Carotte',
      'sous_categorie': 'Froide',
      'prix': 450,
      'description': 'Jus pressé de carotte',
      'ingredients': 'carottes',
      'image': 'assets/images/Boissons/jus_carotte.jpg',
      'pointsFidelite': 2, // Added points fidelite
    },
    {
      'id': '510',
      'nom': 'Jus de Grenade',
      'sous_categorie': 'Froide',
      'prix': 450,
      'description': 'Jus naturel de grenade',
      'ingredients': 'grenades',
      'image': 'assets/images/Boissons/jus_grenade.jpg',
      'pointsFidelite': 2, // Added points fidelite
    },
    {
      'id': '511',
      'nom': 'Jus de Pastèque',
      'sous_categorie': 'Froide',
      'prix': 450,
      'description': 'Jus frais de pastèque',
      'ingredients': 'pastèque',
      'image': 'assets/images/Boissons/jus_pasteque.jpg',
      'pointsFidelite': 2, // Added points fidelite
    },
    {
      'id': '512',
      'nom': 'Limonade Maison',
      'sous_categorie': 'Froide',
      'prix': 350,
      'description': 'Limonade citron-menthe',
      'ingredients': 'citron, sucre, menthe, eau',
      'image': 'assets/images/Boissons/limonade.jpg',
      'pointsFidelite': 2, // Added points fidelite
    },

    // Eaux et Sodas
    {
      'id': '513',
      'nom': 'Eau Minérale',
      'sous_categorie': 'Eau/Soda',
      'prix': 100,
      'description': 'Bouteille 50 cl',
      'ingredients': 'eau minérale',
      'image': 'assets/images/Boissons/eau_minerale.jpg',
      'pointsFidelite': 0, // Added points fidelite
    },
    {
      'id': '514',
      'nom': 'Eau Gazeuse',
      'sous_categorie': 'Eau/Soda',
      'prix': 150,
      'description': 'Bouteille 50 cl',
      'ingredients': 'eau gazeuse',
      'image': 'assets/images/Boissons/eau_gazeuse.jpg',
      'pointsFidelite': 0, // Added points fidelite
    },
    {
      'id': '515',
      'nom': 'Soda',
      'sous_categorie': 'Eau/Soda',
      'prix': 150,
      'description': 'Assortiment de sodas',
      'ingredients': 'eau gazeuse, arômes, sucre',
      'image': 'assets/images/Boissons/soda.jpg',
      'pointsFidelite': 0, // Added points fidelite
    },
    ];
    _boissons = boissonsData.map((data) => Item.fromMap(data)).toList();

    final accompagnementsData = [
   // Riz
    {
      'id': '401',
      'nom': 'Riz Pilaf',
      'sous_categorie': 'Riz',
      'prix': 350,
      'description': 'Riz basmati sauté aux oignons',
      'ingredients': 'riz basmati, oignon, beurre, sel',
      'image': 'assets/images/Accompagnements/riz_pilaf.jpg',
      'pointsFidelite': 1,
    },
    {
      'id': '402',
      'nom': 'Riz aux Vermicelles',
      'sous_categorie': 'Riz',
      'prix': 400,
      'description': 'Riz et vermicelles grillés',
      'ingredients': 'riz, vermicelles, beurre, sel',
      'image': 'assets/images/Accompagnements/riz_vermicelles.jpg',
      'pointsFidelite': 1,
    },

    // Légumes
    {
      'id': '403',
      'nom': 'Légumes Grillés',
      'sous_categorie': 'Légumes',
      'prix': 500,
      'description': 'Poivrons, courgettes et aubergines',
      'ingredients': 'poivrons, courgettes, aubergines, huile d\'olive, sel',
      'image': 'assets/images/Accompagnements/legumes_grilles.jpg',
      'pointsFidelite': 1,
    },
    {
      'id': '404',
      'nom': 'Ratatouille',
      'sous_categorie': 'Légumes',
      'prix': 650,
      'description': 'Mélange mijoté de légumes',
      'ingredients': 'aubergine, courgette, tomate, poivron, oignon, ail, thym',
      'image': 'assets/images/Accompagnements/ratatouille.jpg',
      'pointsFidelite': 2,
    },
    {
      'id': '405',
      'nom': 'Pommes de Terre Sautées',
      'sous_categorie': 'Légumes',
      'prix': 400,
      'description': 'Pommes de terre dorées',
      'ingredients': 'pommes de terre, ail, persil, huile',
      'image': 'assets/images/Accompagnements/pommes_sautees.jpg',
      'pointsFidelite': 1,
    },
    {
      'id': '406',
      'nom': 'Purée de Pommes de Terre',
      'sous_categorie': 'Légumes',
      'prix': 500,
      'description': 'Purée onctueuse',
      'ingredients': 'pommes de terre, beurre, lait, sel',
      'image': 'assets/images/Accompagnements/puree.jpg',
      'pointsFidelite': 1,
    },

    // Pain
    {
      'id': '407',
      'nom': 'Pain Maison',
      'sous_categorie': 'Pain',
      'prix': 100,
      'description': 'Pain traditionnel cuit au four',
      'ingredients': 'farine, eau, levure, sel',
      'image': 'assets/images/Accompagnements/pain_maison.jpg',
      'pointsFidelite': 1,
    },
    {
      'id': '408',
      'nom': 'Msemen',
      'sous_categorie': 'Pain',
      'prix': 300,
      'description': 'Galette feuilletée maison',
      'ingredients': 'farine, semoule, eau, sel, huile',
      'image': 'assets/images/Accompagnements/msemen.jpg',
      'pointsFidelite': 1,
    },
    {
      'id': '409',
      'nom': 'Chapati',
      'sous_categorie': 'Pain',
      'prix': 200,
      'description': 'Pain plat nature',
      'ingredients': 'farine, eau, sel',
      'image': 'assets/images/Accompagnements/chapati.jpg',
      'pointsFidelite': 1,
    },
    {
      'id': '410',
      'nom': 'Frites Maison',
      'sous_categorie': 'Pain',
      'prix': 400,
      'description': 'Frites croustillantes',
      'ingredients': 'pommes de terre, huile, sel',
      'image': 'assets/images/Accompagnements/frites.jpg',
      'pointsFidelite': 1,
    },
    ];
    _accompagnements = accompagnementsData.map((data) => Item.fromMap(data)).toList();
  }

Future<void> _loadApiData() async {
  try {
    const baseUrl = 'http://127.0.0.1:8000/api/table';
    
    debugPrint('Starting API data loading...');
    
    // First get categories
    final categoriesResponse = await http.get(
      Uri.parse('$baseUrl/categories/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (categoriesResponse.statusCode != 200) {
      debugPrint('Failed to load categories: ${categoriesResponse.statusCode}');
      return;
    }

    final List<dynamic> categories = json.decode(categoriesResponse.body);
    debugPrint('Loaded ${categories.length} categories from API');
    
    for (var category in categories) {
      final categoryId = category['id'];
      final categoryName = category['nomCat'].toString().toLowerCase();
      
      debugPrint('Processing category: $categoryName (ID: $categoryId)');
      
      // Get subcategories for this category
      final subcategoriesResponse = await http.get(
        Uri.parse('$baseUrl/categories/$categoryId/subcategories/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (subcategoriesResponse.statusCode != 200) continue;

      final List<dynamic> subcategories = json.decode(subcategoriesResponse.body);
      debugPrint('Loaded ${subcategories.length} subcategories for $categoryName');
      
      for (var subcategory in subcategories) {
        final subcategoryId = subcategory['id'];
        final subcategoryName = subcategory['nomSousCat'] ?? 'Sans sous-catégorie';
        
        debugPrint('Loading items for subcategory: $subcategoryName (ID: $subcategoryId)');
        
        final itemsResponse = await http.get(
          Uri.parse('$baseUrl/subcategories/$subcategoryId/items/'),
          headers: {'Content-Type': 'application/json'},
        );

        if (itemsResponse.statusCode != 200) continue;

        final List<dynamic> apiItems = json.decode(itemsResponse.body);
        debugPrint('Loaded ${apiItems.length} items for subcategory: $subcategoryName');
        
        for (var itemData in apiItems) {
          final itemId = itemData['id'].toString();
          
          // Skip if item exists in hardcoded data
          if (_itemExistsInAnyList(itemId)) {
            debugPrint('Item $itemId exists in hardcoded data - skipping');
            continue;
          }
          
          final item = Item(
            id: itemId,
            nom: itemData['nom'] ?? 'Sans nom',
            sousCategorie: subcategoryName,
            prix: (itemData['prix'] ?? 0).toDouble(),
            description: itemData['description'] ?? 'Aucune description disponible',
            ingredients: itemData['ingredients'] ?? 'Ingrédients non spécifiés',
            image: 'assets/images/placeholder.jpg', // Default placeholder
            pointsFidelite: itemData['pointsFidelite'] ?? 0,
          );

          _getTargetListByCategory(categoryName).add(item);
        }
      }
    }
  } catch (e) {
    debugPrint('Error loading API data: $e');
  }
}


  Future<List<Map<String, dynamic>>> getNouveautes() async {
  try {
    const baseUrl = 'http://127.0.0.1:8000/api';
    final response = await http.get(Uri.parse('$baseUrl/table/plats/nouveautes/'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load new plats');
  } catch (e) {
    debugPrint('Error loading new plats: $e');
    throw e;
  }
}

bool _itemExistsInAnyList(String itemId) {
  return [..._plats, ..._entrees, ..._desserts, ..._boissons, ..._accompagnements]
      .any((item) => item.id == itemId);
}

  List<Item> _getTargetListByCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'plat':
      case 'plats':
        return _plats;
      case 'entree':
      case 'entrée':
      case 'entrees':
      case 'entrées':
        return _entrees;
      case 'dessert':
      case 'desserts':
        return _desserts;
      case 'boisson':
      case 'boissons':
        return _boissons;
      case 'accompagnement':
      case 'accompagnements':
        return _accompagnements;
      default:
        // Default to plats for unknown categories
        debugPrint('Unknown category: $categoryName, defaulting to plats');
        return _plats;
    }
    
  }



  // Grouping methods
  Map<String, List<Item>> get groupedPlats => _groupItemsBySubCategory(_plats);
  Map<String, List<Item>> get groupedEntrees => _groupItemsBySubCategory(_entrees);
  Map<String, List<Item>> get groupedDesserts => _groupItemsBySubCategory(_desserts);
  Map<String, List<Item>> get groupedBoissons => _groupItemsBySubCategory(_boissons);
  Map<String, List<Item>> get groupedAccompagnements => _groupItemsBySubCategory(_accompagnements);

  Map<String, List<Item>> _groupItemsBySubCategory(List<Item> items) {
    final grouped = <String, List<Item>>{};
    for (var item in items) {
      grouped.putIfAbsent(item.sousCategorie, () => []).add(item);
    }
    return grouped;
  }

  Future<void> refresh() async {
    _plats.clear();
    _entrees.clear();
    _desserts.clear();
    _boissons.clear();
    _accompagnements.clear();
    await loadMenuData();
  }

  Item? findItemById(String id) {
    try {
      return [..._plats, ..._entrees, ..._desserts, ..._boissons, ..._accompagnements]
          .firstWhere((item) => item.id == id);
    } catch (e) {
      debugPrint('Item not found with ID: $id');
      return null;
    }
  }

  // Helper method to get all items
  List<Item> getAllItems() {
    return [..._plats, ..._entrees, ..._desserts, ..._boissons, ..._accompagnements];
  }

  // Helper methods to get items by category
  List<Item> getItemsByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'plats':
        return _plats;
      case 'entrees':
        return _entrees;
      case 'desserts':
        return _desserts;
      case 'boissons':
        return _boissons;
      case 'accompagnements':
        return _accompagnements;
      default:
        return [];
    }
  }
}