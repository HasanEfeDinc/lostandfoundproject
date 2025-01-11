import 'dart:io';

class Item {
  String _itemName;
  String _description;
  String _status;
  String _date;
  File? _image;
  double? _lat;
  double? _lng;

  Item(this._itemName, this._description, this._status, this._date, {double? lat, double? lng}) {
    _lat = lat;
    _lng = lng;
  }

  File? getImage() {
    return _image;
  }

  void setImage(File image) {
    _image = image;
  }

  String getDate() {
    return _date;
  }

  void setDate(String date) {
    _date = date;
  }

  String getStatus() {
    return _status;
  }

  void setStatus(String status) {
    _status = status;
  }

  String getDescription() {
    return _description;
  }

  void setDescription(String description) {
    _description = description;
  }

  String getItemName() {
    return _itemName;
  }

  void setItemName(String itemName) {
    _itemName = itemName;
  }

  double? getLat() {
    return _lat;
  }

  void setLat(double lat) {
    _lat = lat;
  }

  double? getLng() {
    return _lng;
  }

  void setLng(double lng) {
    _lng = lng;
  }
}
