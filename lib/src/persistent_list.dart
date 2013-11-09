part of persistent_object;
class _ValueConverter{
  PersistentList persistentList;
  _ValueConverter(this.persistentList);

   convertValue(value) {
    if (value == null) {
      return null;
    }
    if (value is Map) {
      return (objectory.map2Object(persistentList.elementType, value) as EmbeddedPersistentObject)
      .._parent = persistentList._parent 
      .._pathToMe = persistentList._pathToMe
      .._elementListMode = true; 
    }
    if (value is DbRef) {
      return objectory.dbRef2Object(value);
    }
    throw new Exception('Value of unknown type in Persistent list: %value');
  }
}

class PersistentList<E> extends ListBase<E>{
  bool isEmbeddedObject = false;
  BasePersistentObject _parent;
  String _pathToMe;
  Type elementType;
  List _list;
//  set internalList(List value) => _list = value;
  List get internalList => _list;
  _ValueConverter valueConverter;
  PersistentList._internal(this._parent, this.elementType, this._pathToMe) {
    List lst = _parent.map[_pathToMe];
    if (lst == null) {
      lst = [];
    }
    _list = objectory.dataListDecorator(lst);
    _parent.map[_pathToMe] = _list;
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
    _parent.setDirty(_pathToMe);
  }


  internValue(E value) {
    var el = value;
    if (el is EmbeddedPersistentObject) {
      el._parent = _parent;
      el._pathToMe = _pathToMe;
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
  
  void clear() {
    setDirty(null);
    _list.clear();
  }
}



