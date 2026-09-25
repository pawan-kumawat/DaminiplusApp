

import 'package:flutter/foundation.dart';
import 'dart:convert';

class AllTestsModel{

  final bool status;
  final String message;

  final List<TestModel> testsList;

  AllTestsModel({
    required this.status,
    required this.message,
    required this.testsList,
  });

  factory AllTestsModel.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print(json);
    }
    return AllTestsModel(
      status: json['status'],
      message: json['message'],
      testsList: (json['data'] as List).map((e) => TestModel.fromJson(e)).toList(),
    );

  }


}


class TestModel {

  final int testId;
  final String imageUrl;
  final String title;
  final String subTitle;
  final String subscriptionLevel;
  final List<Question> questionsList;


  TestModel({
    required this.testId,
    required this.imageUrl,
    required this.title,
    required this.subTitle,
    required this.subscriptionLevel,
    required this.questionsList,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    var questionListJson = json['questionsList'] as List<dynamic>?;

    print('Questions List in JSON: $questionListJson');  // Debugging

    return TestModel(
      testId: json['testId'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      title: json['title'] ?? 'Untitled Test',
      subTitle: json['subTitle'] ?? '',
      subscriptionLevel: json['subscriptionLevel'] ?? '1',
      questionsList: questionListJson != null
          ? questionListJson.map((question) => Question.fromJson(question)).toList()
          : [],
    );
  }
}




class Question {
  final int questionId;
  final String questionText;
  final List<Option> options;
  final String correctAnswer; // Update to String

  Question({
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.correctAnswer, // Update to String
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['questionId'],
      questionText: json['questionText'],
      options: (json['options'] as List)
          .map((option) => Option.fromJson(option))
          .toList(),
      correctAnswer: json['correctAnswer'], // Update to String
    );
  }
}

class Option {
  final int optionId;
  final String optionText;

  Option({
    required this.optionId,
    required this.optionText,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      optionId: json['optionId'],
      optionText: json['optionText'],
    );
  }
}





