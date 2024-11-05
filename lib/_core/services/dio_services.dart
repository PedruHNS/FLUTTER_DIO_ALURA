import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_listin/_core/data/local_data_handler.dart';
import 'package:flutter_listin/_core/services/dio_endpoints.dart';
import 'package:flutter_listin/_core/services/dio_interceptor.dart';
import 'package:flutter_listin/listins/data/database.dart';

class DioServices {
  var isloading = false;
  var messenge = '';
  final _dio = Dio(
    BaseOptions(
      baseUrl: DioEndpoints.baseUrl,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  DioServices() {
    _dio.interceptors.add(DioInterceptor());
  }

  Future<String?> saveLocalToServer(AppDatabase appdatabase) async {
    _setLoading(true);

    final localData = await LocalDataHandler().localDataToMap(
      appdatabase: appdatabase,
    );
    try {
      await _dio.put(
        DioEndpoints.listin,
        data: json.encode(localData['listins']),
      );
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data!.toString();
      }
      return e.message;
    } on Exception {
      return 'um erro aconteceu';
    }
    _setLoading(false);
    return null;
  }

  Future<void> getDataBasFromServer(AppDatabase appdatabase) async {
    _setLoading(true);
    final response = await _dio.get(
      DioEndpoints.listin,
      queryParameters: {"orderBy": '"name"', "startAt": 0},
    );

    if (response.data == null) return;

    var map = <String, dynamic>{};

    if (response.data.runtimeType == List) {
      if ((response.data as List<dynamic>).isNotEmpty) {
        map['listins'] = response.data;
      }
    } else {
      List<Map<String, dynamic>> tempList = [];

      for (var mapResponse in (response.data as Map).values) {
        tempList.add(mapResponse);
      }
      map['listins'] = tempList;
    }
    await LocalDataHandler().mapToLocalData(
      map: map,
      appdatabase: appdatabase,
    );

    _setLoading(false);
  }

  Future<void> clearServer() async {
    _setLoading(true);
    final response = await _dio.delete(DioEndpoints.listin);
    _setLoading(false);

    if (response.statusCode == 200) {
      messenge = 'Lista apagada com sucesso';
    } else {
      messenge = 'Erro ao apagar lista';
    }
  }

  final _loadingController = StreamController<bool>.broadcast();

  Stream<bool> get loadingStream => _loadingController.stream;

  void _setLoading(bool value) {
    isloading = value;
    _loadingController.add(value);
  }

  void dispose() {
    _loadingController.close();
  }
}
