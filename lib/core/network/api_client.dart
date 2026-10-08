import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../app/config.dart';
import '../storage/secure_storage.dart';

class ApiException implements Exception { const ApiException(this.message,this.status); final String message; final int? status; @override String toString()=>message; }
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.storage); final SecureStorage storage;
  @override void onRequest(RequestOptions options, RequestInterceptorHandler handler) { _continue(options,handler); }
  Future<void> _continue(RequestOptions options, RequestInterceptorHandler handler) async { try { final token=await storage.readToken(); if(token!=null) options.headers['Authorization']='Bearer $token'; } catch (_) {} handler.next(options); }
}
class ApiClient {
  ApiClient(this.storage):dio=Dio(BaseOptions(baseUrl:AppConfig.apiBaseUrl,connectTimeout:const Duration(seconds:20),sendTimeout:const Duration(seconds:60),receiveTimeout:const Duration(seconds:45),headers:{'Accept':'application/json'})){dio.interceptors.add(AuthInterceptor(storage));}
  final Dio dio; final SecureStorage storage;
  Future<dynamic> request(Future<Response<dynamic>> Function() fn)async{try{return (await fn()).data;}on DioException catch(e){final s=e.response?.statusCode;final d=e.response?.data;String m='تعذر الاتصال بالخادم.';if(e.type==DioExceptionType.connectionError||e.type==DioExceptionType.connectionTimeout)m='تعذر الاتصال بالخادم. تحقق من الإنترنت.';if(d is Map&&d['detail']!=null)m=d['detail'].toString();if(s==401){await storage.clear();m='انتهت جلسة تسجيل الدخول.';}if(s==403)m='ليس لديك صلاحية لتنفيذ هذه العملية.';if(s==404)m='العنصر المطلوب غير موجود.';if(s==409)m='تعارض في البيانات.';if(s==422)m='البيانات المدخلة غير صحيحة.';if(s==429)m='محاولات كثيرة، حاول لاحقاً.';if(s!=null&&s>=500)m='الخدمة غير متاحة مؤقتاً، حاول لاحقاً.';throw ApiException(m,s);} }
  Future<dynamic> get(String p,{Map<String,dynamic>? q})=>request(()=>dio.get(p,queryParameters:q));
  Future<dynamic> post(String p,{Object? data,Map<String,dynamic>? q})=>request(()=>dio.post(p,data:data,queryParameters:q));
  Future<dynamic> put(String p,{Object? data})=>request(()=>dio.put(p,data:data));
  Future<dynamic> delete(String p,{Map<String,dynamic>? q})=>request(()=>dio.delete(p,queryParameters:q));
  Future<dynamic> upload(String path,Uint8List bytes,String filename,{Map<String,dynamic>? query,String field='f',Uint8List? requirementsBytes,ProgressCallback? onProgress})async{final form=FormData.fromMap({field:MultipartFile.fromBytes(bytes,filename:filename),if(requirementsBytes!=null)'requirements':MultipartFile.fromBytes(requirementsBytes,filename:'requirements.txt')});return request(()=>dio.post(path,data:form,queryParameters:query,onSendProgress:onProgress,options:Options(contentType:'multipart/form-data')));}
  Future<dynamic> putBytes(String path,Uint8List bytes)=>request(()=>dio.put(path,data:bytes,options:Options(contentType:'application/octet-stream')));
}
