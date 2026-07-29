import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:path/path.dart' as path;
import 'package:uresax_invoice_sys_cloud/widgets/password.editor.widget.dart';

class ElectronicNcfSettingsModal extends StatefulWidget {
  const ElectronicNcfSettingsModal({super.key});

  @override
  State<ElectronicNcfSettingsModal> createState() =>
      _ElectronicNcfSettingsModalState();
}

class _ElectronicNcfSettingsModalState
    extends State<ElectronicNcfSettingsModal> {
  List<Map<String, dynamic>> options = [
    {'id': null, 'name': 'ESTADO'},
    {'id': 1, 'name': 'ACTIVADO'},
    {'id': 2, 'name': 'DESACTIVADO'}
  ];

  List<Map<String,dynamic>> statesDgii = [
    {
      'id': null,
      'name':"ESTADO"
    },
    {
      'id':false,
      'name':'DESARROLLO'
    },
    {
      'id':true,
      'name':'PRODUCCION'
    }
  ];

  bool isValid = false;

  _onSelectPath() async {
    var res = await FilePicker.platform.pickFiles();
    if (res != null) {
      var file = res.files.single;
      var xfile = File(file.path!);
      var ext = path.extension(file.path!);
      var dir = await getUresaxInvoiceDir();
    

      certFile = File(path.join(dir.path, 'certs', 'cert_${company?.id}$ext'));
      await certFile?.create(recursive: true);
      await certFile?.writeAsBytes(await xfile.readAsBytes());
      certPath.value = TextEditingValue(text: certFile?.path ?? '');
      localStorage.setItem('certFilePath_${company?.id}', certFile?.path ?? '');
    }
  }

  _onSubmit() async {
    showLoader(context);
    try {
      var isValid = await isValidCertFilePath();

      if (isValid) {
        showTopSnackBar(context,
            message: 'CERTIFICADO CARGADO!', color: Colors.green);
        Navigator.pop(context);

        setState(() {});
        
      } else {
        throw 'No valido';
      }
    } catch (e) {
     Navigator.pop(context);
      await LogHandler.printError(e.toString());
      setState(() {});


      showTopSnackBar(context,
          message: 'CERTIFICADO NO CARGADO', color: Colors.red);
    } finally {
      localStorage.setItem('certPassword_${company?.id}', certPassword.text);
    }
  }

  _initAsync() async {
    var filePath = localStorage.getItem('certFilePath_${company?.id}');
    var password = localStorage.getItem('certPassword_${company?.id}');
    certFile = File(filePath ?? '');
    certPath.value = TextEditingValue(text: filePath ?? '');
    certPassword.value = TextEditingValue(text: password ?? '');

    await isValidCertFilePath();

    setState(() {});
  }

  @override
  void initState() {
    if(!mounted)return;
     _initAsync();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Form(
          child: SizedBox(
              width: 450,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.all(kDefaultPadding),
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text('CONFIGURACION ELECTRONICA...',
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: kDefaultPadding),
                      TextFormField(
                        controller: certPath,
                        decoration: InputDecoration(
                            labelText: 'RUTA DE ARCHIVO DE CERTIFICADO PFX',
                            hintText: 'Ruta...',
                            suffixIcon: IconButton(
                                onPressed: () {
                                  _onSelectPath();
                                },
                                icon: Icon(Icons.folder))),
                      ),
                      SizedBox(height: kDefaultPadding),
    
                      PasswordEditorWidget(
                      controller: certPassword,
                      labelText: 'CLAVE DE CERTIFICADO', 
                      hintText: 'Escribir algo...'),
                      
                      SizedBox(height: kDefaultPadding),
                      DropdownButtonFormField<int>(
                          initialValue: currentElectronicNcfOption,
                          decoration: InputDecoration(labelText: 'FACTURACION'),
                          items: List.generate(options.length, (i) {
                            var option = options[i];
                            return DropdownMenuItem(
                                value: option['id'],
                                child: Text(option['name']));
                          }),
                          onChanged: null),
                          SizedBox(height: kDefaultPadding),
                          DropdownButtonFormField<bool?>(
                          initialValue: enabledEcfProduction,
                          decoration: InputDecoration(labelText: 'ESTADO DGII'),
                          items: List.generate(options.length, (i) {
                            var option = statesDgii[i];
                            return DropdownMenuItem(
                                value: option['id'],
                                child: Text(option['name']));
                          }),
                          onChanged: null),
                    ],
                  ),
                  SizedBox(height: kDefaultPadding),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                        onPressed: _onSubmit,
                        child: Text('VALIDAR CERTIFICADO')),
                  )
                ],
              ))),
    );
  }
}
