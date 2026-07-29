import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:uresax_invoice_sys_cloud/modals/provider.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/provider.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/scrollmove.event.widget.dart';

class ProvidersPage extends StatefulWidget {
  bool selectorMode;
  ProvidersPage({super.key, this.selectorMode = false});

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  List<Providers> providers = [];
  Future? future;
  final TextEditingController _searchController = TextEditingController();
  ScrollController scrollControllerY = ScrollController();

  _onSelected(Providers provider) {
    Navigator.pop(context, provider);
  }

  _showProviderEditorModal(BuildContext context,
      {required Providers provider, bool editing = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return ProviderEditorModal(
          provider: provider,
          editing: editing,
        );
      },
    ).then((event) async {
      if (event != null) {
        if (event != null) {
          setState(() {
            future = _initAsync();
          });
        }
      }
    });
  }

  _initAsync([String? words]) async {
    try {
      providers = await Providers.get(search: words);

      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  Widget get contentFilled {
    return ScrollMoveEventWidget(scrollControllerY: scrollControllerY, child:  ListView.separated(
        itemCount: providers.length,
        controller: scrollControllerY,
        separatorBuilder: (ctx, i) => const Divider(),
        itemBuilder: (ctx, index) {
          var provider = providers[index];
          return ListTile(
            key: ValueKey(provider.id),
            minVerticalPadding: kDefaultPadding,
            leading: Container(
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(90),
                color: Theme.of(context).primaryColor.withOpacity(0.04),
              ),
              child: Center(
                child: Icon(
                  Icons.people_alt_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
            ),
            title: Text(provider.name ?? ''),
            onTap: widget.selectorMode
                ? () {
                    _onSelected(provider);
                  }
                : null,
            trailing: Wrap(
              children: [
                widget.selectorMode
                    ? IconButton(
                        onPressed: () {
                          _onSelected(provider);
                        },
                        icon: Icon(Icons.arrow_right_outlined))
                    : SizedBox(),
                IconButton(
                    onPressed: () {
                      _showProviderEditorModal(context,
                          provider: provider, editing: true);
                    },
                    icon: Icon(Icons.edit))
              ],
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
          SvgPicture.asset('assets/svgs/undraw_order-delivered_puaw.svg',
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

  @override
  void initState() {
    setState(() {
      future = _initAsync();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.selectorMode) {
      providers.removeWhere((e) => e.id == null);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('TUS PROVEEDORES (${providers.length})'),
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
                  _showProviderEditorModal(context,
                      provider: Providers(), editing: false);
                },
                icon: Icon(Icons.add),
                tooltip: 'AGREGAR PROVEEDOR',
              )),
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
                providers.isNotEmpty) {
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
