import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class Client {
  String? id;
  String? name;
  String? identification;
  String? phone;
  String? email;
  String? address;
  DateTime? createdAt;
  Client({
    this.id,
    this.name,
    this.identification,
    this.phone,
    this.email,
    this.address,
    this.createdAt,
  });

  static Future<List<Client>> get({String? search}) async {
    try {
            await User.authClient();
      String params = '?';

      if (search != null) {
        params += 'search=$search';
      }
      var res = await apiUresax.get('/clients/all$params');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<Client>.from((data as List).map((x) => Client.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
      throw e.response?.data['message'];
    }
  }

  static Future<Client?> findClientContado() async {
    try {
      await User.authClient();
      if(currentClientContado != null) return currentClientContado;
      var res = await apiUresax.get('/clients/findcontado');

      if (res.statusCode == 200) {
        currentClientContado = Client.fromMap(res.data);
        return currentClientContado;
      }

      return null;
    } catch (e) {
       return null;
    }
  }

  static Future<Client?> findById(String identification) async {
    try {
            await User.authClient();
      var res = await apiUresax.get('/clients/find/$identification');

      if (res.statusCode == 200) {
        return Client.fromMap(res.data);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Client?> create() async {
    try {
            await User.authClient();
           var map = toMapInsert();
      var res = await apiUresax.post('/clients/create',data: {
        ...map
      });

      if(res.statusCode == 200){
        return Client.fromMap(res.data);
      }
     
     return null;
    } on DioException catch (e) {
       throw e.response?.data['message'];
    }
  }

  Future<Client?> update() async {
    try {
      await User.authClient();
      var res = await apiUresax.put('/clients/update/$id',data: {
        ...toMapInsert()
      });

      if(res.statusCode == 200){
        return Client.fromMap(res.data);
      }
     
     return null;
    } on DioException catch (e) {
       throw e.response?.data['message'];
    }
  }

  static Future<bool> checkIfExistInvoices(
      {required String identification}) async {
    try {
            await User.authClient();
      var res = await apiUresax.get('/clients/check-if-exist-invoices/$identification');

      if(res.statusCode == 200){
        return true;
      }
    
      return false;
    } on DioException catch (e) {
      throw e.response?.data['message'];
    }
  }

  Client copyWith({
    String? id,
    String? name,
    String? identification,
    String? phone,
    String? email,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      identification: identification ?? this.identification,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'identification': identification,
      'phone': phone,
      'email': email,
      'createdAt': createdAt,
    };
  }

  Map<String, dynamic> toMapInsert() {
    return {
      'id': id,
      'name': name,
      'identification': identification,
      'phone': phone,
      'email': email,
      'address': address
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      identification: map['identification'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt']).toLocal()
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Client.fromJson(String source) =>
      Client.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Client(id: $id, name: $name, identification: $identification, phone: $phone, email: $email, address: $address, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Client &&
        o.id == id &&
        o.name == name &&
        o.identification == identification &&
        o.phone == phone &&
        o.email == email &&
        o.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        identification.hashCode ^
        phone.hashCode ^
        email.hashCode ^
        createdAt.hashCode;
  }
}
