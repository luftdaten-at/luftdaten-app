extension MapToJson on dynamic {
  Map<String, dynamic> get json => (this as Map).cast<String, dynamic>();
}