part of persistent_object;
class _ValueConverter{
  PersistentList persistentList;
  _ValueConverter(this.persistentList);

   convertValue(value) {
    var result;
    if (value == null) {
      return null;
    }
    if (value is Map) {
      return objectory.map2Object(persistentList.elementType, value);
    }
    if (value is DbRef) {
      return objectory.dbRef2Object(value);
    }
  }
}
class _PersistentIterator<E> implements Iterator<E> {
  Iterator _it;
  _ValueConverter valueConverter;
  PersistentList persistentList;
  _PersistentIterator(this.persistentList,this._it, this.valueConverter);
  E next() => valueConverter.convertValue(_it.next());
  bool get hasNext => _it.hasNext;
}

class PersistentList<E> implements List<E>{
  bool isEmbeddedObject = false;
  BasePersistentObject _parent;
  String pathToMe;
  String elementType;
  List _list;
//  set internalList(List value) => _list = value;
  List get internalList => _list;
  _ValueConverter valueConverter;
  PersistentList._internal(this._parent, this.elementType, this.pathToMe) {
    if (_parent.map[pathToMe] == null) {
      _parent.map[pathToMe] = [];
    }
    _list = _parent.map[pathToMe];
    if (objectory.newInstance(elementType) is EmbeddedPersistentObject) {
      isEmbeddedObject = true;
    }
    valueConverter = new _ValueConverter(this);
  }
  factory PersistentList(BasePersistentObject parent, String elementType, String pathToMe) {
    PersistentList result = parent._compoundProperties[pathToMe];
    if (result == null) {
      result = new PersistentList._internal(parent,elementType,pathToMe);
      parent._compoundProperties[pathToMe] = result;
    }
    return result;
  }
  toString() => "PersistentList($_list)";

  void setDirty(String propertyName) {
    _parent.setDirty(pathToMe);
  }


  internValue(E value) {
    // get rid of warnings (Type inferring does not work in code below)
    //TODO revert when possible 
    var el = value;
    if (el is EmbeddedPersistentObject) {
      el._parent = _parent;
      el._pathToMe = pathToMe;
      return el.map;
    }
    if (value is PersistentObject) {
      return el.dbRef;
    }
    return value;
  }


  bool get isEmpty => _list.isEmpty;

  void forEach(void f(element)) => _list.forEach(f);

  Collection map(f(E element)) => _list.map(f);

  Collection<E> filter(bool f(E element)) => _list.filter(f);

  bool every(bool f(E element)) => _list.every(f);

  bool some(bool f(E element)) => _list.some(f);

  Iterator<E> iterator() => new _PersistentIterator(this,_list.iterator(),valueConverter);

  int indexOf(E element, [int start = 0]) => _list.indexOf(element, start);

  int lastIndexOf(E element, [int start]) => _list.lastIndexOf(element, start);

  int get length => _list.length;

  void sort([Comparator compare = Comparable.compare]) {
    _list.sort(compare);
  }

  List getRange(int start, int length) => _list.getRange(start, length);

  void add(E element){
    _list.add(internValue(element));
    setDirty(null);
  }

  void remove(E element){
    if (_list.indexOf(element) == -1) return;
    _list.removeRange(_list.indexOf(element), 1);
    setDirty(null);
  }

  void addAll(Collection<E> elements){
    _list.addAll(elements);
    setDirty(null);
  }

  void clear(){
    Collection<E> c = _list;
    _list.clear();
    setDirty(null);
  }

  E removeLast(){
    E item = _list.last;
    _list.removeLast();
    setDirty(null);
    return item;
  }

  E get last => _list.last;

  void insertRange(int start, int length, [E initialValue]){
    _list.insertRange(start, length, initialValue);
    setDirty(null);
  }

  void addLast(E value) => _list.addLast(value);

  void removeRange(int start, int length){
    _list.removeRange(start, length);
    setDirty(null);
  }
  bool contains(E element) => _list.contains(element);

  void setRange(int start, int length, List<E> from, [int startFrom]){
    _list.setRange(start, length, from, startFrom);
    setDirty(null);
  }
  void set length(int newLength) {
    _list.length = newLength;
  }
  E removeAt(int index) => _list.removeAt(index);
  dynamic reduce(dynamic initialValue,
                 dynamic combine(dynamic previousValue, E element)) => _list.reduce(initialValue, combine);


  void operator[]=(int index, E value){
    _list[index] = internValue(value);
    setDirty(null);
  }

  E operator[](int index) {
    return valueConverter.convertValue(_list[index]);
  }


}