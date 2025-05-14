// lib/data/services/table_service.dart
import 'package:flutter/material.dart';
import 'package:good_taste/data/models/table.dart';

class TableService {
  // Singleton pattern
  static final TableService _instance = TableService._internal();
  factory TableService() => _instance;
  TableService._internal();

  // Liste des tables disponibles dans le restaurant
  final List<TableModel> _tables = [
    TableModel(id: '1', number: '1', capacity: 4, type: 'Carrée'),
    TableModel(id: '2', number: '2', capacity: 4, type: 'Carrée'),
    TableModel(id: '3', number: '3', capacity: 4, type: 'Carrée'),
    TableModel(id: '4', number: '4', capacity: 4, type: 'Carrée'),
    TableModel(id: '5', number: '5', capacity: 4, type: 'Carrée'),
    TableModel(id: '6', number: '6', capacity: 4, type: 'Carrée'),
    TableModel(id: '7', number: '7', capacity: 6, type: 'Rectangulaire'),
    TableModel(id: '8', number: '8', capacity: 6, type: 'Rectangulaire'),
    TableModel(id: '9', number: '9', capacity: 6, type: 'Rectangulaire'),
    TableModel(id: '10', number: '10', capacity: 8, type: 'Large'),
    TableModel(id: '11', number: '11', capacity: 8, type: 'Large'),
  ];

  // Obtenir toutes les tables
  List<TableModel> getAllTables() {
    return List.from(_tables);
  }

  // Obtenir une table par son numéro
  TableModel? getTableByNumber(String number) {
    try {
      return _tables.firstWhere((table) => table.number == number);
    } catch (e) {
      debugPrint('Table non trouvée: $number');
      return null;
    }
  }

  // Obtenir les tables filtrées par capacité
  List<TableModel> getTablesByCapacity(int numberOfPeople) {
    return _tables.where((table) => table.capacity >= numberOfPeople).toList();
  }
}