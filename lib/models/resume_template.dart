/// ---------------------------------------------------------------------------
/// ResUniq - resume_template.dart
/// ---------------------------------------------------------------------------
/// PURPOSE:
/// Plain Dart data models used to represent users, resumes, and resume templates.
///
/// BEGINNER GUIDE:
/// - UI screens/widgets should mainly display information and collect input.
/// - Providers hold/change state that the UI listens to.
/// - Services/repositories perform Firebase, API, PDF, or other data work.
/// - Models describe the data passed between these layers.
///
/// TIP:
/// Read this file together with the classes it imports. The imported classes
/// usually explain where data comes from and where actions are performed.
/// ---------------------------------------------------------------------------
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// GeneratedResumeTemplate is responsible for this part of the ResUniq application.
/// It is kept separate so other files can reuse it without duplicating logic.
class GeneratedResumeTemplate {
  final String id; final String name; final String description; final String accentHex; final String layout; final List<String> sectionOrder; final bool showProfileImage; final String? referenceImageUrl; final DateTime? createdAt;
  final String backgroundHex, textHex, mutedTextHex, secondaryHex, headerBackgroundHex, headerTextHex, headerAlignment, headerStyle, sectionStyle, profileShape, contactStyle, columnLayout, sidebarBackgroundHex, sidebarTextHex;
  final double sidebarPercent, fontScale, sectionSpacing, lineSpacing; final List<String> sidebarSections;
  const GeneratedResumeTemplate({required this.id,required this.name,required this.description,required this.accentHex,required this.layout,required this.sectionOrder,this.showProfileImage=true,this.referenceImageUrl,this.createdAt,this.backgroundHex='#FFFFFF',this.textHex='#111827',this.mutedTextHex='#6B7280',this.secondaryHex='#E5E7EB',this.headerBackgroundHex='#FFFFFF',this.headerTextHex='#111827',this.headerAlignment='center',this.headerStyle='simple',this.sectionStyle='rule',this.profileShape='circle',this.contactStyle='inline',this.columnLayout='single',this.sidebarPercent=30,this.sidebarBackgroundHex='#F3F4F6',this.sidebarTextHex='#111827',this.sidebarSections=const [],this.fontScale=1.0,this.sectionSpacing=12,this.lineSpacing=1.3});
  factory GeneratedResumeTemplate.fromMap(String id, Map<String,dynamic> m){ final rs=m['sectionOrder']; final sec=rs is List?rs.whereType<String>().toList():<String>[]; final rb=m['sidebarSections']; final side=rb is List?rb.whereType<String>().toList():<String>[]; DateTime? d; final rd=m['createdAt']; if(rd is Timestamp)d=rd.toDate(); if(rd is String)d=DateTime.tryParse(rd); return GeneratedResumeTemplate(id:id,name:m['name']?.toString()??'AI-Powered Template',description:m['description']?.toString()??'AI-powered resume template.',accentHex:_hex(m['accentHex']?.toString()),layout:_choice(m['layout']?.toString(),{'minimal','classic','modern','executive'},'minimal'),sectionOrder:sec.isEmpty?const ['objective','experience','education','projects','skills']:sec,showProfileImage:m['showProfileImage']!=false,referenceImageUrl:m['referenceImageUrl']?.toString(),createdAt:d,backgroundHex:_hex(m['backgroundHex']?.toString(),'#FFFFFF'),textHex:_hex(m['textHex']?.toString(),'#111827'),mutedTextHex:_hex(m['mutedTextHex']?.toString(),'#6B7280'),secondaryHex:_hex(m['secondaryHex']?.toString(),'#E5E7EB'),headerBackgroundHex:_hex(m['headerBackgroundHex']?.toString(),'#FFFFFF'),headerTextHex:_hex(m['headerTextHex']?.toString(),'#111827'),headerAlignment:_choice(m['headerAlignment']?.toString(),{'left','center','right'},'center'),headerStyle:_choice(m['headerStyle']?.toString(),{'simple','band','accentBand','split'},'simple'),sectionStyle:_choice(m['sectionStyle']?.toString(),{'rule','accentBar','boxed','plain'},'rule'),profileShape:_choice(m['profileShape']?.toString(),{'circle','square','none'},'circle'),contactStyle:_choice(m['contactStyle']?.toString(),{'inline','stacked'},'inline'),columnLayout:_choice(m['columnLayout']?.toString(),{'single','twoColumn'},'single'),sidebarPercent:_num(m['sidebarPercent'],30,20,45),sidebarBackgroundHex:_hex(m['sidebarBackgroundHex']?.toString(),'#F3F4F6'),sidebarTextHex:_hex(m['sidebarTextHex']?.toString(),'#111827'),sidebarSections:side,fontScale:_num(m['fontScale'],1,0.85,1.2),sectionSpacing:_num(m['sectionSpacing'],12,6,24),lineSpacing:_num(m['lineSpacing'],1.3,1.05,1.7)); }
  Map<String,dynamic> toMap()=>{'name':name,'description':description,'accentHex':accentHex,'layout':layout,'sectionOrder':sectionOrder,'showProfileImage':showProfileImage,if(referenceImageUrl!=null)'referenceImageUrl':referenceImageUrl,'backgroundHex':backgroundHex,'textHex':textHex,'mutedTextHex':mutedTextHex,'secondaryHex':secondaryHex,'headerBackgroundHex':headerBackgroundHex,'headerTextHex':headerTextHex,'headerAlignment':headerAlignment,'headerStyle':headerStyle,'sectionStyle':sectionStyle,'profileShape':profileShape,'contactStyle':contactStyle,'columnLayout':columnLayout,'sidebarPercent':sidebarPercent,'sidebarBackgroundHex':sidebarBackgroundHex,'sidebarTextHex':sidebarTextHex,'sidebarSections':sidebarSections,'fontScale':fontScale,'sectionSpacing':sectionSpacing,'lineSpacing':lineSpacing,'createdAt':FieldValue.serverTimestamp()};
  static String _hex(String? v,[String f='#0F285D'])=>RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(v??'')?v!.toUpperCase():f;
  static String _choice(String? v,Set<String>a,String f)=>a.contains(v)?v!:f;
  static double _num(dynamic v,double f,double min,double max){final n=v is num?v.toDouble():double.tryParse(v?.toString()??'');if(n==null||!n.isFinite)return f;return n.clamp(min,max).toDouble();}
}
