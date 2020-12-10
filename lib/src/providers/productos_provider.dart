import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime_type/mime_type.dart';
import 'package:http_parser/http_parser.dart';

import 'package:food_available/src/preferencias_usuario/preferencias_usuario.dart';
import 'package:food_available/src/models/producto_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
export 'package:food_available/src/models/producto_model.dart';

class ProductosProvider {
  SharedPreferences _prefs;
  initPrefs() async {
    this._prefs = await SharedPreferences.getInstance();
  }

  final String _url = 'https://task-ulibre.firebaseio.com';
  final _pref = new PreferenciasUsuario();

  Future<int> validarToken() async {
    final url = '$_url/productos/1.json?auth=${_pref.token}';
    final resp = await http.delete(url);
    if (resp.statusCode == 200) {
      _pref.page = 'opciones';
    } else {
      _pref.page = 'login';
    }
    return 1;
  }

  //final String _url = 'https://food-available-dev.firebaseio.com';
  final productosModel = new ProductoModel();

  Future<bool> crearProducto(ProductoModel producto) async {
    final url = '$_url/productos.json?auth=${_pref.token}';
    final resp = await http.post(url, body: productoModelToJson(producto));
    //final decodedData = json.decode(resp.body);
    //print(decodedData);
    return true;
  }

  Future<bool> editarProducto(ProductoModel producto) async {
    final url = '$_url/productos/${producto.id}.json?auth=${_pref.token}';
    //final resp = producto.remove('id');
    final resp = await http.put(url, body: productoModelToJson(producto));
    final decodedData = json.decode(resp.body);
    return true;
  }

  Future<List<ProductoModel>> listarProductos() async {
    final url =
        '$_url/productos.json?orderBy="id_correo"&equalTo="${_pref.correo}"&print=pretty&auth=${_pref.token}';
    //print(url);
    final resp = await http.get(url);
    final List<ProductoModel> productos =
        productosModel.modelarProductos(json.decode(resp.body));
    return productos;
  }

  Future<List<ProductoModel>> listarProductosRecolector([int value = 1]) async {
    final url =
        '$_url/productos.json?orderBy="estado"&equalTo=$value&print=pretty&auth=${_pref.token}';
    //print(url);
    final resp = await http.get(url);
    final List<ProductoModel> productos =
        productosModel.modelarProductos(json.decode(resp.body));
    return productos;
  }

  Future<ProductoModel> listarEvidenciaRecolector([int value = 1]) async {
    final url =
        '$_url/productos.json?orderBy="estado"&equalTo=$value&print=pretty&auth=${_pref.token}';
    //print(url);
    final resp = await http.get(url);
    final List<ProductoModel> productos =
        productosModel.modelarProductos(json.decode(resp.body));
    ProductoModel productosNew = new ProductoModel();
    productos.forEach((data) {
      if (data.idCorreoRepartidor == _pref.correo) {
        productosNew = productosModel.toProductoModel(data);
      }
    });
    return productosNew;
  }

  Future<int> eliminarProducto(String id) async {
    final url = '$_url/productos/$id.json?auth=${_pref.token}';
    final resp = await http.delete(url);
    return 1;
  }

  Future<String> subirImagen(File imagen) async {
    final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/kevincho/image/upload?upload_preset=aw5ugyu7');
    final mimeType = mime(imagen.path).split('/');
    final imageUploadRequest = http.MultipartRequest('POST', url);
    final file = await http.MultipartFile.fromPath('file', imagen.path,
        contentType: MediaType(mimeType[0], mimeType[1]));

    imageUploadRequest.files.add(file);
    final streamResponse = await imageUploadRequest.send();
    final resp = await http.Response.fromStream(streamResponse);
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      //print('algo esta mal');
      //print(resp.body);
      return null;
    }
    final respData = json.decode(resp.body);
    //print(respData);
    return respData['secure_url'];
  }
}