import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:vocechat_client/app.dart';

/// 服务用于在发起API请求之前处理URL重定向
class UrlRedirectService {
  static final UrlRedirectService _instance = UrlRedirectService._internal();
  
  factory UrlRedirectService() {
    return _instance;
  }
  
  UrlRedirectService._internal();
  
  /// 尝试获取URL的最终重定向地址
  /// 如果URL不重定向，则返回原始URL
  Future<String> getRedirectedUrl(String originalUrl) async {
    try {
      // 如果URL为空或格式无效，则直接返回原始URL
      if (originalUrl.isEmpty || !Uri.parse(originalUrl).hasAuthority) {
        return originalUrl;
      }
      
      // 创建HTTP客户端，设置不自动重定向
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      // 不使用自动重定向，我们手动处理
      
      // 发起HEAD请求以检查重定向（HEAD比GET轻量）
      final request = await client.headUrl(Uri.parse(originalUrl));
      // 设置请求不跟随重定向
      request.followRedirects = false;
      final response = await request.close();
      
      // 关闭客户端
      client.close();
      
      // 检查是否有重定向（状态码301或302）
      if (response.statusCode == HttpStatus.movedPermanently || 
          response.statusCode == HttpStatus.movedTemporarily ||
          response.statusCode == HttpStatus.permanentRedirect ||
          response.statusCode == HttpStatus.seeOther) {
        
        // 获取Location头部的重定向URL
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location != null && location.isNotEmpty) {
          // 如果重定向URL是相对路径，需要与原始URL合并
          final redirectUrl = _resolveRedirectUrl(originalUrl, location);
          App.logger.info('URL重定向: $originalUrl -> $redirectUrl');
          
          // 递归检查重定向链，最多5次重定向
          return await _followRedirects(redirectUrl, 1, 5);
        }
      }
      
      // 没有重定向，返回原始URL
      return originalUrl;
    } catch (e) {
      App.logger.warning('检查URL重定向时出错: $e');
      // 出错时返回原始URL
      return originalUrl;
    }
  }
  
  /// 跟踪重定向链，限制最大重定向次数
  Future<String> _followRedirects(String url, int currentRedirect, int maxRedirects) async {
    if (currentRedirect >= maxRedirects) {
      App.logger.warning('达到最大重定向次数: $maxRedirects');
      return url;
    }
    
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      
      final request = await client.headUrl(Uri.parse(url));
      // 设置请求不跟随重定向
      request.followRedirects = false;
      final response = await request.close();
      
      client.close();
      
      if (response.statusCode == HttpStatus.movedPermanently || 
          response.statusCode == HttpStatus.movedTemporarily ||
          response.statusCode == HttpStatus.permanentRedirect ||
          response.statusCode == HttpStatus.seeOther) {
        
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location != null && location.isNotEmpty) {
          final redirectUrl = _resolveRedirectUrl(url, location);
          App.logger.info('URL重定向链 $currentRedirect: $url -> $redirectUrl');
          return await _followRedirects(redirectUrl, currentRedirect + 1, maxRedirects);
        }
      }
      
      return url;
    } catch (e) {
      App.logger.warning('跟踪重定向时出错: $e');
      return url;
    }
  }
  
  /// 解析重定向URL，处理相对URL的情况
  String _resolveRedirectUrl(String originalUrl, String redirectLocation) {
    if (redirectLocation.startsWith('http://') || redirectLocation.startsWith('https://')) {
      return redirectLocation;
    }
    
    final originalUri = Uri.parse(originalUrl);
    if (redirectLocation.startsWith('/')) {
      // 绝对路径相对于主机名
      return '${originalUri.scheme}://${originalUri.host}${originalUri.port != 80 && originalUri.port != 443 ? ':${originalUri.port}' : ''}$redirectLocation';
    } else {
      // 相对路径相对于当前URL的路径
      final originalPath = originalUri.path.endsWith('/') ? originalUri.path : '${originalUri.path}/';
      return '${originalUri.scheme}://${originalUri.host}${originalUri.port != 80 && originalUri.port != 443 ? ':${originalUri.port}' : ''}$originalPath$redirectLocation';
    }
  }
} 