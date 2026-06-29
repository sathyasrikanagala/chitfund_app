import 'package:sembast_web/sembast_web.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  // Stores
  final membersStore = stringMapStoreFactory.store('members');
  final groupsStore = stringMapStoreFactory.store('chit_groups');
  final paymentsStore = stringMapStoreFactory.store('payments');
  final prizesStore = stringMapStoreFactory.store('prize_entries');
  final cashbookStore = stringMapStoreFactory.store('cashbook');
  final groupMembersStore = stringMapStoreFactory.store('group_members');
  final settingsStore = stringMapStoreFactory.store('settings');
  final usersStore = stringMapStoreFactory.store('users');

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

 Future<Database> _initDatabase() async {
  if (kIsWeb) {
    print('🔵 Initializing WEB database...');
    final db = await databaseFactoryWeb.openDatabase('chit_fund.db');
    print('✅ WEB database initialized: $db');
    return db;
  } else {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'chit_fund.db');
    print('🔵 Initializing IO database at: $dbPath');
    return await databaseFactoryIo.openDatabase(dbPath);
  }
}

Future<void> updateUserPassword(String userId, String newPassword) async {
  final db = await database;
  final user = await usersStore.record(userId).get(db);
  if (user != null) {
    final updated = Map<String, dynamic>.from(user);
    updated['password'] = newPassword;
    await usersStore.record(userId).put(db, updated);
  }
}

// ── BACKUP / RESTORE ──────────────────────────────────

Future<Map<String, dynamic>> exportAllData() async {
  final db = await database;
  final members = await membersStore.find(db);
  final groups = await groupsStore.find(db);
  final groupMembers = await groupMembersStore.find(db);
  final payments = await paymentsStore.find(db);
  final prizes = await prizesStore.find(db);
  final cashbook = await cashbookStore.find(db);
  final settings = await settingsStore.find(db);
  final users = await usersStore.find(db);

  return {
    'version': 1,
    'exported_at': DateTime.now().toIso8601String(),
    'members': members.map((r) => r.value).toList(),
    'chit_groups': groups.map((r) => r.value).toList(),
    'group_members': groupMembers.map((r) => r.value).toList(),
    'payments': payments.map((r) => r.value).toList(),
    'prize_entries': prizes.map((r) => r.value).toList(),
    'cashbook': cashbook.map((r) => r.value).toList(),
    'settings': settings.map((r) => r.value).toList(),
    'users': users.map((r) => r.value).toList(),
  };
}

Future<void> importAllData(Map<String, dynamic> data) async {
  final db = await database;

  Future<void> restoreStore(
      StoreRef<String, Map<String, dynamic>> store, String key) async {
    final items = data[key] as List<dynamic>?;
    if (items == null) return;
    for (var item in items) {
      final map = Map<String, dynamic>.from(item);
      await store.record(map['id']).put(db, map);
    }
  }

  await restoreStore(membersStore, 'members');
  await restoreStore(groupsStore, 'chit_groups');
  await restoreStore(groupMembersStore, 'group_members');
  await restoreStore(paymentsStore, 'payments');
  await restoreStore(prizesStore, 'prize_entries');
  await restoreStore(cashbookStore, 'cashbook');
  await restoreStore(usersStore, 'users');

  // settings is keyed by 'organization', handle separately
  final settingsItems = data['settings'] as List<dynamic>?;
  if (settingsItems != null) {
    for (var item in settingsItems) {
      // We don't have the key here, so just restore organization details directly
      await settingsStore.record('organization').put(
          db, Map<String, dynamic>.from(item));
    }
  }
}

// ── USERS / AUTH ──────────────────────────────────────

Future<String> insertUser(Map<String, dynamic> user) async {
  final db = await database;
  await usersStore.record(user['id']).put(db, user);
  return user['id'];
}

Future<List<Map<String, dynamic>>> getAllUsers() async {
  final db = await database;
  final records = await usersStore.find(db);
  return records.map((r) => r.value).toList();
}

Future<Map<String, dynamic>?> findUserByUsername(String username) async {
  final db = await database;
  final records = await usersStore.find(db,
      finder: Finder(filter: Filter.equals('username', username)));
  return records.isNotEmpty ? records.first.value : null;
}

Future<bool> hasAnyUsers() async {
  final db = await database;
  final count = await usersStore.count(db);
  return count > 0;
}

  // ── MEMBERS ──────────────────────────────────────────

  Future<String> insertMember(Map<String, dynamic> member) async {
  final db = await database;
  print('🟢 Inserting member: $member');
  await membersStore.record(member['id']).put(db, member);
  print('✅ Member inserted with id: ${member['id']}');
  return member['id'];
}
  Future<List<Map<String, dynamic>>> getAllMembers() async {
    final db = await database;
    final records = await membersStore.find(db,
        finder: Finder(sortOrders: [SortOrder('name')]));
    return records.map((r) => r.value).toList();
  }

  Future<Map<String, dynamic>?> getMemberById(String id) async {
    final db = await database;
    return await membersStore.record(id).get(db);
  }

  Future<void> updateMember(Map<String, dynamic> member) async {
    final db = await database;
    await membersStore.record(member['id']).put(db, member);
  }

  Future<void> deleteMember(String id) async {
    final db = await database;
    await membersStore.record(id).delete(db);
  }

  // ── CHIT GROUPS ───────────────────────────────────────

 Future<String> insertGroup(Map<String, dynamic> group) async {
  final db = await database;
  print('🟢 Inserting group: $group');
  await groupsStore.record(group['id']).put(db, group);
  print('✅ Group inserted with id: ${group['id']}');
  return group['id'];
}

