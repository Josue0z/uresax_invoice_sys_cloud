import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/models/dgiiStates.dart';
import 'package:uresax_invoice_sys_cloud/models/ncftype.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:multiselect/multiselect.dart';

class FilterSalesModal extends StatefulWidget {
  String? ncfTypeId;
  List<NcfType> ncfsTypes;
  SaleStatus? saleStatus;
  int? dgiiState;
  List<DgiiState> dgiiStates;
  FilterSalesModal(
      {super.key,
      required this.saleStatus,
      required this.ncfTypeId,
      required this.ncfsTypes,
      required this.dgiiState,
      required this.dgiiStates});

  @override
  State<FilterSalesModal> createState() => _FilterSalesModalState();
}

class _FilterSalesModalState extends State<FilterSalesModal> {

  List<Map<String, dynamic>> options = [
    {'id': SaleStatus.all, 'name': 'TODAS'},
    {'id': SaleStatus.paid, 'name': 'PAGADA'},
    {'id': SaleStatus.notPaid, 'name': 'PENDIENTE'}
  ];

  _onSaved() async {
    Navigator.pop(context, {
      'ncfTypeId': widget.ncfTypeId,
      'ncfsTypes': widget.ncfsTypes,
      'saleStatus': widget.saleStatus,
      'dgiiState': widget.dgiiState,
      'dgiiStates': widget.dgiiStates
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Form(
          child: SizedBox(
        width: 400,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(kDefaultPadding),
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('Filtros',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(color: Theme.of(context).primaryColor))),
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close))
              ],
            ),
            SizedBox(
              height: kDefaultPadding,
            ),
            DropDownMultiSelect(
              options: ncfs,
              selectedValues: widget.ncfsTypes,
              isDense: true,
              whenEmpty: 'TIPO DE COMPROBANTE',
              decoration: InputDecoration(
                  labelText: 'TIPO DE COMPROBANTE',
                  hintText: 'SELECCIONAR',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20))),
              menuItembuilder: (ncf) {
                return ListTile(
                  title: Text(ncf.name ?? ''),
                  selected: widget.ncfsTypes.contains(ncf),
                  onTap: () {
                    setState(() {
                      if (ncf.id != null) {
                        if (widget.ncfsTypes.contains(ncf)) {
                          widget.ncfsTypes.remove(ncf);
                        } else {
                          widget.ncfsTypes.add(ncf);
                        }
                   
                      }else{
                        widget.ncfsTypes = [];
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              },
              childBuilder: (ncfs) {
                return Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: kDefaultPadding, horizontal: kDefaultPadding),
                    child: Text(
                      ncfs.map((e) => e.id).join('-'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ));
              },
              onChanged: (ncfs) {},
            ),

            SizedBox(height: kDefaultPadding),
            DropdownButtonFormField<SaleStatus>(
                initialValue: widget.saleStatus,
                isExpanded: true,
                decoration: InputDecoration(labelText: 'ESTADO'),
                items: options
                    .map((e) => DropdownMenuItem(
                        value: e['id'] as SaleStatus,
                        child: Text(e['name'] ?? '')))
                    .toList(),
                onChanged: (option) {
                  widget.saleStatus = option;
                }),
            SizedBox(height: kDefaultPadding),
        
             DropDownMultiSelect(
              options: dgiiStates,
              selectedValues: widget.dgiiStates,
              isDense: true,
              whenEmpty: 'ESTADO DGII',
              decoration: InputDecoration(
                  labelText: 'ESTADO DGII',
                  hintText: 'SELECCIONAR',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20))),
              menuItembuilder: (dgiiState) {
                return ListTile(
                  title: Text(dgiiState.name ?? ''),
                  selected: widget.dgiiStates.contains(dgiiState),
                  onTap: () {
                    setState(() {
                      if (dgiiState.id != null) {
                        if (widget.dgiiStates.contains(dgiiState)) {
                          widget.dgiiStates.remove(dgiiState);
                        } else {
                          widget.dgiiStates.add(dgiiState);
                        }
                   
                      }else{
                        widget.dgiiStates = [];
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              },
              childBuilder: (dgiiStates) {
                return Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: kDefaultPadding, horizontal: kDefaultPadding),
                    child: Text(
                      dgiiStates.map((e) => e.id).join('-'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ));
              },
              onChanged: (ncfs) {},
            ),

            SizedBox(height: kDefaultPadding),
            SizedBox(
              width: double.infinity,
              height: 50,
              child:
                  ElevatedButton(onPressed: _onSaved, child: Text('APLICAR')),
            )
          ],
        ),
      )),
    );
  }
}
