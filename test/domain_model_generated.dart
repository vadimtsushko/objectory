/// Warning! That file is generated. Do not edit it manually
part of domain_model;

class $Occupation {
  static Field<String> get name =>
      const Field<String>(id: 'name',label: 'Ocuppation',title: 'Titular name of profession',
          parentTable: null,parentField: '',staticValue: '',
          defaultValue: '',
          type: String,logChanges: true, foreignKey: false,externalKey: false,width: 0,tootltipsOnContent: false);
  static Field<int> get branch =>
      const Field<int>(id: 'branch',label: '',title: '',
          parentTable: null,parentField: '',staticValue: '',
          defaultValue: null,
          type: Branch,logChanges: true, foreignKey: true,externalKey: false,width: 0,tootltipsOnContent: false);
 static TableSchema schema = new TableSchema(
      tableName: 'Occupation',
      tableType: Occupation,
      logChanges: true,
      isView: false,
      cacheValues: false,
      createScript: '''
''',
      superSchema: $PersistentObject.schema,
      fields: {
          'name': name,
          'branch': branch
      });
}

class Occupation extends PersistentObject {
  TableSchema get $schema => $Occupation.schema;
  String get name => getProperty('name');
  set name (String value) => setProperty('name',value);
  Branch get branch => getLinkedObject('branch', Branch);
  set branch(Branch value) => setLinkedObject('branch', value);
}

class $User {
  static Field<String> get name =>
      const Field<String>(id: 'name',label: '',title: '',
          parentTable: null,parentField: '',staticValue: '',
          defaultValue: '',
          type: String,logChanges: true, foreignKey: false,externalKey: false,width: 0,tootltipsOnContent: false);
  static Field<String> get email =>
      const Field<String>(id: 'email',label: '',title: '',
          parentTable: null,parentField: '',staticValue: '',
          defaultValue: '',
          type: String,logChanges: true, foreignKey: false,externalKey: false,width: 0,tootltipsOnContent: false);
  static Field<String> get login =>
      const Field<String>(id: 'login',label: '',title: '',
          parentTable: null,parentField: '',staticValue: '',
          defaultValue: '',
          type: String,logChanges: true, foreignKey: false,externalKey: false,width: 0,tootltipsOnContent: false);
 static TableSchema schema = new TableSchema(
      tableName: 'User',
      tableType: User,
      logChanges: false,
      isView: false,
      cacheValues: false,
      createScript: '''
''',
      superSchema: $PersistentObject.schema,
      fields: {
          'name': name,
          'email': email,
          'login': login
      });
}

class User extends PersistentObject {
  TableSchema get $schema => $User.schema;
  String get name => getProperty('name');
  set name (String value) => setProperty('name',value);
  String get email => getProperty('email');
  set email (String value) => setProperty('email',value);
  String get login => getProperty('login');
  set login (String value) => setProperty('login',value);
}

class $Branch {
  static Field<String> get name =>
      const Field<String>(id: 'name',label: 'Branch',title: 'Branch of wisdom',
          parentTable: null,parentField: '',staticValue: '',
          defaultValue: '',
          type: String,logChanges: true, foreignKey: false,externalKey: false,width: 0,tootltipsOnContent: false);
 static TableSchema schema = new TableSchema(
      tableName: 'Branch',
      tableType: Branch,
      logChanges: true,
      isView: false,
      cacheValues: false,
      createScript: '''
''',
      superSchema: $PersistentObject.schema,
      fields: {
          'name': name
      });
}

class Branch extends PersistentObject {
  TableSchema get $schema => $Branch.schema;
  String get name => getProperty('name');
  set name (String value) => setProperty('name',value);
}

class $PersonView {
  static Field<String> get occupationName =>
      const Field<String>(id: 'occupationName',label: 'Ocuppation',title: 'Titular name of profession',
          parentTable: Occupation,parentField: 'name',staticValue: '',
          defaultValue: '',
          type: String,logChanges: true, foreignKey: false,externalKey: false,width: 0,tootltipsOnContent: false);
  static Field<String> get branchName =>
      const Field<String>(id: 'branchName',label: 'Branch',title: 'Branch of wisdom',
          parentTable: Branch,parentField: 'name',staticValue: '',
          defaultValue: '',
          type: String,logChanges: true, foreignKey: false,externalKey: false,width: 0,tootltipsOnContent: false);
 static TableSchema schema = new TableSchema(
      tableName: 'PersonView',
      tableType: PersonView,
      logChanges: true,
      isView: true,
      cacheValues: false,
      createScript: '''
''',
      superSchema: $Person.schema,
      fields: {
          'occupationName': occupationName,
          'branchName': branchName
      });
}

class PersonView extends Person {
  TableSchema get $schema => $PersonView.schema;
  String get occupationName => getProperty('occupationName');
  set occupationName (String value) => setProperty('occupationName',value);
  String get branchName => getProperty('branchName');
  set branchName (String value) => setProperty('branchName',value);
}

