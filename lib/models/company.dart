import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:localstorage/localstorage.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/apis/sql.dart';

class Company {
  String? id;
  String? name;
  String? comercialName;
  String? rncOrId;
  String? phone1;
  String? phone2;
  String? email;
  String? address;
  String? logo;
  DateTime? expirationDate;
  String? message;
  String? bankInfo;
  int? maxPreSales;
  String? instagramLink;
  final bool eCommerceMode;
  final bool enabledBarCodePrinter;
  final bool enabledVerticalPosInvoice;
  final bool enabledEcfProduction;
  final bool allowEditInvoice;
  final bool automaticSendEcf;
  final bool enabledRetentions;
  final bool enabledRestaurantMode;
  final bool enabledInvoiceSimpleGenerator;
  final bool enabledImageChanges;
  final bool enabledProductQuantityEditor;
  final bool enabledTextEditor;
  final bool enabledPosAutomaticSetup;
  final bool enabledTotalsConfigSimple;
  final bool enabledProformaUpdateStock;
  final bool enabledRemoteSigned;
  final bool removeInvoiceTitle;
  final bool enabledOnlySeller;
  final bool disabledTicket;
  final bool enabledEditPriceModal;
  final bool enabledQuotationsSetup;
  final bool enabledTableInvoiceGenerator;
  final bool enabledRealEstateAgency;
  final bool enabledItemSimpleConfig;
  final bool enabledFullGeneratorTableInvoice;
  final bool enabledStepRncTableInvoice;
  final bool enabledInvoiceDollars;
  final bool enabledStore;
  final bool allowOnlyCashShiftElectronic;
  final bool enabledViewCashShiftDetails;
  final bool enabledFilterInvoicesByDay;
  final bool enabledFirstComercialName;
  final bool enabledMultiplyBranches;
  final bool enabledInvoiceNotes;
  int? currentInvoiceIndex;
  Company({
    this.id,
    this.name,
    this.comercialName,
    this.rncOrId,
    this.phone1,
    this.phone2,
    this.email,
    this.address,
    this.logo,
    this.expirationDate,
    this.message,
    this.bankInfo,
    this.maxPreSales = 99999999,
    this.instagramLink,
    this.eCommerceMode = false,
    this.enabledBarCodePrinter = false,
    this.enabledVerticalPosInvoice = false,
    this.enabledEcfProduction = false,
    this.allowEditInvoice = false,
    this.automaticSendEcf = false,
    this.enabledRetentions = false,
    this.enabledRestaurantMode = false,
    this.enabledInvoiceSimpleGenerator = false,
    this.enabledImageChanges = false,
    this.enabledProductQuantityEditor = false,
    this.enabledTextEditor = false,
    this.enabledPosAutomaticSetup = false,
    this.enabledTotalsConfigSimple = false,
    this.enabledProformaUpdateStock = false,
    this.enabledRemoteSigned = false,
    this.removeInvoiceTitle = false,
    this.enabledOnlySeller = false,
    this.disabledTicket = false,
    this.enabledEditPriceModal = false,
    this.enabledQuotationsSetup = false,
    this.enabledTableInvoiceGenerator = false,
    this.enabledRealEstateAgency = false,
    this.enabledItemSimpleConfig = false,
    this.enabledFullGeneratorTableInvoice = true,
    this.enabledStepRncTableInvoice = false,
    this.enabledInvoiceDollars = false,
    this.enabledStore = false,
    this.allowOnlyCashShiftElectronic = false,
    this.enabledViewCashShiftDetails = false,
    this.enabledFilterInvoicesByDay = false,
    this.enabledFirstComercialName = false,
    this.enabledMultiplyBranches = false,
    this.enabledInvoiceNotes = false,
    this.currentInvoiceIndex = 0
  });

