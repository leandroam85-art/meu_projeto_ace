import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // ATENÇÃO: Versão 5 para forçar a criação da nova tabela de Vacinação!
    _database = await _initDB('endemias_offline_v5.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. GAVETA DE VISITAS (PNCD)
    await db.execute('''
    CREATE TABLE visitas_offline (
      id_local INTEGER PRIMARY KEY AUTOINCREMENT,
      status TEXT,
      imovel TEXT,
      agente INTEGER,
      amostras_coletadas INTEGER,
      quantidade_larvas INTEGER,
      depositos_eliminados INTEGER,
      larvicida_1_tipo TEXT,
      larvicida_1_qtde REAL,
      larvicida_1_dep_tratados INTEGER,
      larvicida_2_tipo TEXT,
      larvicida_2_qtde REAL,
      larvicida_2_dep_tratados INTEGER,
      adulticida_tipo TEXT,
      adulticida_qtde REAL,
      observacoes TEXT,
      dep_A1 INTEGER,
      dep_A2 INTEGER,
      dep_B INTEGER,
      dep_C INTEGER,
      dep_D1 INTEGER,
      dep_D2 INTEGER,
      dep_E INTEGER,
      ciclo INTEGER,
      semana_epidemiologica INTEGER,
      data_visita TEXT,
      sincronizado INTEGER DEFAULT 0
    )
    ''');

    // 2. GAVETA DE IMÓVEIS
    await db.execute('''
    CREATE TABLE imoveis_offline (
      id_local INTEGER PRIMARY KEY AUTOINCREMENT,
      endereco TEXT,
      numero TEXT,
      bairro TEXT,
      quarteirao TEXT,
      tipo TEXT,
      localizacao TEXT,
      sincronizado INTEGER DEFAULT 0
    )
    ''');

    // 3. CACHE DE SISTEMA
    await db.execute('CREATE TABLE cache (chave TEXT PRIMARY KEY, dados TEXT)');

    // =========================================================================
    // 4. NOVA GAVETA: VACINAÇÃO ANTIRRÁBICA
    // =========================================================================
    await db.execute('''
    CREATE TABLE vacinacao_offline (
      id_local INTEGER PRIMARY KEY AUTOINCREMENT,
      agente_username TEXT,
      localidade TEXT,
      caes_vacinados INTEGER,
      gatos_vacinados INTEGER,
      data_vacinacao TEXT,
      localizacao TEXT,
      sincronizado INTEGER DEFAULT 0
    )
    ''');
  }

  // =========================================================================
  // FUNÇÕES DE CACHE
  // =========================================================================
  Future<void> salvarCache(String chave, String dados) async {
    final db = await instance.database;
    await db.insert('cache', {
      'chave': chave,
      'dados': dados,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> lerCache(String chave) async {
    final db = await instance.database;
    final res = await db.query('cache', where: 'chave = ?', whereArgs: [chave]);
    if (res.isNotEmpty) return res.first['dados'] as String;
    return null;
  }

  // =========================================================================
  // FUNÇÕES DE VISITAS (PNCD)
  // =========================================================================
  Future<int> inserirVisita(Map<String, dynamic> visita) async {
    final db = await instance.database;
    return await db.insert('visitas_offline', visita);
  }

  Future<List<Map<String, dynamic>>> buscarVisitasPendentes() async {
    final db = await instance.database;
    return await db.query(
      'visitas_offline',
      where: 'sincronizado = ?',
      whereArgs: [0],
    );
  }

  Future<int> marcarComoSincronizado(int idLocal) async {
    final db = await instance.database;
    return await db.update(
      'visitas_offline',
      {'sincronizado': 1},
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  Future<void> atualizarIdImovelNasVisitas(String idTemp, int idReal) async {
    final db = await instance.database;
    await db.update(
      'visitas_offline',
      {'imovel': idReal.toString()},
      where: 'imovel = ?',
      whereArgs: [idTemp],
    );
  }

  // =========================================================================
  // FUNÇÕES DE IMÓVEIS
  // =========================================================================
  Future<int> inserirImovel(Map<String, dynamic> imovel) async {
    final db = await instance.database;
    return await db.insert('imoveis_offline', imovel);
  }

  Future<List<Map<String, dynamic>>> buscarImoveisPendentes() async {
    final db = await instance.database;
    return await db.query(
      'imoveis_offline',
      where: 'sincronizado = ?',
      whereArgs: [0],
    );
  }

  Future<int> marcarImovelComoSincronizado(int idLocal) async {
    final db = await instance.database;
    return await db.update(
      'imoveis_offline',
      {'sincronizado': 1},
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  // =========================================================================
  // NOVAS FUNÇÕES: VACINAÇÃO ANTIRRÁBICA
  // =========================================================================
  Future<int> inserirVacinacao(Map<String, dynamic> vacinacao) async {
    final db = await instance.database;
    return await db.insert('vacinacao_offline', vacinacao);
  }

  Future<List<Map<String, dynamic>>> buscarVacinacoesPendentes() async {
    final db = await instance.database;
    return await db.query(
      'vacinacao_offline',
      where: 'sincronizado = ?',
      whereArgs: [0],
    );
  }

  Future<int> marcarVacinacaoComoSincronizada(int idLocal) async {
    final db = await instance.database;
    return await db.update(
      'vacinacao_offline',
      {'sincronizado': 1},
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }
}
