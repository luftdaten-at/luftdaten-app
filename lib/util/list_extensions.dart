extension IterableMean on Iterable<num> {
  double get mean {
    double sum = 0;
    for(num n in this) {
      sum += n;
    }
    return sum / length;
  }
}

extension ListRemoveNulls<T> on List<T?> {
  List<T> removeListNulls() => where((element) => element != null).map((e) => e!).toList();
}

extension SpaceWith<A> on List<A> {
  List<A> spaceWith(A spacer, {A? first}) {
    if (isEmpty) return this;
    if (length == 1) return this;
    List<A> list = [this[0]];
    for (int i = 1; i < length; i++) {
      if(i == 1 && first != null) {
        list.add(first);
      } else {
        list.add(spacer);
      }
      list.add(this[i]);
    }
    return list;
  }

  List<A> spaceWithList(List<A> spacer, {A? first}) {
    if (isEmpty) return this;
    if (length == 1) return this;
    List<A> list = [this[0]];
    for (int i = 1; i < length; i++) {
      if(i == 1 && first != null) {
        list.add(first);
      } else {
        list.addAll(spacer);
      }
      list.add(this[i]);
    }
    return list;
  }
}

extension AllIndiciesOf<A> on List<A> {
  List<int> allIndicesOf(bool Function(A) test) {
    List<int> indices = [];
    for (int i = 0; i < length; i++) {
      if (test(this[i])) {
        indices.add(i);
      }
    }
    return indices;
  }
}