  static Future<Company?> get() async {
    try {
      final conn = SqlConector.connection;
      var result =
          await conn?.execute('select * from public."Company" LIMIT 1');
      if (result != null) {
        var first = result[0];
        return Company.fromMap(first.toColumnMap());
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Company?> update() async {
    try {
      var res = await apiUresax.put('/companies/$id', data: toMap());

      if (res.statusCode == 200) {
        return Company.fromMap(res.data);
      }
      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Company copyWith(
      {String? name,
      String? rncOrId,
      String? phone1,
      String? phone2,
      String? email,
      String? address,
      String? logo,
      String? message,
      String? bankInfo,
      int? maxPreSales,
      String? instagramLink}) {
    return Company(
        name: name ?? this.name,
        rncOrId: rncOrId ?? this.rncOrId,
        phone1: phone1 ?? this.phone1,
        phone2: phone2 ?? this.phone2,
        email: email ?? this.email,
        address: address ?? this.address,
        logo: logo ?? this.logo,
        message: message ?? this.message,
        bankInfo: bankInfo ?? this.bankInfo,
        maxPreSales: maxPreSales ?? this.maxPreSales,
        instagramLink: instagramLink ?? this.instagramLink);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'comercialName': comercialName,
      'rncOrId': rncOrId,
      'phone1': phone1,
      'phone2': phone2,
      'email': email,
      'address': address,
      'logo': logo,
      'message': message,
      'bankInfo': bankInfo,
      'maxPreSales': maxPreSales,
      'instagramLink': instagramLink
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {

    return Company(
      id: map['id'],
      name: map['name'],
      comercialName: localStorage.getItem('URESAX_INVOICE_BRANCHE_NAME_${map['id']}') ??
          Platform.environment['URESAX_INVOICE_COMPANY_COMERCIAL_NAME_${map['id']}'] ??
              map['comercialName'],
      rncOrId: map['rncOrId'],
      phone1:  localStorage.getItem('URESAX_INVOICE_BRANCHE_PHONE1_${map['id']}') ?? Platform.environment['URESAX_INVOICE_COMPANY_PHONE1'] ??
          map['phone1'],
      phone2: localStorage.getItem('URESAX_INVOICE_BRANCHE_PHONE2_${map['id']}') ?? Platform.environment['URESAX_INVOICE_COMPANY_PHONE2'] ??
          map['URESAX_INVOICE_COMPANY_PHONE2'] ??
          map['phone2'],
      email:localStorage.getItem('URESAX_INVOICE_BRANCHE_EMAIL_${map['id']}') ?? 
          Platform.environment['URESAX_INVOICE_COMPANY_EMAIL'] ?? map['email'],
      address: localStorage.getItem('URESAX_INVOICE_BRANCHE_ADDRESS_${map['id']}') ?? Platform.environment['URESAX_INVOICE_COMPANY_ADDRESS_NAME'] ??
          map['address'],
      logo: map['logo'],
      message: Platform.environment['URESAX_INVOICE_COMPANY_MESSAGE'] ??
          map['message'],
      bankInfo: map['bankInfo'],
      maxPreSales: map['maxPreSales'] ?? 99999999,
      instagramLink: map['instagramLink'],
      enabledFirstComercialName: bool.tryParse(Platform
                  .environment['URESAX_INVOICE_ENABLED_FIRST_COMERCIAL_NAME'] ??
              (map['URESAX_INVOICE_ENABLED_FIRST_COMERCIAL_NAME']?.toString() ?? 'false')) ??
          false,
      // Variables booleanas con prioridad en entorno
      eCommerceMode: bool.tryParse(Platform
                  .environment['URESAX_INVOICE_ECOMMERCE_MODE'] ??
              (map['URESAX_INVOICE_ECOMMERCE_MODE']?.toString() ?? 'false')) ??
          false,

      enabledBarCodePrinter: bool.tryParse(Platform
                  .environment['URESAX_INVOICE_BARCODE_PRINTER'] ??
              (map['URESAX_INVOICE_BARCODE_PRINTER']?.toString() ?? 'false')) ??
          false,

      enabledVerticalPosInvoice: bool.tryParse(Platform
                  .environment['URESAX_INVOICE_ENABLED_VERTICAL_POS_INVOICE'] ??
              (map['URESAX_INVOICE_ENABLED_VERTICAL_POS_INVOICE']?.toString() ??
                  'false')) ??
          false,

      enabledEcfProduction: bool.tryParse(
              Platform.environment['URESAX_INVOICE_ENABLED_ECF_PRODUCTION'] ??
                  (map['URESAX_INVOICE_ENABLED_ECF_PRODUCTION']?.toString() ??
                      'false')) ??
          false,

      allowEditInvoice: bool.tryParse(
              Platform.environment['URESAX_INVOICE_ALLOW_EDIT_INVOICE'] ??
                  (map['URESAX_INVOICE_ALLOW_EDIT_INVOICE']?.toString() ??
                      'false')) ??
          false,

      enabledInvoiceNotes: map['URESAX_INVOICE_ENABLED_INVOICE_NOTES'],

      automaticSendEcf: bool.tryParse(
              Platform.environment['URESAX_INVOICE_AUTOMATIC_SEND_ECF'] ??
                  (map['URESAX_INVOICE_AUTOMATIC_SEND_ECF']?.toString() ??
                      'false')) ??
          false,

      enabledRetentions: bool.tryParse(
              Platform.environment['URESAX_INVOICE_ENABLED_RETENTIONS'] ??
                  (map['URESAX_INVOICE_ENABLED_RETENTIONS']?.toString() ??
                      'false')) ??
          false,

      enabledRestaurantMode: bool.tryParse(
              Platform.environment['URESAX_INVOICE_ENABLED_RESTAURANT_MODE'] ??
                  (map['URESAX_INVOICE_ENABLED_RESTAURANT_MODE']?.toString() ??
                      'false')) ??
          false,

      enabledInvoiceSimpleGenerator: bool.tryParse(Platform.environment[
                  'URESAX_INVOICE_ENABLED_INVOICE_SIMPLE_GENERATOR'] ??
              (map['URESAX_INVOICE_ENABLED_INVOICE_SIMPLE_GENERATOR']
                      ?.toString() ??
                  'false')) ??
          false,

      enabledImageChanges: bool.tryParse(
              Platform.environment['URESAX_INVOICE_ENABLED_IMAGE_CHANGE'] ??
                  (map['URESAX_INVOICE_ENABLED_IMAGE_CHANGE']?.toString() ??
                      'false')) ??
          false,

      enabledProductQuantityEditor: bool.tryParse(Platform.environment[
                  'URESAX_INVOICE_ENABLED_PRODUCT_QUANTITY_EDITOR'] ??
              (map['URESAX_INVOICE_ENABLED_PRODUCT_QUANTITY_EDITOR']
                      ?.toString() ??
                  'false')) ??
          false,

      enabledTextEditor: bool.tryParse(
              Platform.environment['URESAX_INVOICE_ENABLED_TEXT_EDITOR'] ??
                  (map['URESAX_INVOICE_ENABLED_TEXT_EDITOR']?.toString() ??
                      'false')) ??
          false,

      enabledPosAutomaticSetup: bool.tryParse(Platform
                  .environment['URESAX_INVOICE_ENABLED_POS_AUTOMATIC_SETUP'] ??
              (map['URESAX_INVOICE_ENABLED_POS_AUTOMATIC_SETUP']?.toString() ??
                  'false')) ??
          false,

      enabledTotalsConfigSimple: bool.tryParse(Platform
                  .environment['URESAX_INVOICE_ENABLED_TOTAL_CONFIG_SIMPLE'] ??
              (map['URESAX_INVOICE_ENABLED_TOTAL_CONFIG_SIMPLE']?.toString() ??
                  'false')) ??
          false,

      enabledProformaUpdateStock: bool.tryParse(Platform.environment[
                  'URESAX_INVOICE_ENABLED_PROFORMA_UPDATE_STOCK'] ??
              (map['URESAX_INVOICE_ENABLED_PROFORMA_UPDATE_STOCK']
                      ?.toString() ??
                  'false')) ??
          false,

      enabledRemoteSigned: bool.tryParse(
              Platform.environment['URESAX_INVOICE_ENABLED_REMOTE_SIGNED'] ??
                  (map['URESAX_INVOICE_ENABLED_REMOTE_SIGNED']?.toString() ??
                      'false')) ??
          false,

      removeInvoiceTitle: bool.tryParse(
              Platform.environment['URESAX_INVOICE_REMOVE_INVOICE_TITLE'] ??
                  (map['URESAX_INVOICE_REMOVE_INVOICE_TITLE']?.toString() ??
                      'false')) ??
          false,

      enabledOnlySeller: bool.tryParse(
              Platform.environment['URESAX_INVOICE_ONLY_SELLER'] ??
                  (map['URESAX_INVOICE_ONLY_SELLER']?.toString() ?? 'false')) ??
          false,

      disabledTicket: bool.tryParse(Platform
                  .environment['URESAX_INVOICE_DISABLED_TICKET'] ??
              (map['URESAX_INVOICE_DISABLED_TICKET']?.toString() ?? 'false')) ??
          false,

      enabledEditPriceModal: bool.tryParse(
              Platform.environment['URESAX_INVOICE_ENABLED_EDIT_PRICE'] ??
                  (map['URESAX_INVOICE_ENABLED_EDIT_PRICE']?.toString() ??
                      'false')) ??
          false,

      enabledQuotationsSetup: bool.tryParse(
              Platform.environment['URESAX_INVOICE_ENABLED_QUOTATIONS_SETUP'] ??
                  (map['URESAX_INVOICE_ENABLED_QUOTATIONS_SETUP']?.toString() ??
                      'false')) ??
          false,

      enabledTableInvoiceGenerator: bool.tryParse(Platform.environment[
                  'URESAX_INVOICE_ENABLED_TABLE_INVOICE_GENERATOR'] ??
              (map['URESAX_INVOICE_ENABLED_TABLE_INVOICE_GENERATOR']
                      ?.toString() ??
                  'false')) ??
          false,

      enabledRealEstateAgency: bool.tryParse(Platform
                  .environment['URESAX_INVOICE_ENABLED_REAL_ESTATE_AGENCY'] ??
              (map['URESAX_INVOICE_ENABLED_REAL_ESTATE_AGENCY']?.toString() ??
                  'false')) ??
          false,

      enabledItemSimpleConfig: bool.tryParse(Platform
                  .environment['URESAX_INVOICE_ENABLED_ITEMS_SIMPLE_CONFIG'] ??
              (map['URESAX_INVOICE_ENABLED_ITEMS_SIMPLE_CONFIG']?.toString() ??
                  'false')) ??
          false,

      enabledFullGeneratorTableInvoice: bool.tryParse(Platform.environment[
                  'URESAX_INVOICE_ENABLED_FULL_GENERATOR_TABLE_INVOICE'] ??
              (map['URESAX_INVOICE_ENABLED_FULL_GENERATOR_TABLE_INVOICE']
                      ?.toString() ??
                  'true')) ??
          true,

      enabledStepRncTableInvoice: bool.tryParse(Platform.environment[
                  'URESAX_INVOICE_ENABLED_STEP_RNC_TABLE_INVOICE'] ??
              (map['URESAX_INVOICE_ENABLED_STEP_RNC_TABLE_INVOICE']
                      ?.toString() ??
                  'false')) ??
          false,

      enabledInvoiceDollars: bool.tryParse(
              Platform.environment['URESAX_INVOICE_ENABLED_INVOICE_DOLLARS'] ??
                  (map['URESAX_INVOICE_ENABLED_INVOICE_DOLLARS']?.toString() ??
                      'false')) ??
          false,

      enabledStore: bool.tryParse(Platform
                  .environment['URESAX_INVOICE_ENABLED_STORE'] ??
              (map['URESAX_INVOICE_ENABLED_STORE']?.toString() ?? 'false')) ??
          false,
      allowOnlyCashShiftElectronic: bool.tryParse(Platform.environment[
                  'URESAX_INVOICE_ALLOW_ONLY_CASH_SHIFT_ELECTRONIC'] ??
              (map['URESAX_INVOICE_ALLOW_ONLY_CASH_SHIFT_ELECTRONIC']
                      ?.toString() ??
                  'false')) ??
          false,
      enabledViewCashShiftDetails: bool.tryParse(Platform.environment[
                  'URESAX_INVOICE_VIEW_CASH_SHIFT_FULL_DETAILS'] ??
              (map['URESAX_INVOICE_VIEW_CASH_SHIFT_FULL_DETAILS']?.toString() ??
                  'false')) ?? false,
     enabledFilterInvoicesByDay: bool.tryParse(Platform.environment[
                  'URESAX_INVOICE_FILTER_INVOICES_BY_DAY'] ??
              (map['URESAX_INVOICE_FILTER_INVOICES_BY_DAY']?.toString() ??
                  'false')) ?? false,
      currentInvoiceIndex: map['URESAX_INVOICE_CURRENT_INVOICE'],
      enabledMultiplyBranches: map['URESAX_INVOICE_ENABLED_MULTIPLY_BRANCHES']
    );
  }

  String toJson() => json.encode(toMap());

  factory Company.fromJson(String source) =>
      Company.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Company(id: $id, name: $name,comercialName: $comercialName, rncOrId: $rncOrId, phone1: $phone1, phone2: $phone2, email: $email, address: $address, logo: $logo, message: $message, bankInfo: $bankInfo, maxPreSales: $maxPreSales,instagramLink:$instagramLink)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Company &&
        o.id == id &&
        o.name == name &&
        o.comercialName == comercialName &&
        o.rncOrId == rncOrId &&
        o.phone1 == phone1 &&
        o.phone2 == phone2 &&
        o.email == email &&
        o.address == address &&
        o.logo == logo;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        comercialName.hashCode ^
        rncOrId.hashCode ^
        phone1.hashCode ^
        phone2.hashCode ^
        email.hashCode ^
        address.hashCode ^
        logo.hashCode;
  }
}