Future<void> deleteGroup(String id) async {
  final db = await database;
  await groupsStore.record(id).delete(db);
}

  Future<List<Map<String, dynamic>>> getAllGroups() async {
    final db = await database;
    final records = await groupsStore.find(db,
        finder: Finder(sortOrders: [SortOrder('created_at', false)]));
    return records.map((r) => r.value).toList();
  }

  // ── GROUP MEMBERS (linking) ──────────────────────────

Future<String> addMemberToGroup(Map<String, dynamic> link) async {
  final db = await database;
  await groupMembersStore.record(link['id']).put(db, link);
  return link['id'];
}

Future<List<Map<String, dynamic>>> getMembersInGroup(String groupId) async {
  final db = await database;
  final records = await groupMembersStore.find(db,
      finder: Finder(filter: Filter.equals('group_id', groupId)));
  return records.map((r) => r.value).toList();
}

Future<List<Map<String, dynamic>>> getGroupsForMember(String memberId) async {
  final db = await database;
  final records = await groupMembersStore.find(db,
      finder: Finder(filter: Filter.equals('member_id', memberId)));
  return records.map((r) => r.value).toList();
}

Future<void> removeMemberFromGroup(String linkId) async {
  final db = await database;
  await groupMembersStore.record(linkId).delete(db);
}

  Future<void> updateGroup(Map<String, dynamic> group) async {
    final db = await database;
    await groupsStore.record(group['id']).put(db, group);
  }

  // ── PAYMENTS ─────────────────────────────────────────

  Future<String> insertPayment(Map<String, dynamic> payment) async {
    final db = await database;
    await paymentsStore.record(payment['id']).put(db, payment);
    return payment['id'];
  }

  Future<List<Map<String, dynamic>>> getPaymentsByMember(String memberId) async {
    final db = await database;
    final records = await paymentsStore.find(db,
        finder: Finder(
            filter: Filter.equals('member_id', memberId),
            sortOrders: [SortOrder('paid_at', false)]));
    return records.map((r) => r.value).toList();
  }

  Future<List<Map<String, dynamic>>> getPaymentsByGroup(String groupId) async {
    final db = await database;
    final records = await paymentsStore.find(db,
        finder: Finder(
            filter: Filter.equals('group_id', groupId),
            sortOrders: [SortOrder('paid_at', false)]));
    return records.map((r) => r.value).toList();
  }

  Future<List<Map<String, dynamic>>> getTodayPayments() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final records = await paymentsStore.find(db,
        finder: Finder(sortOrders: [SortOrder('paid_at', false)]));
    return records
        .map((r) => r.value)
        .where((p) => (p['paid_at'] as String).startsWith(today))
        .toList();
  }
  Future<List<Map<String, dynamic>>> getAllPayments() async {
  final db = await database;
  final records = await paymentsStore.find(db,
      finder: Finder(sortOrders: [SortOrder('paid_at', false)]));
  return records.map((r) => r.value).toList();
}

Future<List<Map<String, dynamic>>> getAllCashEntries() async {
  final db = await database;
  final records = await cashbookStore.find(db,
      finder: Finder(sortOrders: [SortOrder('entry_date', false)]));
  return records.map((r) => r.value).toList();
}

  // ── CASHBOOK ─────────────────────────────────────────

  Future<String> insertCashEntry(Map<String, dynamic> entry) async {
    final db = await database;
    await cashbookStore.record(entry['id']).put(db, entry);
    return entry['id'];
  }

  Future<List<Map<String, dynamic>>> getTodayCashEntries() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final records = await cashbookStore.find(db,
        finder: Finder(sortOrders: [SortOrder('entry_date', false)]));
    return records
        .map((r) => r.value)
        .where((e) => (e['entry_date'] as String).startsWith(today))
        .toList();
  }

  // ── SETTINGS / ORGANIZATION ──────────────────────────

Future<void> saveOrganizationDetails(Map<String, dynamic> details) async {
  final db = await database;
  await settingsStore.record('organization').put(db, details);
}

Future<Map<String, dynamic>?> getOrganizationDetails() async {
  final db = await database;
  return await settingsStore.record('organization').get(db);
}

  // ── PRIZE ENTRIES ─────────────────────────────────────

  Future<String> insertPrizeEntry(Map<String, dynamic> prize) async {
    final db = await database;
    await prizesStore.record(prize['id']).put(db, prize);
    return prize['id'];
  }

  Future<List<Map<String, dynamic>>> getPrizesByGroup(String groupId) async {
    final db = await database;
    final records = await prizesStore.find(db,
        finder: Finder(
            filter: Filter.equals('group_id', groupId),
            sortOrders: [SortOrder('prize_date', false)]));
    return records.map((r) => r.value).toList();
  }
}