class $Person {
  static Field<String> get firstName =>
      const Field<String>(id: 'firstName',label: '',title: '',
          parentTable: null,parentField: '',staticValue: '',
          defaultValue: '',
          type: String,logChanges: true, foreignKey: false,externalKey: false,width: 0,tootltipsOnContent: false);
  static Field<String> get lastName =>
      const Field<String>(id: 'lastName',label: '',title: '',
          parentTable: null,parentField: '',staticValue: '',
          defaultValue: '',
          type: String,logChanges: true, foreignKey: false,externalKey: false,width: 0,tootltipsOnContent: false);
  static Field<int> get father =>
      const Field<int>(id: 'father',label: '',title: '',
          parentTable: null,parentField: '',staticValue: '',
          defaultValue: null,
          type: Person,logChanges: true, foreignKey: true,externalKey: false,width: 0,tootltipsOnContent: false);
  static Field<int> get mother =>
      const Field<int>(id: 'mother',label: '',title: '',
          parentTable: null,parentField: '',staticValue: '',
          defaultValue: null,
          type: Person,logChanges: true, foreignKey: true,externalKey: false,width: 0,tootltipsOnContent: false);
  static Field<int> get occupation =>
      const Field<int>(id: 'occupation',label: '',title: '',
          parentTable: null,parentField: '',staticValue: '',
          defaultValue: null,
          type: Occupation,logChanges: true, foreignKey: true,externalKey: false,width: 0,tootltipsOnContent: false);
 static TableSchema schema = new TableSchema(
      tableName: 'Person',
      tableType: Person,
      logChanges: true,
      isView: false,
      cacheValues: true,
      createScript: '''
''',
      superSchema: $PersistentObject.schema,
      fields: {
          'firstName': firstName,
          'lastName': lastName,
          'father': father,
          'mother': mother,
          'occupation': occupation
      });
}

class Person extends PersistentObject {
  TableSchema get $schema => $Person.schema;
  String get firstName => getProperty('firstName');
  set firstName (String value) => setProperty('firstName',value);
  String get lastName => getProperty('lastName');
  set lastName (String value) => setProperty('lastName',value);
  Person get father => getLinkedObject('father', Person);
  set father(Person value) => setLinkedObject('father', value);
  Person get mother => getLinkedObject('mother', Person);
  set mother(Person value) => setLinkedObject('mother', value);
  Occupation get occupation => getLinkedObject('occupation', Occupation);
  set occupation(Occupation value) => setLinkedObject('occupation', value);
}

class $Author {
  static Field<String> get name =>
      const Field<String>(id: 'name',label: '',title: '',
          parentTable: null,parentField: '',staticValue: '',
          defaultValue: '',
          type: String,logChanges: true, foreignKey: false,externalKey: false,width: 0,tootltipsOnContent: false);
  static Field<String> get email =>
      const Field<String>(id: 'email',label: '',title: '',
          parentTable: null,parentField: '',staticValue: '',
          defaultValue: '',
          type: String,logChanges: true, foreignKey: false,externalKey: false,width: 0,tootltipsOnContent: false);
  static Field<int> get age =>
      const Field<int>(id: 'age',label: '',title: '',
          parentTable: null,parentField: '',staticValue: '',
          defaultValue: 0,
          type: int,logChanges: true, foreignKey: false,externalKey: false,width: 0,tootltipsOnContent: false);
 static TableSchema schema = new TableSchema(
      tableName: 'Author',
      tableType: Author,
      logChanges: true,
      isView: false,
      cacheValues: false,
      createScript: '''
''',
      superSchema: $PersistentObject.schema,
      fields: {
          'name': name,
          'email': email,
          'age': age
      });
}

class Author extends PersistentObject {
  TableSchema get $schema => $Author.schema;
  String get name => getProperty('name');
  set name (String value) => setProperty('name',value);
  String get email => getProperty('email');
  set email (String value) => setProperty('email',value);
  int get age => getProperty('age');
  set age (int value) => setProperty('age',value);
}

registerClasses(Objectory objectoryParam) {
  objectoryParam.registerClass(Occupation,()=>new Occupation(),()=>new List<Occupation>(), {'branch': Branch});
  objectoryParam.registerClass(User,()=>new User(),()=>new List<User>(), {});
  objectoryParam.registerClass(Branch,()=>new Branch(),()=>new List<Branch>(), {});
  objectoryParam.registerClass(PersonView,()=>new PersonView(),()=>new List<PersonView>(), {});
  objectoryParam.registerClass(Person,()=>new Person(),()=>new List<Person>(), {'father': Person, 'mother': Person, 'occupation': Occupation});
  objectoryParam.registerClass(Author,()=>new Author(),()=>new List<Author>(), {});
}
