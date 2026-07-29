import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:uresax_invoice_sys_cloud/modals/discount.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/discount.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/scrollmove.event.widget.dart';

class DiscountsPage extends StatefulWidget {
  bool selectorMode;
  DiscountsPage({super.key, this.selectorMode = false});

  @override
  State<DiscountsPage> createState() => _DiscountsPageState();
}

class _DiscountsPageState extends State<DiscountsPage> {
  List<Discount> discounts = [];
  Future? future;

  ScrollController scrollControllerY = ScrollController();


  _showModal({bool editing = false, required Discount discount}) async {
    var res = await showDialog(
        context: context,
        builder: (ctx) =>
            DiscountEditorModal(editing: editing, discount: discount));

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

  _onSelected(Discount discount) {
    Navigator.pop(context, discount);
  }

  Widget get contentFilled {
    return ScrollMoveEventWidget(
        scrollControllerY: scrollControllerY,
 
        child: ListView.separated(
           controller: scrollControllerY,
            itemBuilder: (ctx, index) {
              var discount = discounts[index];
              return ListTile(
                onTap: widget.selectorMode
                    ? () {
                        _onSelected(discount);
                      }
                    : null,
                title: Text(discount.name ?? ''),
                trailing: Wrap(
                  children: [
                    widget.selectorMode
                        ? IconButton(
                            onPressed: () {
                              _onSelected(discount);
                            },
                            icon: Icon(Icons.arrow_right))
                        : SizedBox(),
                    IconButton(
                        onPressed: () {
                          _showModal(discount: discount, editing: true);
                        },
                        icon: Icon(Icons.edit))
                  ],
                ),
              );
            },
            separatorBuilder: (ctx, i) => const Divider(),
            itemCount: discounts.length));
  }

  Widget get contentEmpty {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/svgs/undraw_statistic-chart_6s7z.svg',
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

  _initAsync([String? words]) async {
    discounts = [
      Discount(
        name: 'DESCUENTO',
      ),
      ...await Discount.get()
    ];
    setState(() {});
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
        title: Text('DESCUENTOS (${discounts.length})'),
        actions: [
          Wrap(
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CircleAvatar(
                child: IconButton(
                  tooltip: 'AGREGAR DESCUENTO',
                  onPressed: () {
                    _showModal(discount: Discount());
                  },
                  icon: Icon(Icons.add),
                ),
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
                discounts.isNotEmpty) {
              return contentFilled;
            }

            return contentEmpty;
          }),
    );
  }
}
