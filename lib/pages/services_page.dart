import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:uresax_invoice_sys_cloud/modals/filter.services.modal.dart';
import 'package:uresax_invoice_sys_cloud/modals/service.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/categorie.dart';
import 'package:uresax_invoice_sys_cloud/models/service.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/scrollmove.event.widget.dart';

class ServicesPage extends StatefulWidget {
  bool selectedMode;
  ServicesPage({super.key, this.selectedMode = false});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<Services> services = [];
  List<Category> _categories = [];
  Future? future;
  final TextEditingController _searchController = TextEditingController();
  ScrollController scrollControllerY = ScrollController();

  List<int> get xcategories {
    return _categories.map((e) => e.id).toList().cast<int>();
  }

  _showModal({bool editing = false, required Services service}) async {
    var res = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ServiceEditorModal(
              editing: editing,
              service: service,
            ));

    if (res == 'CREATE') {
      setState(() {
        future = _initAsync();
      });
    }

    if (res == 'UPDATE') {
      setState(() {
        future = _initAsync();
      });
    }
  }

  _initAsync([String? words]) async {
    try {
      services = await Services.get(search: words, categories: xcategories);
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
            key: PageStorageKey('services_list'),
            controller: scrollControllerY,
            separatorBuilder: (ctx, i) => const Divider(),
            itemCount: services.length,
            itemBuilder: (ctx, index) {
              var service = services[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey(service.id),
                  onTap: widget.selectedMode
                      ? () {
                          try {
                            Navigator.pop(context, service);
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
                              service.image != null && enabledImageChanges
                                  ? Container(
                                      margin: EdgeInsets.only(
                                        right: kDefaultPadding,
                                      ),
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              service.imageUrl ?? ''),
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
                                      child: Icon(Icons.shopping_bag_outlined,
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
                                    child: Text(service.name ?? ''),
                                  ),
                                  service.code != null
                                      ? Text(service.code ?? '')
                                      : SizedBox(),
                                  Row(
                                    children: [
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
                                          service.categoryName ?? '',
                                          style: TextStyle(
                                              color: secondaryColor,
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
                              Text(service.price?.toCoin() ?? ''),
                              currentUser!.permissions!
                                      .contains('ALLOW_EDIT_SERVICE')
                                  ? IconButton(
                                      onPressed: () {
                                        _showModal(
                                            service: service, editing: true);
                                      },
                                      icon: Icon(Icons.edit,
                                          color: Colors.black38),
                                    )
                                  : SizedBox(),
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
          SvgPicture.asset('assets/svgs/undraw_terms_sx63.svg', width: 250)
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
        builder: (ctx) => FilterServicesModal(categories: _categories));
    if (res is Map) {
      setState(() {
        future = _initAsync();
      });
    }
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
          title: Text('TUS SERVICIOS (${services.length})'),
          toolbarHeight: kToolbarHeight + 50,
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
                        border: OutlineInputBorder(
                            borderSide:
                                BorderSide(style: BorderStyle.none, width: 0)),
                        hintText: 'Nombre...',
                        fillColor: Colors.white,
                        filled: true,
                        suffixIcon: Icon(Icons.search)),
                  ),
                ),
                SizedBox(width: kDefaultPadding),
                IconButton(
                    onPressed: _showFiltersModal,
                    icon: Icon(Icons.tune_outlined)),
                SizedBox(width: kDefaultPadding),
                currentUser!.permissions!.contains('ALLOW_ADD_SERVICE')
                    ? Container(
                        margin: EdgeInsets.only(right: kDefaultPadding),
                        child: CircleAvatar(
                          child: IconButton(
                              tooltip: 'AGREGAR SERVICIO',
                              onPressed: () {
                                _showModal(service: Services());
                              },
                              icon: Icon(Icons.add)),
                        ),
                      )
                    : SizedBox(),
                CircleAvatar(
                  child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close)),
                ),
                SizedBox(width: kDefaultPadding)
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
                  services.isNotEmpty) {
                return contentFilled;
              }

              return contentEmpty;
            }),
        floatingActionButton: Stack(
          children: [
            Positioned(
              bottom: 20,
              right: kDefaultPadding * 2,
              child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _categories = [];
                      future = _initAsync();
                    });
                  },
                  child: Icon(Icons.restore)),
            )
          ],
        ));
  }
}
