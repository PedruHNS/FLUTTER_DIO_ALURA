import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_listin/_core/services/dio_services.dart';

import 'package:flutter_listin/authentication/models/mock_user.dart';
import 'package:flutter_listin/listins/data/database.dart';
import 'package:flutter_listin/listins/screens/widgets/dialog_widget.dart';
import 'package:flutter_listin/listins/screens/widgets/home_drawer.dart';
import 'package:flutter_listin/listins/screens/widgets/home_listin_item.dart';
import '../models/listin.dart';
import 'widgets/listin_add_edit_modal.dart';
import 'widgets/listin_options_modal.dart';

class HomeScreen extends StatefulWidget {
  final MockUser user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Listin> listListins = [];
  late AppDatabase _appDatabase;
  final DioServices _dioServices = DioServices();

  @override
  void initState() {
    _appDatabase = AppDatabase();
    refresh();
    super.initState();
  }

  @override
  void dispose() {
    _appDatabase.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: HomeDrawer(user: widget.user),
      appBar: AppBar(
        title: const Text("Minhas listas"),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.cloud),
            onSelected: (value) {
              switch (value) {
                case 'cloud-send':
                  cloudUpload();
                  break;
                case 'cloud-sync':
                  cloudSync();
                  break;
                case 'cloud-clear':
                  cloudClear();
                  break;
              }
            },
            itemBuilder: (_) {
              return [
                const PopupMenuItem(
                  value: 'cloud-send',
                  child: ListTile(
                    leading: Icon(Icons.cloud_upload),
                    title: Text('enviar para nuvem'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'cloud-sync',
                  child: ListTile(
                    leading: Icon(Icons.cloud_sync),
                    title: Text('sincronizar com a nuvem'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'cloud-clear',
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('deletar da nuvem'),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddModal();
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<bool>(
          stream: _dioServices.loadingStream,
          initialData: false,
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              return listListins.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset("assets/bag.png"),
                          const SizedBox(height: 32),
                          const Text(
                            "Nenhuma lista ainda.\nVamos criar a primeira?",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () {
                        return refresh();
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                        child: ListView(
                          children: List.generate(
                            listListins.length,
                            (index) {
                              Listin listin = listListins[index];
                              return HomeListinItem(
                                listin: listin,
                                showOptionModal: showOptionModal,
                              );
                            },
                          ),
                        ),
                      ),
                    );
            }
          }),
    );
  }

  showAddModal({Listin? listin}) {
    showAddEditListinModal(
      context: context,
      onRefresh: refresh,
      model: listin,
      appDatabase: _appDatabase,
    );
  }

  showOptionModal(Listin listin) {
    showListinOptionsModal(
      context: context,
      listin: listin,
      onRemove: remove,
    ).then((value) {
      if (value != null && value) {
        showAddModal(listin: listin);
      }
    });
  }

  refresh() async {
    // Basta alimentar essa variável com Listins que, quando o método for
    // chamado, a tela sera reconstruída com os itens.
    List<Listin> listaListins = await _appDatabase.getListins();

    setState(() {
      listListins = listaListins;
    });
  }

  void remove(Listin model) async {
    await _appDatabase.deleteListin(int.parse(model.id));
    refresh();
  }

  cloudUpload() async {
    log('upload');
    showDialog(
      context: context,
      builder: (context) {
        return DialogWidget(
          title: 'Enviar para nuvem?',
          content: 'Deseja realmente mandar para nuvem?',
          onPressed: () async {
            _dioServices.saveLocalToServer(_appDatabase).then((error) {
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                  ),
                );
              }
            });
            if (context.mounted) Navigator.pop(context);
          },
        );
      },
    );
  }

  cloudSync() async {
    log('sync');

    refresh();
    showDialog(
      context: context,
      builder: (context) {
        return DialogWidget(
          title: 'sincronizar com a nuvem?',
          content: 'Deseja realmente fazer a sincronização do app com a nuvem?',
          onPressed: () async {
            await _dioServices.getDataBasFromServer(_appDatabase);
            if (context.mounted) Navigator.pop(context);
            refresh();
          },
        );
      },
    );
  }

  cloudClear() async {
    log('clear');
    showDialog(
      context: context,
      builder: (context) {
        return DialogWidget(
          title: 'Limpar a nuvem',
          content:
              'Deseja realmente limpar a nuvem?\nEsse processo não será revertido!!',
          onPressed: () async {
            await _dioServices.clearServer();
            if (context.mounted) Navigator.pop(context);
            if (_dioServices.messenge != '') {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_dioServices.messenge),
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
}
