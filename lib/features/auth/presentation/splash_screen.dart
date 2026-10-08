import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget { const SplashScreen({super.key}); @override State<SplashScreen> createState()=>_SplashState(); }
class _SplashState extends State<SplashScreen> { @override void initState(){super.initState();Future.delayed(const Duration(milliseconds:650),(){if(mounted)context.go('/home');});} @override Widget build(BuildContext c)=>const Scaffold(body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.cloud_done_rounded,size:76,color:AppTheme.primary),SizedBox(height:18),Text('DEX Host',style:TextStyle(fontSize:30,fontWeight:FontWeight.w800)),SizedBox(height:8),Text('Powerful Hosting. Simplified.',style:TextStyle(color:AppTheme.muted))]))); }
