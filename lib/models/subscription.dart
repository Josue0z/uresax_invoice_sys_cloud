import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:paypal_sdk/core.dart';
import 'package:paypal_sdk/subscriptions.dart';
import 'package:postgres/postgres.dart';
import 'package:uresax_invoice_sys_cloud/apis/sql.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/pages/home_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/pos_screen.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uuid/uuid.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:path/path.dart' as path;

var returnUrl = 'https://api.uresax.com/paypal/return';
var cancelUrl = 'https://api.uresax.com/paypal/cancel';

class SubscriptionModel {
  static String? id;
  static String? subscriptionId;
  static String? planId;
  static late PayPalEnvironment paypalEnvironment;
  static String clientId = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
  static String clientSecret = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXX';
  static String productId = 'XXXXXXXXXXXXXXXXXXX';

  DateTime? createdAt;

  SubscriptionModel._();

  static Future<void> init() async {

  
      if (kDebugMode) {
        // Configura el entorno de PayPal (sandbox o live)
        paypalEnvironment = PayPalEnvironment.sandbox(
            clientId: clientId, clientSecret: clientSecret);
      } else {
        // Configura el entorno de PayPal (sandbox o live)
        paypalEnvironment = PayPalEnvironment.live(
            clientId: clientId, clientSecret: clientSecret);
      }
    
  }

