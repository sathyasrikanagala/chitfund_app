import 'package:uuid/uuid.dart';

class Member {
  final String id;
  final String name;
  final String mobile;
  final String? fatherName;
  final String village;
  final String? address;
  final String? idProofType;
  final String? idProofNumber;
  final String? nomineeName;
  final String? nomineeMobile;
  final String status;
  final String createdAt;

  Member({
    String? id,
    required this.name,
    required this.mobile,
    this.fatherName,
    required this.village,
    this.address,
    this.idProofType,
    this.idProofNumber,
    this.nomineeName,
    this.nomineeMobile,
    this.status = 'Active',
    String? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'father_name': fatherName,
      'village': village,
      'address': address,
      'id_proof_type': idProofType,
      'id_proof_number': idProofNumber,
      'nominee_name': nomineeName,
      'nominee_mobile': nomineeMobile,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      name: map['name'],
      mobile: map['mobile'],
      fatherName: map['father_name'],
      village: map['village'],
      address: map['address'],
      idProofType: map['id_proof_type'],
      idProofNumber: map['id_proof_number'],
      nomineeName: map['nominee_name'],
      nomineeMobile: map['nominee_mobile'],
      status: map['status'] ?? 'Active',
      createdAt: map['created_at'],
    );
  }
}