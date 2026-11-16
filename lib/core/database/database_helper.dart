import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._({String? dbPath}) : _dbPath = dbPath;

  factory DatabaseHelper.test(String dbPath) =>
      DatabaseHelper._(dbPath: dbPath);

  static final DatabaseHelper instance = DatabaseHelper._();

  static const int _databaseVersion = 6;
  static const String _databaseName = 'quotation.db';

  final String? _dbPath;
  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path;
    if (_dbPath != null) {
      path = _dbPath;
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      path = p.join(documentsDirectory.path, _databaseName);
    }

    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE quotation_items ADD COLUMN category_name TEXT NOT NULL DEFAULT 'General'",
          );
          await db.execute('''
            UPDATE quotations
            SET total_amount = COALESCE((
              SELECT SUM(amount) * 1.08 FROM quotation_items
              WHERE quotation_items.quotation_id = quotations.id
            ), 0)
          ''');
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE quotations ADD COLUMN say_text TEXT NOT NULL DEFAULT ''");
          await db.execute("ALTER TABLE quotation_items ADD COLUMN category_quantity REAL NOT NULL DEFAULT 1");
          await db.execute("ALTER TABLE quotation_items ADD COLUMN category_unit TEXT");
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE quotation_categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              quotation_id INTEGER NOT NULL,
              category_name TEXT NOT NULL,
              amount REAL NOT NULL,
              FOREIGN KEY (quotation_id) REFERENCES quotations(id) ON DELETE CASCADE,
              UNIQUE (quotation_id, category_name)
            )
          ''');
          await db.execute('''
            INSERT INTO quotation_categories (quotation_id, category_name, amount)
            SELECT quotation_id, category_name, SUM(amount)
            FROM quotation_items
            GROUP BY quotation_id, category_name
          ''');
        }
        if (oldVersion < 5 && oldVersion >= 4) {
          await db.execute('ALTER TABLE quotation_categories RENAME TO quotation_categories_old');
          await db.execute('''
            CREATE TABLE quotation_categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              quotation_id INTEGER NOT NULL,
              category_name TEXT NOT NULL,
              amount REAL NOT NULL,
              FOREIGN KEY (quotation_id) REFERENCES quotations(id) ON DELETE CASCADE,
              UNIQUE (quotation_id, category_name)
            )
          ''');
          await db.execute('''
            INSERT INTO quotation_categories (quotation_id, category_name, amount)
            SELECT quotation_id, category_name, amount FROM quotation_categories_old
          ''');
          await db.execute('DROP TABLE quotation_categories_old');
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE quotations ADD COLUMN say_amount REAL');
          await db.execute('DROP TABLE IF EXISTS quotation_categories');
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE quotations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quotation_no TEXT NOT NULL UNIQUE,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        customer_address TEXT,
        quotation_date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        say_amount REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE quotation_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quotation_id INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        category_name TEXT NOT NULL DEFAULT 'General',
        quantity REAL NOT NULL,
        unit TEXT,
        unit_price REAL NOT NULL,
        amount REAL NOT NULL,
        remark TEXT,
        FOREIGN KEY (quotation_id) REFERENCES quotations(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_quotation_items_quotation_id '
      'ON quotation_items(quotation_id)',
    );

  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }
}
