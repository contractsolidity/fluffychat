import 'dart:async';

import 'package:famedlysdk/famedlysdk.dart';
import 'package:fluffychat/i18n/i18n.dart';
import 'package:fluffychat/utils/app_route.dart';
import 'package:fluffychat/views/chat_encryption_settings.dart';
import 'package:flutter/material.dart';

import 'dialogs/simple_dialogs.dart';
import 'matrix.dart';

class EncryptionButton extends StatefulWidget {
  final Room room;
  const EncryptionButton(this.room, {Key key}) : super(key: key);
  @override
  _EncryptionButtonState createState() => _EncryptionButtonState();
}

class _EncryptionButtonState extends State<EncryptionButton> {
  StreamSubscription _onSyncSub;

  void _enableEncryptionAction() async {
    if (widget.room.encrypted) {
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text(I18n.of(context).warningEncryptionInBeta),
        ),
      );
      await Navigator.of(context).push(
        AppRoute.defaultRoute(
          context,
          ChatEncryptionSettingsView(widget.room.id),
        ),
      );
      return;
    }
    if (!widget.room.client.encryptionEnabled) {
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text(
            I18n.of(context).needPantalaimonWarning,
          ),
        ),
      );
      return;
    }
    if (await SimpleDialogs(context).askConfirmation(
          titleText: I18n.of(context).enableEncryptionWarning,
          contentText: widget.room.client.encryptionEnabled
              ? I18n.of(context).warningEncryptionInBeta
              : I18n.of(context).needPantalaimonWarning,
          confirmText: I18n.of(context).yes,
        ) ==
        true) {
      await Matrix.of(context).tryRequestWithLoadingDialog(
        widget.room.enableEncryption(),
      );
    }
  }

  @override
  void dispose() {
    _onSyncSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _onSyncSub ??= Matrix.of(context)
        .client
        .onSync
        .stream
        .listen((s) => setState(() => null));
    return FutureBuilder<List<DeviceKeys>>(
        future: widget.room.getUserDeviceKeys(),
        builder: (BuildContext context, snapshot) {
          Color color;
          if (widget.room.encrypted && snapshot.hasData) {
            final List<DeviceKeys> deviceKeysList = snapshot.data;
            color = Colors.orange;
            if (deviceKeysList.indexWhere((DeviceKeys deviceKeys) =>
                    deviceKeys.verified == false &&
                    deviceKeys.blocked == false) ==
                -1) {
              color = Colors.black.withGreen(220).withOpacity(0.75);
            }
          } else if (!widget.room.encrypted &&
              widget.room.joinRules != JoinRules.public) {
            color = null;
          }
          return IconButton(
            icon: Icon(widget.room.encrypted ? Icons.lock : Icons.lock_open,
                size: 20, color: color),
            onPressed: _enableEncryptionAction,
          );
        });
  }
}
