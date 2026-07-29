import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:paypal_sdk/subscriptions.dart' show PlanCollection;
import 'package:uresax_invoice_sys_cloud/models/bank.dart'; 
import 'package:uresax_invoice_sys_cloud/models/box.dart';
import 'package:uresax_invoice_sys_cloud/models/categorie.dart';
import 'package:uresax_invoice_sys_cloud/models/client.dart';
import 'package:uresax_invoice_sys_cloud/models/company.dart';
import 'package:uresax_invoice_sys_cloud/models/currency.dart';
import 'package:uresax_invoice_sys_cloud/models/dgiiStates.dart';
import 'package:uresax_invoice_sys_cloud/models/discount.dart';
import 'package:uresax_invoice_sys_cloud/models/ncftype.dart';
import 'package:uresax_invoice_sys_cloud/models/override.codes.dart';
import 'package:uresax_invoice_sys_cloud/models/payment.method.dart';
import 'package:uresax_invoice_sys_cloud/models/payment.mode.dart';
import 'package:uresax_invoice_sys_cloud/models/payment.type.dart';
import 'package:uresax_invoice_sys_cloud/models/permission.dart';
import 'package:uresax_invoice_sys_cloud/models/provider.dart';
import 'package:uresax_invoice_sys_cloud/models/retention.isr.dart';
import 'package:uresax_invoice_sys_cloud/models/retention.tax.dart';
import 'package:uresax_invoice_sys_cloud/models/role.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.element.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/symbol.dart';
import 'package:uresax_invoice_sys_cloud/models/taxes.dart';
import 'package:uresax_invoice_sys_cloud/models/type.income.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';
import 'package:uresax_invoice_sys_cloud/models/warehouse.dart';



Company? company;

List<NcfType> ncfs = [];

List<PaymentMethod> paymentsMethods = [];

List<TypeIncome> typesIncomes = [];

List<Role> roles = [];

List<Bank> banks = [];

List<Permission> permissions = [];

List<Taxes> taxes = [];

List<Currency> currencies = [];

List<PaymentType> paymentsTypes = [];

List<PaymentMode> paymentsModes = [];

List<OverrideCode> overrideCodes = [];

List<Providers> providers = [];

List<WareHouses> wareHouses = [];

List<Discount> discounts = [];

List<SymbolModel> symbols = [];

List<DgiiState> dgiiStates = [];

List<Box> boxes = [];

List<Category> categories = [];

const double kDefaultPadding = 20;

enum SaleMode { service, product }

enum SaleStatus { all, paid, notPaid }

User? currentUser;

bool electronicNcfEnabled = false;

int? currentElectronicNcfOption = 2;

File? certFile;

String? pemCert;

bool isValid = false;

TextEditingController certPath = TextEditingController();

TextEditingController certPassword = TextEditingController();


var hostname = Platform.environment['URESAX_INVOICE_DATABASE_HOSTNAME'];
var databaseName = Platform.environment['URESAX_INVOICE_DATABASE_NAME'];
var dbUsername = Platform.environment['URESAX_INVOICE_DATABASE_USERNAME'];
var dbPassword = Platform.environment['URESAX_INVOICE_DATABASE_PASSWORD'];
var dirPath =   Platform.environment['URESAX_INVOICE_STATIC_LOCAL_SERVER_PATH'];
var port = Platform.environment['URESAX_INVOICE_DATABASE_PORT'];
var timezone = Platform.environment['URESAX_INVOICE_DB_TIMEZONE'] ?? 'America/Mexico_City';

List<SaleElement> elements = [];

List<RetentionTax> retentionsTaxes = [];

List<RetentionIsr> retentionsIsrs = [];
List<String> printers =[];

String? devicePos = localStorage.getItem('devicePos');
String? devicePosBarcodes = localStorage.getItem('devicePosBarcodes');


bool eCommerceMode = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ECOMMERCE_MODE'] ?? 'false') ?? false;

