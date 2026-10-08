import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:localstorage/localstorage.dart';
import 'package:timezone/timezone.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/pages/printers_page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class CompanyEditorModal extends StatefulWidget {
  const CompanyEditorModal({super.key});

  @override
  State<CompanyEditorModal> createState() => _CompanyEditorModalState();
}

class _CompanyEditorModalState extends State<CompanyEditorModal> {
  TextEditingController name = TextEditingController();
  TextEditingController comercialName = TextEditingController();
  TextEditingController identification = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController phone2 = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController address = TextEditingController();
  TextEditingController devicePosName = TextEditingController();
  TextEditingController devicePosBarCodesName = TextEditingController();
  TextEditingController message = TextEditingController();
  TextEditingController bankInfo = TextEditingController();
  TextEditingController maxPreSales = TextEditingController();
  TextEditingController instagramLink = TextEditingController();
  String? logo;

  _onSubmit() async {
    showLoader(context);
    try {
      company?.name = name.text.trim();
      company?.rncOrId = identification.text.trim();
      company?.phone1 = phone.text.isEmpty ? null : phone.text.trim();
      company?.phone2 = phone2.text.isEmpty ? null : phone2.text.trim();
      company?.email = email.text.isEmpty ? null : email.text.trim();
      company?.address = address.text.isEmpty ? null : address.text;
      company?.message = message.text.isEmpty ? null : message.text;
      company?.bankInfo = bankInfo.text.isEmpty ? null : bankInfo.text;
      company?.maxPreSales = int.tryParse(maxPreSales.text) ?? 99999999;
      company?.instagramLink =
          instagramLink.text.isEmpty ? null : instagramLink.text.trim();
      company = await company?.update();

      await LogHandler.printEvent(
          'LOS DATOS DE ${company?.name} FUERON ACTUALIZADOS');
      Navigator.pop(context);
      Navigator.pop(context, 'UPDATE');
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  @override
  void initState() {
    name.value = TextEditingValue(text: company?.name ?? '');
    comercialName.text = company?.comercialName ?? '';
    identification.value = TextEditingValue(text: company?.rncOrId ?? '');
    phone.value = TextEditingValue(text: company?.phone1 ?? '');
    phone2.value = TextEditingValue(text: company?.phone2 ?? '');
    email.value = TextEditingValue(text: company?.email ?? '');
    address.value = TextEditingValue(text: company?.address ?? '');
    devicePosName.text = devicePos ?? '';
    devicePosBarCodesName.text = devicePosBarcodes ?? '';
    logo = company?.logo;
    message.text = company?.message ?? '';
    bankInfo.text = company?.bankInfo ?? '';
    maxPreSales.text = company!.maxPreSales!.toString();
    instagramLink.text = company?.instagramLink ?? '';
    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Form(
          child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
              width: 400,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text('EDITANDO EMPRESA...',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                      color: Theme.of(context).primaryColor))),
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close))
                    ],
                  ),
                  Expanded(
                      child: ListView(
                    shrinkWrap: true,
                    children: [
                      SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                      ImagePickerWidget(logo: logo),
                      SizedBox(
                        height: kDefaultPadding,
                      ),
                      TextFormField(
                        controller: name,
                        readOnly: true,
                        decoration: InputDecoration(
                            labelText: 'RAZON SOCIAL',
                            hintText: 'Escribir algo...'),
                      ),
                      SizedBox(height: kDefaultPadding),
                      TextFormField(
                        controller: comercialName,
                        readOnly: true,
                        decoration: InputDecoration(
                            labelText: 'NOMBRE COMERCIAL',
                            hintText: 'Escribir algo...'),
                      ),
                      SizedBox(height: kDefaultPadding),
                      TextFormField(
                        controller: identification,
                        readOnly: true,
                        decoration: InputDecoration(
                            labelText: 'RNC/CEDULA',
                            hintText: 'Escribir algo...'),
                      ),
                      SizedBox(height: kDefaultPadding),
                      TextFormField(
                        controller: phone,
                        decoration: InputDecoration(
                            labelText: 'TELEFONO 1', hintText: '809 000 0000'),
                      ),
                      SizedBox(height: kDefaultPadding),
                      TextFormField(
                        controller: phone2,
                        decoration: InputDecoration(
                            labelText: 'TELEFONO 2', hintText: '809 000 0000'),
                      ),
                      SizedBox(height: kDefaultPadding),
                      TextFormField(
                        controller: email,
                        decoration: InputDecoration(
                            labelText: 'CORREO',
                            hintText: 'correo@example.com'),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: kDefaultPadding),
                        child: TextFormField(
                          controller: instagramLink,
                          decoration: InputDecoration(
                              labelText: 'ENLACE DE INSTAGRAM',
                              hintText: 'https://instagram.com'),
                        ),
                      ),
                      currentUser?.roleId != 1
                          ? Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: kDefaultPadding),
                              child: TextFormField(
                                controller: maxPreSales,
                                decoration: InputDecoration(
                                    labelText: 'MAXIMO DE FACTURAS PRE VENTAS',
                                    hintText: '1 - 99999999'),
                              ),
                            )
                          : SizedBox(),
                      TextFormField(
                        controller: bankInfo,
                        keyboardType: TextInputType.multiline,
                        maxLines: 3,
                        decoration: InputDecoration(
                            labelText: 'INFORMACION BANCARIA',
                            hintText: 'Escribir algo...'),
                      ),
                      SizedBox(height: kDefaultPadding),
                      TextFormField(
                        controller: message,
                        keyboardType: TextInputType.multiline,
                        maxLines: 3,
                        decoration: InputDecoration(
                            labelText: 'MENSAJE', hintText: 'Escribir algo...'),
                      ),
                      SizedBox(height: kDefaultPadding),
                      TextFormField(
                        controller: devicePosName,
                        decoration: InputDecoration(
                            labelText: 'IMPRESORA TERMICA DE RECIBOS',
                            hintText: 'Nombre...',
                            suffixIcon: Wrap(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    var printerName = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (ctx) => PrintersPage()));
                                    if (printerName != null) {
                                      devicePosName.text = printerName;
                                      devicePos = printerName;
                                      localStorage.setItem(
                                          'devicePos', printerName);
                                      setState(() {});
                                    }
                                  },
                                  icon: Icon(Icons.print_rounded),
                                )
                              ],
                            )),
                      ),
                      SizedBox(height: kDefaultPadding),
                      TextFormField(
                        controller: devicePosBarCodesName,
                        decoration: InputDecoration(
                            labelText: 'IMPRESORA TERMICA DE CODIGOS DE BARRA',
                            hintText: 'Nombre...',
                            suffixIcon: Wrap(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    var printerName = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (ctx) => PrintersPage()));
                                    if (printerName != null) {
                                      devicePosBarCodesName.text = printerName;
                                      devicePosBarcodes = printerName;
                                      localStorage.setItem(
                                          'devicePosBarcodes', printerName);
                                      setState(() {});
                                    }
                                  },
                                  icon: Icon(Icons.print_rounded),
                                )
                              ],
                            )),
                      ),
                      SizedBox(height: kDefaultPadding),
                      TextFormField(
                        controller: address,
                        maxLines: 6,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                            labelText: 'DIRECCION',
                            hintText: 'Escribir algo...'),
                      ),
                      SizedBox(height: kDefaultPadding),

                    currentUser!.permissions!.contains('ALLOW_CHANGE_BOX_ID') ?  Container(
                              margin: EdgeInsets.only(bottom: kDefaultPadding),
                              child: DropdownButtonFormField(
                                  initialValue: int.tryParse(localStorage.getItem(
                                          'URESAX_INVOICE_CURRENT_BOX_ID_${company?.id}') ??
                                      'x'),
                                  decoration:
                                      InputDecoration(labelText: 'CAJA'),
                                  isExpanded: true,
                                  items: List.generate(boxes.length, (i) {
                                    var box = boxes[i];
                                    return DropdownMenuItem(
                                        value: box.id,
                                        child: Text(box.name ?? ''));
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                     localStorage.setItem('URESAX_INVOICE_CURRENT_BOX_ID_${company?.id}', val.toString());
                                     currentUser?.boxId = val;
                                    }
                                  }),
                            ):SizedBox(),
                      enabledMultiplyBranches &&
                              currentUser!.permissions!
                                  .contains('ALLOW_CHANGE_BRANCHE') && currentUser?.roleId == 3
                          ? Container(
                              margin: EdgeInsets.only(bottom: kDefaultPadding),
                              child: DropdownButtonFormField(
                                  initialValue: int.tryParse(localStorage.getItem(
                                          'URESAX_INVOICE_BRANCHE_ID_${company?.id}') ??
                                      'x'),
                                  decoration:
                                      InputDecoration(labelText: 'SUCURSAL'),
                                  isExpanded: true,
                                  items: List.generate(branches.length, (i) {
                                    var branch = branches[i];
                                    return DropdownMenuItem(
                                        value: branch.id,
                                        child: Text(branch.name ?? ''));
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      var b = branches
                                          .firstWhere((x) => x.id == val);
                                      localStorage.setItem(
                                          'URESAX_INVOICE_BRANCHE_ID_${company?.id}',
                                          val.toString());
                                      localStorage.setItem(
                                          'URESAX_INVOICE_BRANCHE_NAME_${company?.id}',
                                          b.name ?? '');
                                      localStorage.setItem(
                                          'URESAX_INVOICE_BRANCHE_PHONE1_${company?.id}',
                                          b.phone1 ?? '');
                                      localStorage.setItem(
                                          'URESAX_INVOICE_BRANCHE_PHONE2_${company?.id}',
                                          b.phone2 ?? '');
                                      localStorage.setItem(
                                          'URESAX_INVOICE_BRANCHE_ADDRESS_${company?.id}',
                                          b.address ?? '');
                                      localStorage.setItem(
                                          'URESAX_INVOICE_BRANCHE_EMAIL_${company?.id}',
                                          b.email ?? '');
                                      address.text = b.address ?? '';
                                      phone.text = b.phone1 ?? '';
                                      phone2.text = b.phone2 ?? '';
                                      email.text = b.email ?? '';
                                      comercialName.text = b.name ?? '';
                                    }
                                  }),
                            )
                          : SizedBox(),
                    ],
                  )),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                        onPressed: _onSubmit, child: Text('EDITAR DATOS')),
                  )
                ],
              ))),
    );
  }
}

class ImagePickerWidget extends StatefulWidget {
  String? logo;
  ImagePickerWidget({super.key, this.logo});

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? file;

  _onOpenPicker() async {
    final ImagePicker picker = ImagePicker();
    var res = await picker.pickImage(source: ImageSource.gallery);
    if (res != null) {
      file = File(res.path);
      var bytes = await file?.readAsBytes();
      widget.logo = base64Encode(bytes!);
      company?.logo = widget.logo;
      await company?.update();
      setState(() {});
    }
  }

  _removeImagen() async {
    file = null;
    widget.logo = null;
    company?.logo = widget.logo;
    await company?.update();
    setState(() {});
  }

  Widget get contentFilled {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12)),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.memory(base64Decode(widget.logo ?? ''), width: 180),
            SizedBox(height: kDefaultPadding),
            TextButton(onPressed: _removeImagen, child: Text('Eliminar Imagen'))
          ],
        ),
      ),
    );
  }

  Widget get contentDefault {
    return GestureDetector(
      onTap: _onOpenPicker,
      child: Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black12)),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 90, color: Colors.black12),
              SizedBox(height: kDefaultPadding),
              Text('Cargar Imagen')
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.logo != null) {
      return contentFilled;
    } else {
      return contentDefault;
    }
  }
}