  static Future<bool> checkIfExistSubscriptionsTable() async {
    try {
      final conne = SqlConector.connection;

      // Verificar si la tabla existe en el esquema public
      var checkTable = await conne?.execute(Sql.named('''SELECT EXISTS (
           SELECT 1
           FROM information_schema.tables 
           WHERE table_schema = 'public' 
           AND table_name = 'Subscriptions'
         ) AS exists_table'''));

      if (checkTable?.isNotEmpty == true) {
        return checkTable?.first.toColumnMap()['exists_table'] as bool;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> findSubscription() async {
    try {
      final conne = SqlConector.connection;

      var exists = await checkIfExistSubscriptionsTable();

      if (exists == true) {
        notExistsSubscriptionsTable = false;
        // La tabla existe, ahora consultamos
        var res = await conne?.execute(Sql.named(
            'SELECT * FROM public."Subscriptions" WHERE active = true LIMIT 1'));
        if (res?.isNotEmpty == true) {
          var data = res?.first.toColumnMap();
          subscriptionActive=true;
          subscriptionCancel=false;
          subscriptionPause=false;
          return data;
        }
      } else {
        notExistsSubscriptionsTable = true;
      }

      // Si la tabla no existe o no hay registros
      return null;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateSubscriptionsStatus() async {
    try {
      final conne = SqlConector.connection;

      await conne?.execute(
          Sql.named(
              'UPDATE public."Subscriptions" SET active = @active WHERE "subscriptionId" = @subscriptionId'),
          parameters: {
            'active': subscriptionActive,
            'subscriptionId': subscriptionId
          });
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> checkIfExistSubscriptionIsActive() async {
    try {
  
      var payPalHttpClient = PayPalHttpClient(
        paypalEnvironment,
        accessTokenUpdatedCallback: (accessToken) async {
          // Aquí puedes guardar el token para reusarlo
        },
      );

      var subscriptionsApi = SubscriptionsApi(payPalHttpClient);
      var subscriptionRequest = SubscriptionRequest(
          planId: planId!,
          customId: subscriptionId,
          applicationContext: ApplicationContext(
              returnUrl: returnUrl,
              cancelUrl: cancelUrl,
              userAction: UserAction.subscribedNow,
              paymentMethod: PaymentMethod(
                  payeePreferred: PayeePreferred.immediatePaymentRequired)));
      await subscriptionsApi.createSubscription(subscriptionRequest);

      var details =
          await subscriptionsApi.showSubscriptionDetails(subscriptionId!);
      if (details.status == SubscriptionStatus.active) {
        subscriptionActive = true;
        subscriptionCancel=false;
        return true;
      } else if(details.status == SubscriptionStatus.cancelled){
        subscriptionActive = false;
        subscriptionPause=false;
        subscriptionCancel = true;
        return false;
      }else if(details.status == SubscriptionStatus.suspended){
         subscriptionActive=false;
         subscriptionCancel=false;
         subscriptionPause=true;
         return false;
      } 
       else{
         subscriptionActive = false;
         return false;
      }
    } catch (e) {
      subscriptionActive = false;
      rethrow;
    }
  }

  static Future<void> create() async {
    try {
      paypalEnvironment;
      final conne = SqlConector.connection;
      await conne?.execute(Sql.named('DELETE FROM public."Subscriptions"'));
      await conne?.execute(
          Sql.named(
              'insert into public."Subscriptions"(id,"subscriptionId","planId",active) values(@id,@subscriptionId,@planId,@active)'),
          parameters: {
            'id': id,
            'subscriptionId': subscriptionId,
            'planId': planId,
            'active': true
          });
    } catch (e) {
      rethrow;
    }
  }

  static Future<PlanCollection> listPlan() async {
    var payPalHttpClient = PayPalHttpClient(
      paypalEnvironment,
      accessTokenUpdatedCallback: (accessToken) async {
        // Aquí puedes guardar el token para reusarlo
      },
    );

    var subscriptionsApi = SubscriptionsApi(payPalHttpClient);

    // Listar planes asociados a tu producto
    var plansResponse = await subscriptionsApi.listPlans(
      productId: productId, // Tu producto uresax_invoice_sys_cloud
      pageSize: 10, // cantidad de resultados por página
      page: 1, // página inicial
    );
    return plansResponse;
  }

  static Future<void> createSubscription(
      {required BuildContext context, required String xplanId}) async {
        showLoader(context);
    await init();
    var payPalHttpClient = PayPalHttpClient(paypalEnvironment);
    var subscriptionsApi = SubscriptionsApi(payPalHttpClient);

    // Crear la suscripción basada en tu plan
    id = Uuid().v4();
    planId = xplanId;
    var subscriptionRequest = SubscriptionRequest(
        planId: xplanId,
        customId: id,
        applicationContext: ApplicationContext(
            returnUrl: returnUrl,
            cancelUrl: cancelUrl,
            paymentMethod: PaymentMethod(
                payeePreferred: PayeePreferred.immediatePaymentRequired)));

    var subscription =
        await subscriptionsApi.createSubscription(subscriptionRequest);
    Navigator.pop(context);
   
    subscriptionId = subscription.id;
    print(subscriptionId);

    // Buscar el link de aprobación
    var approvalLink =
        subscription.links?.firstWhere((link) => link.rel == 'approve').href;

    print('Approval URL: $approvalLink');

    // Abrir navegador en Windows para que el cliente apruebe
    if (approvalLink != null) {
      showLoader(context);
      final webview = await WebviewWindow.create(
        configuration: CreateConfiguration(
          windowHeight: 800,
          windowWidth: 600,
          userDataFolderWindows:path.join(Directory.systemTemp.path,'uresax_invoice_sys_cloud','WEBVIEW','DATA'),
          title: "Aprobar suscripción",
        ),
        
      );
      Navigator.pop(context);

      webview.launch(approvalLink);

      // Escuchar cambios de URL
      webview.addOnUrlRequestCallback((String url) async {
        Uri uri = Uri.parse(url);
        String? xsubscriptionId = uri.queryParameters['subscription_id'];
        print(url);

        if (url.startsWith(returnUrl)) {
          if (subscriptionId != null) {
            print("Suscripción aprobada: $xsubscriptionId");

            var subscriptionDetails = await subscriptionsApi
                .showSubscriptionDetails(xsubscriptionId!);

            if (subscriptionDetails.status == SubscriptionStatus.active) {
              subscriptionId = xsubscriptionId;

              subscriptionActive = true;
              // Guardar en tu DB local
              print('Suscripción activa: $xsubscriptionId');
              await SubscriptionModel.create();

              webview.close();

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
            } else {
              print(
                  'Suscripción aún no activa. Estado: ${subscriptionDetails.status}');
              if (subscriptionActive == false) {
                throw 'NO SE ACTIVO LA SUBSCRIPCION';
              }
            }
          }
        }
      });
    }
  }
}