bool enabledBarCodePrinter = bool.tryParse(
            Platform.environment['URESAX_INVOICE_BARCODE_PRINTER'] ?? 'false') ?? false;

bool enabledVerticalPosInvoice = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_VERTICAL_POS_INVOICE'] ?? 'false') ?? false;

bool enabledEcfProduction = bool.parse(Platform.environment['URESAX_INVOICE_ENABLED_ECF_PRODUCTION'] ?? 'false');

bool allowEditInvoice = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ALLOW_EDIT_INVOICE'] ??
                'false') ??
        false;


bool automaticSendEcf = bool.tryParse(
            Platform.environment['URESAX_INVOICE_AUTOMATIC_SEND_ECF'] ??
                'false') ??
        false;

bool enabledRetentions = bool.tryParse(Platform.environment['URESAX_INVOICE_ENABLED_RETENTIONS'] ?? 'false') ?? false;

bool enabledRestaurantMode = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_RESTAURANT_MODE'] ?? 'false') ??
        false;

bool enabledInvoiceSimpleGenerator = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_INVOICE_SIMPLE_GENERATOR'] ?? 'false') ??
        false;

bool enabledImageChanges = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_IMAGE_CHANGE'] ?? 'false') ??
        false;


bool enabledProductQuantityEditor = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_PRODUCT_QUANTITY_EDITOR'] ?? 'false') ??
        false;

bool enabledTextEditor = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_TEXT_EDITOR'] ?? 'false') ??
        false;

bool enabledPosAutomaticSetup = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_POS_AUTOMATIC_SETUP'] ?? 'false') ??
        false;

bool enabledTotalsConfigSimple = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_TOTAL_CONFIG_SIMPLE'] ?? 'false') ??
        false;

bool enabledProformaUpdateStock = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_PROFORMA_UPDATE_STOCK'] ?? 'false') ??
        false;

bool enabledRemoteSigned = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_REMOTE_SIGNED'] ?? 'false') ??
        false;

bool removeInvoiceTitle = bool.tryParse(
            Platform.environment['URESAX_INVOICE_REMOVE_INVOICE_TITLE'] ?? 'false') ??
        false;

bool enabledOnlySeller = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ONLY_SELLER'] ?? 'false') ??
        false;

bool disabledTicket = bool.tryParse(
            Platform.environment['URESAX_INVOICE_DISABLED_TICKET'] ?? 'false') ??
        false;

bool enabledEditPriceModal = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_EDIT_PRICE'] ?? 'false') ??
        false;

bool enabledQuotationsSetup = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_QUOTATIONS_SETUP'] ?? 'false') ??
        false;

bool enabledTableInvoiceGenerator = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_TABLE_INVOICE_GENERATOR'] ?? 'false') ??
        false;

bool enabledRealEstateAgency = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_REAL_ESTATE_AGENCY'] ?? 'false') ??
        false;
bool enabledItemSimpleConfig = bool.tryParse(
            Platform.environment['URESAX_INVOICE_ENABLED_ITEMS_SIMPLE_CONFIG'] ?? 'false') ??
        false;
String appVersion = 'Desconocida';
String localVersion = 'Desconocida';
String remoteVersion = 'Desconocida';
bool versionChanged = false;

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();


final Color secondaryColor = const Color.fromARGB(255, 11, 146, 15);

late PlanCollection plans;

bool subscriptionActive = false;
bool subscriptionCancel = false;
bool subscriptionPause = false;
bool notExistsSubscriptionsTable=true;
bool enabledInvoiceDollars = bool.tryParse(Platform.environment['URESAX_INVOICE_ENABLED_INVOICE_DOLLARS'] ?? 'false') ?? false;

bool enabledStore = bool.tryParse(Platform.environment['URESAX_INVOICE_ENABLED_STORE'] ?? 'false') ?? false;
Client? currentClientContado;

const double kDefaultNavbarHeight = kToolbarHeight + kDefaultPadding;