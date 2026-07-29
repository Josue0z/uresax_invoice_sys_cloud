import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:uresax_invoice_sys_cloud/modals/drivers.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/drivers.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';

class DriversPage extends StatefulWidget {
  bool selectedMode;

  DriversPage({super.key, this.selectedMode = false});

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  Future? future;
  _initAsync() async {
    try {
      drivers = await Drivers.get();
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  @override
  initState() {
   setState(() {
     future =   _initAsync();
   });
    super.initState();
  }

  List<Drivers> drivers = [];
  _onSelected(Drivers? driver) {
    Navigator.pop(context, driver);
  }

    Widget get contentEmpty {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/svgs/undraw_male-avatar_zkzx.svg', width: 220)
        ],
      ),
    );
  }

  Widget get contentLoading {
    return Center(
      child: CircularProgressIndicator(),
    );
  }


  Widget get contentFilled {
    return ListView.separated(
          itemBuilder: (ctx, index) {
            var driver = drivers[index];
            return ListTile(
              title: Text(driver.name ?? ''),
              onTap: !widget.selectedMode
                  ? null
                  : () {
                      _onSelected(driver);
                    },
              trailing: Wrap(
                children: [
                  IconButton(
                      onPressed: () {
                        _onSelected(driver);
                      },
                      icon: Icon(Icons.arrow_right)),
                  IconButton(
                      onPressed: () async {
                        var res = await showDialog(
                            context: context,
                            builder: (ctx) => DriversEditorModal(
                                  driver: driver,
                                  editing: true,
                                ));
                        if (res != null) {
                          drivers = await Drivers.get();
                          setState(() {});
                        }
                      },
                      icon: Icon(Icons.edit))
                ],
              ),
            );
          },
          separatorBuilder: (ctx, i) => const Divider(),
          itemCount: drivers.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CONDUCTORES (${drivers.length})'),
        actions: [
          Wrap(
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 50,
                child: TextFormField(
                  onChanged: (words) async {
                    drivers = await Drivers.get(search: words);
                    setState(() {});
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
                tooltip: 'AGREGAR CONDUCTOR',
                onPressed: () async {
                  var res = await showDialog(
                      context: context,
                      builder: (ctx) => DriversEditorModal(driver: Drivers()));
                  if (res != null) {
                    drivers = await Drivers.get();
                    setState(() {});
                  }
                },
                icon: Icon(Icons.add),
              )),
              SizedBox(width: kDefaultPadding),
            ],
          )
        ],
      ),
      body:  FutureBuilder(
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
                drivers.isNotEmpty) {
              return contentFilled;
            }

            return contentEmpty;
          }),
    );
  }
}
