// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../ChatMessageModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageModel _$ChatMessageModelFromJson(Map<String, dynamic> json) =>
    ChatMessageModel(
      text: json['text'] as String,
      senderId: json['senderId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ChatMessageModelToJson(ChatMessageModel instance) =>
    <String, dynamic>{
      'text': instance.text,
      'senderId': instance.senderId,
      'createdAt': instance.createdAt.toIso8601String(),
    };
