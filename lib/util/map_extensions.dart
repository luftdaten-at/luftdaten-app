extension MapToJson on dynamic {
  Map<dynamic, dynamic> get json => (this as Map).cast<String, dynamic>();
}