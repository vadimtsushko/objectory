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
    throw 'Value of unknown type in Persistent list: %value';
  }
}

class PersistentList<E> extends ListBase<E>{
  bool isEmbeddedObject = false;
  BasePersistentObject _parent;
  String pathToMe;
  Type elementType;
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
  factory PersistentList(BasePersistentObject parent, Type elementType, String pathToMe) {
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
    var el = value;
    if (el is EmbeddedPersistentObject) {
      el._parent = _parent;
      el._pathToMe = pathToMe;
      return el.map;
    }
    if (el is PersistentObject) {
      return el.dbRef;
    }
    return value;
  }

  int get length => _list.length;

  void set length(int newLength) {
    _list.length = newLength;
  }

  void operator[]=(int index, E value){
    _list[index] = internValue(value);
    setDirty(null);
  }

  E operator[](int index) => valueConverter.convertValue(_list[index]);
}



