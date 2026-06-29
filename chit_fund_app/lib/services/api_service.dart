import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // ── MEMBERS ──────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getMembers() async {
    final response = await http.get(Uri.parse('$baseUrl/members/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load members: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> createMember(
      Map<String, dynamic> member) async {
    final response = await http.post(
      Uri.parse('$baseUrl/members/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(member),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to create member: ${response.body}');
  }

  static Future<Map<String, dynamic>> updateMember(
      String id, Map<String, dynamic> member) async {
    final response = await http.put(
      Uri.parse('$baseUrl/members/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(member),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update member: ${response.body}');
  }

  static Future<void> deleteMember(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/members/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete member: ${response.body}');
    }
  }

  // ── GROUPS ────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getGroups() async {
    final response = await http.get(Uri.parse('$baseUrl/groups/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load groups: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> createGroup(
      Map<String, dynamic> group) async {
    final response = await http.post(
      Uri.parse('$baseUrl/groups/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(group),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to create group: ${response.body}');
  }

  static Future<void> deleteGroup(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/groups/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete group: ${response.body}');
    }
  }

  // ── PAYMENTS ─────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPayments(
      {String? memberId, String? groupId}) async {
    final params = <String, String>{};
    if (memberId != null) params['member_id'] = memberId;
    if (groupId != null) params['group_id'] = groupId;

    final uri =
        Uri.parse('$baseUrl/payments/').replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load payments: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> createPayment(
      Map<String, dynamic> payment) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payment),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to create payment: ${response.body}');
  }

 // ── USERS / AUTH ──────────────────────────────────────

static Future<Map<String, dynamic>> register(
    Map<String, dynamic> payload) async {
  final response = await http.post(
    Uri.parse('$baseUrl/users/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );
  if (response.statusCode == 200) return jsonDecode(response.body);
  final detail = jsonDecode(response.body)['detail'] ?? 'Registration failed';
  throw Exception(detail);
}

static Future<Map<String, dynamic>> login(
    String username, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/users/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': username, 'password': password}),
  );
  if (response.statusCode == 200) return jsonDecode(response.body);
  final detail =
      jsonDecode(response.body)['detail'] ?? 'Invalid username or password';
  throw Exception(detail);
}

static Future<List<Map<String, dynamic>>> getUsers() async {
  final response = await http.get(Uri.parse('$baseUrl/users/'));
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }
  throw Exception('Failed to load users: ${response.statusCode}');
}

static Future<Map<String, dynamic>> updateProfile(
    String userId, String fullName, String? mobile) async {
  final response = await http.put(
    Uri.parse('$baseUrl/users/$userId/profile'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'full_name': fullName, 'mobile': mobile}),
  );
  if (response.statusCode == 200) return jsonDecode(response.body);
  final detail = jsonDecode(response.body)['detail'] ?? 'Failed to update profile';
  throw Exception(detail);
}

// ── JOIN REQUESTS ──────────────────────────────────────

static Future<Map<String, dynamic>> createJoinRequest(
    Map<String, dynamic> payload) async {
  final response = await http.post(
    Uri.parse('$baseUrl/join-requests/'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );
  if (response.statusCode == 200) return jsonDecode(response.body);
  final detail = jsonDecode(response.body)['detail'] ?? 'Request failed';
  throw Exception(detail);
}
static Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
  final response = await http.get(
      Uri.parse('$baseUrl/join-requests/group/$groupId/members'));
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }
  throw Exception('Failed to load group members: ${response.statusCode}');
}
static Future<List<Map<String, dynamic>>> getJoinRequests({String? status}) async {
  final params = <String, String>{};
  if (status != null) params['status'] = status;
  final uri = Uri.parse('$baseUrl/join-requests/').replace(queryParameters: params);
  final response = await http.get(uri);
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }
  throw Exception('Failed to load join requests: ${response.statusCode}');
}

static Future<void> updateJoinRequestApproval(String requestId, String status) async {
  final response = await http.put(
    Uri.parse('$baseUrl/join-requests/$requestId/approval'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'status': status}),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to update approval: ${response.body}');
  }
}

static Future<void> directAddMemberToGroup(String memberId, String groupId) async {
  final response = await http.post(
    Uri.parse('$baseUrl/join-requests/direct-add'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'member_id': memberId, 'group_id': groupId}),
  );
  if (response.statusCode != 200) {
    final detail = jsonDecode(response.body)['detail'] ?? 'Failed to add member';
    throw Exception(detail);
  }
}

  // ── CASHBOOK ─────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCashEntries() async {
    final response = await http.get(Uri.parse('$baseUrl/cashbook/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load cashbook: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> createCashEntry(
      Map<String, dynamic> entry) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cashbook/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(entry),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to create cash entry: ${response.body}');
  }

  // ── PRIZES ───────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPrizes(
      {String? groupId}) async {
    final params = <String, String>{};
    if (groupId != null) params['group_id'] = groupId;

    final uri =
        Uri.parse('$baseUrl/prizes/').replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load prizes: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> createPrize(
      Map<String, dynamic> prize) async {
    final response = await http.post(
      Uri.parse('$baseUrl/prizes/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(prize),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to create prize: ${response.body}');
  }
}