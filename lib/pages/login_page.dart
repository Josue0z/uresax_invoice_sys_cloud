import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart' show LogHandler;
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';
import 'package:uresax_invoice_sys_cloud/pages/home_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/pos_screen.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/password.editor.widget.dart';
import 'package:page_route_transition/page_route_transition.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();

  _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        showLoader(context);
     
        currentUser = await User.login(username.text, password.text);
        
        company = currentUser?.company;

        apiUresax.options.headers['x-max-pre-sales'] =
            company?.maxPreSales ?? 99999999;

        /*await CashShiftModel.closeCashShiftTurno(
            id: localStorage.getItem('currentTurnoId') ?? 'x');
        localStorage.removeItem('currentTurnoId');
        localStorage.removeItem('oldPeriodId');*/

        var isValid = await isValidCertFilePath(company: company);

        if (isValid) {
          electronicNcfEnabled = true;
          currentElectronicNcfOption = 1;
        } else {
          electronicNcfEnabled = false;
          currentElectronicNcfOption = 2;
        }

        await LogHandler.printEvent(
            'EL USUARIO: ${currentUser?.name} INICIO SESION');

        if (currentUser != null) {
          if (isTerminal) {
            apiUresax.options.headers['x-terminalid'] = currentTerminalId;
          }

          eCommerceMode = company?.eCommerceMode ?? false;
          enabledBarCodePrinter = company?.enabledBarCodePrinter ?? false;
          enabledVerticalPosInvoice =
              company?.enabledVerticalPosInvoice ?? false;
          enabledEcfProduction = company?.enabledEcfProduction ?? false;
          allowEditInvoice = company?.allowEditInvoice ?? false;
          automaticSendEcf = company?.automaticSendEcf ?? false;
          enabledRetentions = company?.enabledRetentions ?? false;
          enabledRestaurantMode = company?.enabledRestaurantMode ?? false;
          enabledInvoiceSimpleGenerator =
              company?.enabledInvoiceSimpleGenerator ?? false;
          enabledImageChanges = company?.enabledImageChanges ?? false;
          enabledProductQuantityEditor =
              company?.enabledProductQuantityEditor ?? false;
          enabledTextEditor = company?.enabledTextEditor ?? false;
          enabledPosAutomaticSetup = company?.enabledPosAutomaticSetup ?? false;
          enabledTotalsConfigSimple =
              company?.enabledTotalsConfigSimple ?? false;
          enabledProformaUpdateStock =
              company?.enabledProformaUpdateStock ?? false;
          enabledRemoteSigned = company?.enabledRemoteSigned ?? false;
          removeInvoiceTitle = company?.removeInvoiceTitle ?? false;
          enabledOnlySeller = company?.enabledOnlySeller ?? false;

       
          disabledTicket = company?.disabledTicket ?? false;
          enabledEditPriceModal = company?.enabledEditPriceModal ?? false;
          enabledQuotationsSetup = company?.enabledQuotationsSetup ?? false;
          enabledTableInvoiceGenerator =
              company?.enabledTableInvoiceGenerator ?? false;
          enabledRealEstateAgency = company?.enabledRealEstateAgency ?? false;
          enabledItemSimpleConfig = company?.enabledItemSimpleConfig ?? false;
          enabledFullGeneratorTableInvoice =
              company?.enabledFullGeneratorTableInvoice ??
                  true; // este por defecto true
          enabledStepRncTableInvoice =
              company?.enabledStepRncTableInvoice ?? false;
          enabledInvoiceDollars = company?.enabledInvoiceDollars ?? false;
          enabledStore = company?.enabledStore ?? false;
          allowOnlyCashShiftElectronic =
              company?.allowOnlyCashShiftElectronic ?? false;
          enabledViewCashShiftDetails =
              company?.enabledViewCashShiftDetails ?? false;
          enabledFilterInvoicesByDay =
              company?.enabledFilterInvoicesByDay ?? false;
          enabledFirstComercialName =
              company?.enabledFirstComercialName ?? false;
          enabledMultiplyBranches = company?.enabledMultiplyBranches ?? false;
          enabledInvoiceNotes = company?.enabledInvoiceNotes ?? false;
          currentInvoiceIndex = company?.currentInvoiceIndex ?? 0;

          currentUser?.boxId = int.tryParse(localStorage
                  .getItem('URESAX_INVOICE_CURRENT_BOX_ID_${company?.id}') ??
              'x');

          localStorage.setItem('currentUsername', currentUser?.username ?? '');

          if(currentUser?.cashShiftId != null){
              localStorage.setItem('currentTurnoId_$currentInstanceId',currentUser!.cashShiftId!);
          }else{
              localStorage.removeItem('currentTurnoId_$currentInstanceId');
          }

             if(currentUser!.permissions!.contains('ALLOW_ENABLED_ONLY_SELLER')){
            enabledOnlySeller = true;
          }

           await Navigator.pushAndRemoveUntil(
                context,
                PageRouteTransitionBuilder(
                    page: const HomePage(),
                    effect: TransitionEffect.leftToRight),
                (_) => false);
        }
      } catch (e) {
        Navigator.pop(context);
        await LogHandler.printError(e.toString());
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  @override
  void initState() {
    username.text = localStorage.getItem('currentUsername') ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 350,
              child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Container(
                    padding: EdgeInsets.all(kDefaultPadding),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACCEDER',
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                    color: Theme.of(context).primaryColor)),
                        SizedBox(
                          height: kDefaultPadding,
                        ),
                        TextFormField(
                          controller: username,
                          validator: (val) =>
                              val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                          decoration: InputDecoration(
                              labelText: 'USUARIO',
                              hintText: 'Escribir algo...'),
                        ),
                        SizedBox(
                          height: kDefaultPadding,
                        ),
                        PasswordEditorWidget(
                          controller: password,
                          onFieldSubmitted: (_) {
                            _onSubmit();
                          },
                        ),
                        SizedBox(
                          height: kDefaultPadding,
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                              onPressed: _onSubmit, child: Text('INICIAR')),
                        )
                      ],
                    ),
                  )),
            )
          ],
        ),
      ),
    );
  }
}
