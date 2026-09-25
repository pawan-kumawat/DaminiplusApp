

class TestDataGet{

  final bool status;
  final String message;


  TestDataGet({
  required this.status,
    required this.message,
  });


  TestDataGet.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        message = json['message'];
}



// {
// "type": "general",
// "setup": "Did you hear about the runner who was criticized?",
// "punchline": "He just took it in stride",
// "id": 94
// }

class SendOtpModel{

  final bool status;
  final String message;


  SendOtpModel({
    required this.status,
    required this.message,
  });


  SendOtpModel.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        message = json['message'];
}


