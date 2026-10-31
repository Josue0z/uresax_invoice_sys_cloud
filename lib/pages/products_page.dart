import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/modals/filter.products.modal.dart';
import 'package:uresax_invoice_sys_cloud/modals/product.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/categorie.dart';
import 'package:uresax_invoice_sys_cloud/models/product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.abs.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/scrollmove.event.widget.dart';

class ProductsPage extends StatefulWidget {
  bool selectedMode;
  bool isOrdenGenerator;
  List<SaleItem>? items;
  Products? parentProduct;
  ProductsPage(
      {super.key,
      this.selectedMode = false,
      this.items,
      this.isOrdenGenerator = false,
      this.parentProduct});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Products> products = [];
  Future? future;
  final TextEditingController _searchController = TextEditingController();
  ScrollController scrollControllerY = ScrollController();

  List<Category> _categories = [];

  _showModal({bool editing = false, required Products product}) async {
    var res = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ProductEditorModal(
            editing: editing,
            isParent: widget.parentProduct != null ? true : false,
            product: product,
            parentProduct: widget.parentProduct));

    if (res != null) {
      setState(() {
        future = _initAsync();
      });
    }
  }

  _deleteProduct(Products product) async {
    try {
      var isConfirm =
          await showConfirm(context, title: 'DESEAS ELIMINAR PRODUCTO?');
      if (isConfirm == true) {
        showLoader(context);
        await product.delete();
        setState(() {
          future = _initAsync();
        });
        showTopSnackBar(context,
            message: 'PRODUCTO ELIMINADO!', color: Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
      await LogHandler.printError(e.toString());
    }
  }

  _showChildrens({required Products product}) async {
    try {
      var xproduct = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) => ProductsPage(parentProduct: product, selectedMode: widget.selectedMode)));
      
      if(xproduct != null){
         Navigator.pop(context,xproduct);
      }
    } catch (e) {
      print(e);
    }
    
  }

  List<int> get xcategories {
    return _categories.map((e) => e.id).toList().cast<int>();
  }

  _initAsync([String? words]) async {
    try {
      products = await Products.get(
          search: words,
          categories: xcategories,
          parentId: widget.parentProduct?.id);
    } catch (e) {
      print(e);
    } finally {
      setState(() {});
    }
  }

  Widget get contentFilled {
    return ScrollMoveEventWidget(
        scrollControllerY: scrollControllerY,
        child: ListView.separated(
            key: PageStorageKey('products_list'),
            controller: scrollControllerY,
            separatorBuilder: (ctx, i) => const Divider(),
            itemCount: products.length,
            itemBuilder: (ctx, index) {
              var product = products[index];
              return Material(
                color: Colors
                    .transparent, // importante para que el ripple se vea sobre el fondo
                child: InkWell(
                  key: ValueKey(product.id),
                  onTap: widget.selectedMode
                      ? () {
                          try {
                            Navigator.pop(context, product);
                          } catch (e) {
                            showTopSnackBar(context,
                                message: e.toString(), color: Colors.red);
                          }
                        }
                      : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        vertical: kDefaultPadding, horizontal: kDefaultPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              product.image != null && enabledImageChanges
                                  ? Container(
                                      margin: EdgeInsets.only(
                                        right: kDefaultPadding,
                                      ),
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              product.imageUrl ?? ''),
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                    )
                                  : Container(
                                      width: 100,
                                      height: 100,
                                      margin: EdgeInsets.only(
                                        right: kDefaultPadding,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.04),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                      child: Icon(Icons.inventory_2_outlined,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    margin: EdgeInsets.only(
                                        bottom: kDefaultPadding / 2),
                                    child: Text(product.name ?? ''),
                                  ),
                                  product.code != null
                                      ? Text(product.code ?? '')
                                      : SizedBox(),
                                  Row(
                                    children: [
                                      currentUser!.permissions!.contains(
                                                      'ALLOW_VIEW_PRODUCT_QUANTITY') ==
                                                  false ||
                                              product.parentId != null
                                          ? SizedBox()
                                          : Container(
                                              margin: EdgeInsets.only(
                                                  top: kDefaultPadding / 3,
                                                  right: kDefaultPadding / 3),
                                              padding: EdgeInsets.all(
                                                  kDefaultPadding / 2),
                                              decoration: BoxDecoration(
                                                color: product.color
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                              ),
                                              child: Text(
                                                product.quantity!
                                                    .toStringAsFixed(2),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                        color: product.color),
                                              ),
                                            ),
                                      Container(
                                        margin: EdgeInsets.only(
                                            top: kDefaultPadding / 3,
                                            right: kDefaultPadding / 3),
                                        padding:
                                            EdgeInsets.all(kDefaultPadding / 2),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          color:
                                              secondaryColor.withOpacity(0.04),
                                        ),
                                        child: Text(
                                          product.categoryName ?? '',
                                          style: TextStyle(
                                              color: secondaryColor,
                                              fontSize: 14),
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(
                                            top: kDefaultPadding / 3),
                                        padding:
                                            EdgeInsets.all(kDefaultPadding / 2),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.04),
                                        ),
                                        child: Text(
                                          product.wareHouseName ?? '',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            spacing: kDefaultPadding,
                            children: [
                              Wrap(
                                runAlignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(product.price?.toCoin() ?? ''),
                                  widget.parentProduct != null ||
                                          product.isUnique == true
                                      ? SizedBox()
                                      : IconButton(
                                          onPressed: () =>
                                              _showChildrens(product: product),
                                          icon: Icon(Icons.visibility_rounded,
                                              color: Colors.black38)),
                                  enabledBarCodePrinter &&
                                          widget.selectedMode == false
                                      ? IconButton(
                                          tooltip: product.code?.isNotEmpty ==
                                                  true
                                              ? 'IMPRIMIR CODIGO DE BARRA: ${product.code}'
                                              : null,
                                          onPressed: () {
                                            if (product.code?.isNotEmpty ==
                                                true) {
                                              var codes = List.generate(
                                                      5,
                                                      (ctx) =>
                                                          product.code ?? '')
                                                  .toList();
                                              if (codes.isNotEmpty == true) {
                                                printBarcodes(codes: codes);
                                              }
                                            }
                                          },
                                          icon: Icon(Icons.print_rounded,
                                              color: Colors.black38))
                                      : SizedBox(),
                                  currentUser!.permissions!
                                          .contains('ALLOW_EDIT_PRODUCT')
                                      ? IconButton(
                                          onPressed: () {
                                            _showModal(
                                                product: product,
                                                editing: true);
                                          },
                                          icon: Icon(Icons.edit,
                                              color: Colors.black38),
                                        )
                                      : SizedBox(),
                                  currentUser!.permissions!
                                          .contains('ALLOW_DELETE_PRODUCT')
                                      ? IconButton(
                                          onPressed: () {
                                            _deleteProduct(product);
                                          },
                                          icon: Icon(Icons.delete,
                                              color: Colors.black38),
                                        )
                                      : SizedBox(),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }));
  }

  Widget get contentEmpty {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/svgs/undraw_product-iteration_r2wg.svg',
              width: 250)
        ],
      ),
    );
  }

  Widget get contentLoading {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  _showFiltersModal() async {
    categories = [Category(name: 'CATEGORIA'), ...await Category.get()];
    var res = await showDialog(
        context: context,
        builder: (ctx) => FilterProductsModal(categories: _categories));
    if (res is Map) {
      setState(() {
        future = _initAsync();
      });
    }
  }

  String get title {
    if (widget.parentProduct != null) {
      return '${widget.parentProduct?.name} (${products.length})';
    }
    return 'TUS PRODUCTOS (${products.length})';
  }

  @override
  void initState() {
    setState(() {
      future = _initAsync();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: kToolbarHeight + 50,
        title: Text(title),
        actions: [
          Wrap(
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 50,
                child: TextFormField(
                  controller: _searchController,
                  onFieldSubmitted: (words) async {
                    setState(() {
                      future = _initAsync(words);
                    });
                  },
                  decoration: InputDecoration(
                      hintText: 'Nombre...',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                            borderSide:
                                BorderSide(style: BorderStyle.none, width: 0)),
                      suffixIcon: Icon(Icons.search)),
                ),
              ),
              SizedBox(
                width: kDefaultPadding,
              ),
              IconButton(
                  onPressed: _showFiltersModal,
                  icon: Icon(Icons.tune_outlined)),
              SizedBox(width: kDefaultPadding),
              CircleAvatar(
                child: IconButton(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _categories = [];
                        future = _initAsync();
                      });
                    },
                    icon: Icon(Icons.restore)),
              ),
              SizedBox(width: kDefaultPadding),
              currentUser!.permissions!.contains('ALLOW_ADD_PRODUCT')
                  ? Container(
                      margin: EdgeInsets.only(right: kDefaultPadding),
                      child: CircleAvatar(
                          child: IconButton(
                              tooltip: 'AGREGAR PRODUCTO',
                              onPressed: () {
                                _showModal(
                                    product:
                                        Products());
                              },
                              icon: Icon(Icons.add))),
                    )
                  : SizedBox(),


                 CircleAvatar(
                  child: IconButton(onPressed: (){
                    Navigator.pop(context);
                  }, icon: Icon(Icons.close)),
                ),

                SizedBox(
                  width: kDefaultPadding
                )
            ],
          )
        ],
      ),
      body: FutureBuilder(
          future: future,
          builder: (ctx, s) {
            if (s.connectionState == ConnectionState.waiting) {
              return contentLoading;
            }

            if (s.hasError) {
              return ContentErrorWidget(
                error: s.error.toString(),
                onRetry: () {
                  setState(() {
                    future = _initAsync();
                  });
                },
              );
            }
            if (s.connectionState == ConnectionState.done &&
                products.isNotEmpty) {
              return contentFilled;
            }

            return contentEmpty;
          }),
    );
  }
}
