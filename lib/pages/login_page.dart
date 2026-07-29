import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart' show LogHandler;
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';
import 'package:uresax_invoice_sys_cloud/pages/home_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/plans_page.dart';
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
        company= currentUser?.company;
        apiUresax.options.headers['x-max-pre-sales'] = company?.maxPreSales ?? 99999999;
   
        await isValidCertFilePath();
      
        await LogHandler.printEvent(
            'EL USUARIO: ${currentUser?.name} INICIO SESION');

        if (currentUser != null) {
          /*if(!notExistsSubscriptionsTable){
            if(!subscriptionActive){

           
              if(subscriptionPause){
                throw 'LA SUBSCRIPCION ESTA PAUSADA';
              }
              Navigator.pop(context);

              await showDialog(context: context, builder: (ctx) => PlansPage());
              if(!subscriptionActive){
                return;
              }
            }
          }*/
           
          if (currentUser!.permissions!.contains('ALLOW_VIEW_POS_SCREEN')) {

         
            if (!eCommerceMode) {
              throw 'NO ESTA HABILITADO EL MODO COMERCIO';
            }


            await Navigator.pushAndRemoveUntil(
                context,
                PageRouteTransitionBuilder(
                    page: PosScreenPage(
                      sale: SaleProduct(),
                      items: [],
                    ),
                    effect: TransitionEffect.leftToRight),
                (_) => false);
         
          } else {
            await Navigator.pushAndRemoveUntil(
                context,
                PageRouteTransitionBuilder(
                    page: const HomePage(),
                    effect: TransitionEffect.leftToRight),
                (_) => false);
          }
        }
      } catch (e) {
        Navigator.pop(context);
        await LogHandler.printError(e.toString());
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
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
