
class LoginModel{

  final bool status;
  final String message;

  final LoginData? data;

  LoginModel({
    required this.status,
    required this.message,
    required this.data,
  });


  LoginModel.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        message = json['message'],
        data = json['data'] != null ? LoginData.fromJson(json['data']) : null
  ;

}



class LoginData{

  final int id;

  final String username;
  final String mobileNumber;
  final String name;
  final String jwtToken;
  final String referralCode;

  final bool isNewUser;

  LoginData({
    required this.id,
    required this.username,
    required this.mobileNumber,
    required this.name,
    required this.jwtToken,
    required this.referralCode,
    required this.isNewUser,
  });


  LoginData.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        username = json['username'],
        mobileNumber = json['mobileNumber'],
        name = json['name'],
        jwtToken = json['jwtToken'],
        referralCode = json['referralCode'],
        isNewUser = json['isNewUser']
  ;

}
