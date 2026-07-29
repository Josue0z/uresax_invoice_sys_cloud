import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:uresax_invoice_sys_cloud/modals/warehouses.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/warehouse.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';

class WareHousesPage extends StatefulWidget {
  bool selectorMode;
  WareHousesPage({super.key, this.selectorMode = false});

  @override
  State<WareHousesPage> createState() => _WareHousesPageState();
}

class _WareHousesPageState extends State<WareHousesPage> {
  List<WareHouses> wareHouses = [];
  final TextEditingController _searchController = TextEditingController();
  Future? future;

  Widget get contentFilled {
    return ListView.separated(
        itemCount: wareHouses.length,
        separatorBuilder: (ctx, i) => const Divider(),
        itemBuilder: (ctx, index) {
          var wareHouse = wareHouses[index];
          return ListTile(
            key: ValueKey(wareHouse.id),
            minVerticalPadding: kDefaultPadding,
            leading: Container(
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(90),
                color: Theme.of(context).primaryColor.withOpacity(0.04),
              ),
              child: Center(
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
            ),
            title: Text(wareHouse.name ?? ''),
            onTap: widget.selectorMode
                ? () {
                    _onSelected(wareHouse);
                  }
                : null,
            trailing: Wrap(
              children: [
                widget.selectorMode
                    ? IconButton(
                        onPressed: () {
                          _onSelected(wareHouse);
                        },
                        icon: Icon(Icons.arrow_right_outlined))
                    : SizedBox(),
                IconButton(
                    onPressed: () {
                      _showWareHousesEditorModal(context,
                          wareHouse: wareHouse, editing: true);
                    },
                    icon: Icon(Icons.edit))
              ],
            ),
          );
        });
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

  _onSelected(WareHouses wareHouse) {
    Navigator.pop(context, wareHouse);
  }

  _showWareHousesEditorModal(BuildContext context,
      {required WareHouses wareHouse, bool editing = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return WareHousesEditorModal(
          wareHouse: wareHouse,
          editing: editing,
        );
      },
    ).then((event) async {
      if (event != null) {
        setState(() {
          future = _initAsync();
        });
      }
    });
  }

  _initAsync([String? words]) async {
    try {
      wareHouses = await WareHouses.get(search: words);

      setState(() {});
    } catch (e) {
      print(e);
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
    wareHouses.removeWhere((e) => e.id == null);
    return Scaffold(
      appBar: AppBar(
        title: Text('ALMACENES (${wareHouses.length})'),
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
                      suffixIcon: Icon(Icons.search)),
                ),
              ),
              SizedBox(width: kDefaultPadding),
              CircleAvatar(
                child: IconButton(
                    onPressed: () {
                      _showWareHousesEditorModal(context,
                          wareHouse: WareHouses(), editing: false);
                    },
                    icon: Icon(Icons.add)),
              ),
              SizedBox(width: kDefaultPadding),
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
                wareHouses.isNotEmpty) {
              return contentFilled;
            }

            return contentEmpty;
          }),
        floatingActionButton: Stack(
      children: [
        Positioned(
          bottom: 20,
          right: kDefaultPadding*2,
          child: FloatingActionButton(onPressed: (){
        setState(() {
          _searchController.clear();
          future = _initAsync();
        });
      },
      child: Icon(Icons.restore)),)
      ],
    )
    );
  }
}
