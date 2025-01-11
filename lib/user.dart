class User {
  String _fullName;
  String _contactNumber;
  String _email;
  String _password;

  User(this._fullName, this._contactNumber, this._email, this._password);

  String get password => _password;

  set password(String value) {
    _password = value;
  }

  String get email => _email;

  set email(String value) {
    _email = value;
  }

  String get contactNumber => _contactNumber;

  set contactNumber(String value) {
    _contactNumber = value;
  }

  String get fullName => _fullName;

  set fullName(String value) {
    _fullName = value;
  }
}
