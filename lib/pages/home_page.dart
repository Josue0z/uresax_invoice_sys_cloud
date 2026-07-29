import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/modals/company.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/modals/electronic.ncf.settings.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.product.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.service.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.service.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.service.dart';
import 'package:uresax_invoice_sys_cloud/pages/boxes_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/categories_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/clients_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/cotizations_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/credit.notes_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/entries_purchases_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/invoice_generator_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/invoices_models_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/login_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/ncf.list_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/ncfs.sequences_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/ordens_purchases_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/pos_screen.dart';
import 'package:uresax_invoice_sys_cloud/pages/products_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/providers_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/reports-sales-page.dart';
import 'package:uresax_invoice_sys_cloud/pages/sales.607.form_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/sales_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/services_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/table_invoice_generator.dart';
import 'package:uresax_invoice_sys_cloud/pages/units_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/users_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/warehouses_page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/widgets/scrollmove.event.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/updater.widget.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> options = [
    {
      'id': 1,
      'title': 'GENERAR FACTURA DE SERVICIO',
      'svg': 'assets/svgs/undraw_files-uploading_qf8u.svg'
    },
    {
      'id': 2,
      'title': 'GENERAR FACTURA DE PRODUCTO',
      'svg': 'assets/svgs/undraw_product-iteration_r2wg.svg'
    },
    {
      'id': 8,
      'title': 'GENERAR NOTA DE CREDITO DE SERVICIO',
      'svg': 'assets/svgs/undraw_statistic-chart_6s7z.svg'
    },
    {
      'id': 9,
      'title': 'GENERAR NOTA DE CREDITO DE PRODUCTO',
      'svg': 'assets/svgs/undraw_printing-invoices_osgs.svg'
    },
    {
      'id': 3,
      'title': 'MANEJAR SERVICIOS',
      'svg': 'assets/svgs/undraw_services_dhxj.svg'
    },
    {
      'id': 4,
      'title': 'MANEJAR PRODUCTOS',
      'svg': 'assets/svgs/undraw_groceries_4via.svg'
    },
    {
      'id': 16,
      'title': 'VER CATEGORIAS',
      'svg': 'assets/svgs/undraw_logistics_xpdj.svg'
    },
    {
      'id': 13,
      'title': 'PROVEEDORES',
      'svg': 'assets/svgs/undraw_order-delivered_puaw.svg'
    },
    {
      'id': 14,
      'title': 'ALMACENES',
      'svg': 'assets/svgs/undraw_web-shopping_xd5k.svg'
    },
    {
      'id': 15,
      'title': 'VER ORDENES DE COMPRAS',
      'svg': 'assets/svgs/undraw_successful-purchase_p2fz.svg'
    },
     {
      'id': 19,
      'title': 'VER ENTRADAS DE ALMACEN',
      'svg': 'assets/svgs/undraw_successful-purchase_p2fz.svg'
    },
    {
      'id': 5,
      'title': 'TUS FACTURAS',
      'svg': 'assets/svgs/undraw_receipt_tzi0.svg'
    },
    {
      'id': 10,
      'title': 'TUS NOTAS DE CREDITO',
      'svg': 'assets/svgs/undraw_receipt_tzi0.svg'
    },
        {
      'id': 20,
      'title': 'VER TUS COTIZACIONES',
      'svg': 'assets/svgs/undraw_receipt_tzi0.svg'
    },
      {
      'id': 21,
      'title': 'VER GENERADOR DE REPORTES',
      'svg': 'assets/svgs/undraw_report_k55w.svg'
    },
    {
      'id': 6,
      'title': 'TUS CLIENTES',
      'svg': 'assets/svgs/undraw_interview_yz52.svg'
    },
    {
      'id': 7,
      'title': 'GENERADOR DE FORMULARIO 607',
      'svg': 'assets/svgs/undraw_complete-form_aarh.svg'
    },
    {
      'id': 11,
      'title': 'VER TUS COMPROBANTES',
      'svg': 'assets/svgs/undraw_key-points_mnrr.svg'
    },
    {
      'id': 12,
      'title': 'LISTA NCFS AGREGADOS',
      'svg': 'assets/svgs/undraw_timeline_2gfy.svg'
    },
    {
      'id': 17,
      'title': 'VER CAJAS',
      'svg': 'assets/svgs/undraw_payments_nbqu.svg'
    },
    {
      'id': 18,
      'title': 'VER UNIDADES DE MEDIDA',
      'svg': 'assets/svgs/undraw_report_k55w.svg'
    },


  ];
  ScrollController scrollControllerY = ScrollController();
  late List<Map<String, dynamic>> defaultOptions = [];

  _showInvoiceGenerator(SaleMode mode, List<SaleItem> items, Sale sale) {
    if( (enabledInvoiceSimpleGenerator && (sale is SaleProduct || sale is SaleService) )  ){
       Navigator.push(context, MaterialPageRoute(builder: (ctx) {
      return PosScreenPage( items: [], sale: sale);
    }));
    } else if(enabledTableInvoiceGenerator){
          Navigator.push(context, MaterialPageRoute(builder: (ctx) {
      return TableInvoiceGenerator( items: items, sale: sale ,mode: mode);
    }));
    }
    else{
      Navigator.push(context, MaterialPageRoute(builder: (ctx) {
      return InvoiceGeneratorPage(mode: mode, items: items, sale: sale);
    }));
    }
    
  }

  _showServicesPage() async {
    Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => ServicesPage()));
  }

  _showSales() async {
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => SalesPage()));
  }

  _show607FormPage() async {
    Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => Sales607FormPage()));
  }

  _showProductsPage() async {
    Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => ProductsPage()));
  }

  _showClientsPage() async {
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => ClientsPage()));
  }

  _showCreditNotes() async {
    Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => CreditNotesPage()));
  }

  _showUsersPage() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => UsersPage()));
    setState(() {});
  }

    _showCotizationsPage() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => CotizationsPage()));
    setState(() {});
  }

  _showCompanyDetailsPage() async {
    var res = await showDialog(
        context: context, builder: (ctx) => CompanyEditorModal());
    if (res == 'UPDATE') {
      setState(() {});
    }
  }

  _showElectronicNcfSettingsPage() async {
    await showDialog(
        context: context, builder: (ctx) => ElectronicNcfSettingsModal());
  }

  _showNcfs() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => NcfsSequencesPage()));
  }

  _showNcfsList() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => NcfListPage()));
  }

  _showProvidersPage() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => ProvidersPage()));
  }

  _showWareHousesPage() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => WareHousesPage()));
  }

  _showOrdensPurchasesPage() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => OrdensPurchasesPage()));
  }

  _showEntriesPurchasesPage() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => EntriesPurchasesPage()));
  }

  _showCategoriesPage() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => CategoriesPage()));
  }

  _showBoxesPage() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => BoxesPage()));
  }

  _showUnitsPage() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => UnitsPage()));
  }

  _showReportsPage()async{
    await Navigator.push(context,MaterialPageRoute(builder: (ctx) => ReportsSalesPage()));
  }

  _showPage(int id) {
    switch (id) {
      case 1:
        _showInvoiceGenerator(SaleMode.service,
            [SaleItemService(id: Uuid().v4(),quantity: 1.0)], SaleService());
        break;

      case 2:
        _showInvoiceGenerator(SaleMode.product,
            [SaleItemProduct(id: Uuid().v4(),quantity: 1.0)], SaleProduct());
        break;
      case 3:
        _showServicesPage();
      case 5:
        _showSales();
        break;
      case 6:
        _showClientsPage();
        break;
      case 7:
        _show607FormPage();
        break;
      case 4:
        _showProductsPage();
        break;
      case 8:
        _showInvoiceGenerator(
            SaleMode.service, List.of([]), CreditNoteAsService());
        break;
      case 9:
        _showInvoiceGenerator(
            SaleMode.product, List.of([]), CreditNoteAsProduct());
        break;
      case 10:
        _showCreditNotes();
        break;
      case 11:
        _showNcfs();
        break;
      case 12:
        _showNcfsList();
        break;

      case 13:
        _showProvidersPage();
        break;
      case 14:
        _showWareHousesPage();
        break;

      case 15:
        _showOrdensPurchasesPage();
        break;

      case 16:
        _showCategoriesPage();
        break;
      case 17:
        _showBoxesPage();
        break;
      case 18:
        _showUnitsPage();
        break;
    case 19:
    _showEntriesPurchasesPage();
    break;
      case 20:
        _showCotizationsPage();
        break;

    case 21:
    _showReportsPage();
    break;
      default:
    }
  }

  @override
  void initState() {
    defaultOptions = [...options];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!currentUser!.permissions!.contains('ALLOW_VIEW_CREATE_SALE_SERVICE')) {
      options.removeWhere((e) => e['id'] == 1);
    }
    if (!currentUser!.permissions!.contains('ALLOW_VIEW_CREATE_SALE_PRODUCT')) {
      options.removeWhere((e) => e['id'] == 2);
    }
    if (!currentUser!.permissions!
        .contains('ALLOW_VIEW_CREATE_CREDIT_NOTE_SERVICE')) {
      options.removeWhere((e) => e['id'] == 8);
    }

    if (!currentUser!.permissions!
        .contains('ALLOW_VIEW_CREATE_CREDIT_NOTE_PRODUCT')) {
      options.removeWhere((e) => e['id'] == 9);
    }

    if (!currentUser!.permissions!.contains('ALLOW_VIEW_SERVICES')) {
      options.removeWhere((e) => e['id'] == 3);
    }
    if (!currentUser!.permissions!.contains('ALLOW_VIEW_PRODUCTS')) {
      options.removeWhere((e) => e['id'] == 4);
    }

    if (!currentUser!.permissions!.contains('ALLOW_VIEW_SALES')) {
      options.removeWhere((e) => e['id'] == 5);
    }
    if (!currentUser!.permissions!.contains('ALLOW_VIEW_CREDIT_NOTES')) {
      options.removeWhere((e) => e['id'] == 10);
    }
    if (!currentUser!.permissions!.contains('ALLOW_VIEW_CLIENTS')) {
      options.removeWhere((e) => e['id'] == 6);
    }

    if (!currentUser!.permissions!.contains('ALLOW_VIEW_CREATE_FORM_607')) {
      options.removeWhere((e) => e['id'] == 7);
    }

    if (!currentUser!.permissions!.contains('ALLOW_VIEW_NCFS_EDITOR')) {
      options.removeWhere((e) => e['id'] == 11);
    }

    if (!currentUser!.permissions!.contains('ALLOW_VIEW_NCFS_LIST_EDITOR')) {
      options.removeWhere((e) => e['id'] == 12);
    }
    if (!currentUser!.permissions!.contains('ALLOW_VIEW_PROVIDERS')) {
      options.removeWhere((e) => e['id'] == 13);
    }
    if (!currentUser!.permissions!.contains('ALLOW_VIEW_WAREHOUSES')) {
      options.removeWhere((e) => e['id'] == 14);
    }

    if (!currentUser!.permissions!.contains('ALLOW_VIEW_ORDENS_PURCHASES')) {
      options.removeWhere((e) => e['id'] == 15);
    }
     if (!currentUser!.permissions!.contains('ALLOW_VIEW_ENTRIES_PURCHASES')) {
      options.removeWhere((e) => e['id'] == 19);
    }

    if (!currentUser!.permissions!.contains('ALLOW_VIEW_CATEGORIES')) {
      options.removeWhere((e) => e['id'] == 16);
    }

    if (!currentUser!.permissions!.contains('ALLOW_VIEW_BOXES')) {
      options.removeWhere((e) => e['id'] == 17);
    }
    if (!currentUser!.permissions!.contains('ALLOW_VIEW_UNITS')) {
      options.removeWhere((e) => e['id'] == 18);
    }
        if (!currentUser!.permissions!.contains('ALLOW_VIEW_COTIZATIONS')) {
      options.removeWhere((e) => e['id'] == 20);
    }
      if (!currentUser!.permissions!.contains('ALLOW_VIEW_REPORTS')) {
      options.removeWhere((e) => e['id'] == 21);
    }
    
    return UpdaterWidget(
        context: context,
        child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TABLERO -  BIENVENIDO ${company?.name}!'),
                  SizedBox(height: kDefaultPadding / 2),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(kDefaultPadding / 2),
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(currentUser?.username ?? '',
                            textAlign: TextAlign.right,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white)),
                      ),
                      SizedBox(width: kDefaultPadding / 2),
                      Text(appVersion,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500))
                    ],
                  )
                ],
              ),
              actions: [
                Wrap(
                  runAlignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                   /* Container(
                      margin: EdgeInsets.only(right: kDefaultPadding),
                      child: CircleAvatar(
                            child: IconButton(
                                onPressed: ()async{
                               await  Navigator.push(context, MaterialPageRoute(builder: (ctx)=>BarcodeList(codes: [
                                    '10009011111',
                                    '45000922222',
                                    '50000022222',
                                    '10000000001',
                                    '90000000001',
                                    '10190202111'
                                  ])));
                                },
                                icon: Icon(Icons.barcode_reader)),
                          ),
                    ),*/
                    currentUser!.permissions!
                            .contains('ALLOW_VIEW_ELECTRONIC_SETTINGS')
                        ? CircleAvatar(
                            child: IconButton(
                                onPressed: _showElectronicNcfSettingsPage,
                                icon: Icon(Icons.receipt_long)),
                          )
                        : SizedBox(),
                    SizedBox(
                      width: kDefaultPadding,
                    ),
                    currentUser!.permissions!.contains('ALLOW_EDIT_COMPANY')
                        ? CircleAvatar(
                            child: IconButton(
                                onPressed: _showCompanyDetailsPage,
                                icon: Icon(Icons.store_outlined)),
                          )
                        : SizedBox(),
                    SizedBox(
                      width: kDefaultPadding,
                    ),
                    currentUser!.permissions!.contains('ALLOW_VIEW_USERS')
                        ? CircleAvatar(
                            child: IconButton(
                                onPressed: _showUsersPage,
                                icon: Icon(Icons.people)),
                          )
                        : SizedBox(),
                    SizedBox(
                      width: kDefaultPadding,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currentUser?.name ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(color: Colors.white),
                            textAlign: TextAlign.right),
                        SizedBox(height: kDefaultPadding / 2),
                        Container(
                          padding: EdgeInsets.all(kDefaultPadding / 2),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(currentUser?.roleName ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context).primaryColor)),
                        ),
                        SizedBox(height: kDefaultPadding / 2),
                      ],
                    ),
                    SizedBox(
                      width: kDefaultPadding,
                    ),
                  Container(
                            margin: EdgeInsets.only(right: kDefaultPadding),
                            child: CircleAvatar(
                              child: IconButton(
                                  onPressed: () async {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (ctx) =>
                                                InvoicesModelsPage()));
                                  },
                                  icon: Icon(Icons.receipt_long_outlined)),
                            ),
                          ),
             
                    CircleAvatar(
                      child: IconButton(
                          onPressed: () async {
                            Navigator.pushAndRemoveUntil(
                                context,
                                PageRouteTransitionBuilder(
                                    page: LoginPage(),
                                    effect: TransitionEffect.topToBottom),
                                (_) => false);
                            await LogHandler.printEvent(
                                '${currentUser?.name} CERRO SESION');
                            currentUser = null;
                            company = null;
                            currentClientContado = null;
                            discounts = [];
                            retentionsTaxes = [];
                            retentionsIsrs = [];
                            taxes = [];
                            typesIncomes = [];
                            overrideCodes = [];
                            paymentsMethods = [];
                            paymentsTypes = [];
                            paymentsModes = [];
                            symbols = [];
                            dgiiStates = [];
                            boxes = [];
                            wareHouses = [];
                          },
                          icon: Icon(Icons.power_settings_new_outlined)),
                    ),
                    SizedBox(
                      width: kDefaultPadding * 2,
                    )
                  ],
                )
              ],
            ),
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 50,
                  margin: EdgeInsets.symmetric(
                      vertical: kDefaultPadding,
                      horizontal: kDefaultPadding / 2),
                  child: TextFormField(
                    onChanged: (words) {
                      var xoptions = options
                          .where((e) => (e['title'] as String)
                              .toLowerCase()
                              .contains(words.toLowerCase()))
                          .toList();

                      if (words.isNotEmpty) {
                        options = xoptions;
                      } else {
                        options = defaultOptions;
                      }
                      setState(() {});
                    },
                    decoration: InputDecoration(
                        labelText: 'BUSCAR',
                        hintText: 'Escribir algo...',
                        suffixIcon: Icon(Icons.search)),
                  ),
                ),
                Expanded(
                    child: ScrollMoveEventWidget(
                  scrollControllerY: scrollControllerY,
                  child: GridView.builder(
                      controller: scrollControllerY,
                      physics: Theme.of(context).platform ==
                                  TargetPlatform.iOS ||
                              Theme.of(context).platform == TargetPlatform.macOS
                          ? const BouncingScrollPhysics()
                          : const ClampingScrollPhysics(),
                      itemCount: options.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4),
                      itemBuilder: (ctx, i) {
                        var option = options[i];
                        return _CardHover(
                            option: option,
                            onTap: () {
                              _showPage(option['id']);
                            });
                      }),
                ))
              ],
            )));
  }
}

class _CardHover extends StatefulWidget {
  final Map<String, dynamic> option;
  VoidCallback onTap;

  _CardHover({required this.option, required this.onTap});

  @override
  State<_CardHover> createState() => __CardHoverState();
}

class __CardHoverState extends State<_CardHover> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
  
    return MouseRegion(
      opaque: false,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
          duration: Duration(seconds: 1),
          child: Card(
              clipBehavior: Clip.hardEdge,
              shape: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      style: BorderStyle.solid,
                      color: _isHovered
                          ? Theme.of(context).primaryColor
                          : Colors.transparent)),
              child: Ink(
                child: InkWell(
                  onTap: widget.onTap,
                  child: Center(
                      child: Padding(
                    padding: EdgeInsets.all(kDefaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(widget.option['svg'], width: 100),
                        SizedBox(height: kDefaultPadding),
                        Text(widget.option['title'],
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize:15
                            ),
                            textAlign: TextAlign.center)
                      ],
                    ),
                  )),
                ),
              ))),
    );
  }
}
