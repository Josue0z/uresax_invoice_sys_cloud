import 'package:flutter/material.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/models/ncf.secuencia.dart';
import 'package:uresax_invoice_sys_cloud/models/ncfList.dart';
import 'package:uresax_invoice_sys_cloud/models/ncftype.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class NcfListEditorModal extends StatefulWidget {
  NcfsList? ncfList;
  bool editing;
  NcfListEditorModal({super.key,this.ncfList, this.editing = false});

  @override
  State<NcfListEditorModal> createState() => _NcfListEditorModalState();
}

class _NcfListEditorModalState extends State<NcfListEditorModal> {
  String? currentNcfTypeId;
  String? currentNcfTypeName;
  NcfType? currentNcfType;
  DateTime expirationDate = DateTime.now().endOfYear();
  TextEditingController expirationDateController = TextEditingController();
  TextEditingController lastNumber = TextEditingController();
  TextEditingController start = TextEditingController();
  TextEditingController end = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  NcfSecuencia? secuencia;

  _onSubmit() async {
    if (_formKey.currentState!.validate()) {

      showLoader(context);
      try {
        int? xstart = int.tryParse(start.text);
        int? xend = int.tryParse(end.text);
        int? xlastNumber = int.tryParse(lastNumber.text);
        var ncfList = NcfsList(
            id: widget.ncfList?.id,
            ncfTypeId: currentNcfTypeId,
            ncfTypeName: currentNcfTypeName,
            start: xstart,
            end: xend,
            lastNumber: xlastNumber,
            expirationDate: expirationDate);

  
        if (widget.editing) {
          await ncfList.update();
        } else {
          await ncfList.create();
        }

        await LogHandler.printEvent(
            'LISTA DE NCFS: ${ncfList.ncfTypeName} CREADA');

        await LogHandler.printEvent(
            'SECUENCIA DE NCFS: ${ncfList.ncfTypeName} ACTUALIZADA');
        Navigator.pop(context);
        Navigator.pop(context, widget.editing ? 'UPDATE' : 'CREATE');
      } catch (e) {
         Navigator.pop(context);
        await LogHandler.printError(e.toString());
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  _showDatePicker2() async {
    var result = await showDatePicker(
        context: context,
        initialDate: expirationDate,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 25)));

    if (result != null) {
      expirationDate = result;
      expirationDateController.value =
          TextEditingValue(text: expirationDate.format(payload: 'DD/MM/YYYY'));
    }
  }

  @override
  void initState() {
    if(!mounted)return;
    if (widget.editing && widget.ncfList != null) {
      currentNcfTypeId = widget.ncfList?.ncfTypeId;
      start.text = widget.ncfList!.start.toString();
      end.text = widget.ncfList!.end.toString();
      lastNumber.text = widget.ncfList!.lastNumber.toString();

      expirationDate = widget.ncfList?.expirationDate ?? DateTime.now().endOfYear();
      expirationDateController.value =
          TextEditingValue(text: expirationDate.format(payload: 'DD/MM/YYYY'));
        setState(() {
          
        });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Form(
      key: _formKey,
      child: SizedBox(
        width: 450,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(kDefaultPadding),
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(
                 widget.editing ? 'EDITANDO LISTA DE NCF' : 'AGREGANDO LISTA DE NCF',
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(color: Theme.of(context).primaryColor),
                )),
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
            DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: currentNcfTypeId,
                validator: (val) => val == null ? 'CAMPO OBLIGATORIO' : null,
                items: List.generate(ncfs.length, (index) {
                  var ncf = ncfs[index];
                  return DropdownMenuItem(
                      value: ncf.id, child: Text(ncf.name ?? ''));
                }),
                onChanged: widget.editing ? null : (id) async {
                  currentNcfTypeId = id;
                  currentNcfType = ncfs.firstWhere((e) => e.id == id);
                  currentNcfTypeName = currentNcfType?.name;
                  setState(() {});
                }),
            SizedBox(
              height: kDefaultPadding,
            ),
            Row(
              children: [
                Expanded(
                    child: TextFormField(
                  controller: start,
                  maxLength:
                      currentNcfType != null ? currentNcfType?.maxLimit : 8,
                  validator: (val) => val!.isEmpty
                      ? 'CAMPO OBLIGATORIO'
                      : int.parse(val) < 1
                          ? 'NO PUEDE SER MENOR QUE 1'
                          : null,
                  onChanged: (val){
                
                     lastNumber.text = start.text;
                    
                  },
                  decoration:
                      InputDecoration(labelText: 'INICIAL', hintText: '1'),
                )),
                SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Expanded(
                    child: TextFormField(
                  controller: end,
                  maxLength:
                      currentNcfType != null ? currentNcfType?.maxLimit : 8,
                  validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                  decoration: InputDecoration(
                      labelText: 'FINAL',
                      hintText: List.generate(
                          currentNcfType?.maxLimit ?? 8, (i) => '9').join('')),
                )),
              ],
            ),
            SizedBox(
              height: kDefaultPadding,
            ),
            TextFormField(
              controller:  lastNumber,
                  maxLength:
                      currentNcfType != null ? currentNcfType?.maxLimit : 8,
                  validator: (val) => val!.isEmpty
                      ? 'CAMPO OBLIGATORIO'
                      : int.parse(val) < 1
                          ? 'NO PUEDE SER MENOR QUE 1'
                          : null,
              decoration: InputDecoration(
                  labelText: 'SECUENCIA ACTUAL', hintText: '0000000000'),
            ),
            SizedBox(
              height: kDefaultPadding,
            ),
            TextFormField(
              controller: expirationDateController,
              readOnly: true,
              style: Theme.of(context).textTheme.bodyMedium,
              validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
              decoration: InputDecoration(
                  labelText: 'FECHA DE VENCIMIENTO',
                  hintText: 'DD/MM/YYYY',
                  suffixIcon: IconButton(
                      onPressed: _showDatePicker2,
                      icon: Icon(Icons.calendar_month))),
            ),
            SizedBox(
              height: kDefaultPadding,
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child:
                  ElevatedButton(onPressed: _onSubmit, child: Text(widget.editing ? 'EDITAR': 'AGREGAR')),
            )
          ],
        ),
      ),
    ));
  }
}
