library schema_generator;

import 'dart:mirrors';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'field.dart' as schema;

class Field {
  final String label;
  final String title;
  final bool logChanges;
  final bool externalKey;
  const Field(
      {this.label: '',
      this.title: '',
      this.logChanges: true,
      this.externalKey: false});
}

class Table {
  final bool logChanges;
  final bool isView;
  final bool cacheValues;
  final String createScript;
  const Table({this.logChanges: true, this.isView: false, this.createScript: '', this.cacheValues: false});
}

///<-- Metadata

/// --> Metadata

class PropertyType {
  final _value;
  const PropertyType._internal(this._value);
  String toString() => 'PropertyType.$_value';
  static const PERSISTENT_OBJECT =
      const PropertyType._internal('PERSISTENT_OBJECT');
  static const PERSISTENT_LIST =
      const PropertyType._internal('PERSISTENT_LIST');
  static const SIMPLE = const PropertyType._internal('SIMPLE');
}

class ModelGenerator {
  static const HEADER = '''
/// Warning! That file is generated. Do not edit it manually
part of domain_model;

''';
  Symbol libraryName;
  List<ClassGenerator> classGenerators = new List<ClassGenerator>();
  Map<Type, ClassMirror> classMirrors = new Map<Type, ClassMirror>();
  List<Type> _classesOrdered = [];
  final Map<Type, List> _linkedTypes = new Map<Type, List>();
  ModelGenerator(this.libraryName);
  StringBuffer output = new StringBuffer();
  init() {
    var lib = currentMirrorSystem().findLibrary(libraryName);
    lib.declarations.forEach((sym, dm) {
      if (dm is ClassMirror) {
        _classesOrdered.add(dm.reflectedType);
        classMirrors[dm.reflectedType] = dm;
      }
    });
  }

  generateTo(String outFileName) {
    init();
    processAll();
    generateOutput();
    saveOuput(outFileName);
  }

  void generateOutput(
      {bool header: true,
      bool persistentClasses: true,
      bool schemaClasses: false,
      bool register: true}) {
    if (header) {
      output.write(HEADER);
    }
    classGenerators.forEach((cls) {
      generateOuputForTableSchema(cls);
      if (persistentClasses) {
        generateOuputForClass(cls);
      }
    });
    if (register) {
      output.write('registerClasses(Objectory objectoryParam) {\n');
      for (Type cls in _classesOrdered) {
        var linkedTypeMap = {};
        for (List each in _linkedTypes[cls]) {
          linkedTypeMap["'${each.first}'"] = each.last;
        }

        output.write(
            '  objectoryParam.registerClass($cls,()=>new $cls(),()=>new List<$cls>(), $linkedTypeMap);\n');
      }
      output.write('}\n');
    }
  }

  void saveOuput(String fileName) {
    if (path.isRelative(fileName)) {
      var targetDir = path.dirname(path.fromUri(Platform.script));
      fileName = path.join(targetDir, path.basename(fileName));
    }
    new File(fileName).writeAsStringSync(output.toString());
    print('Created file: $fileName');
  }

  void generateOuputForClass(ClassGenerator classGenerator) {
    output.write(
        'class ${classGenerator.type} extends ${classGenerator.superClass} {\n');
    output.writeln(
        "  TableSchema get \$schema => \$${classGenerator.type}.schema;");
    classGenerator.properties.forEach(generateOuputForProperty);
    _linkedTypes[classGenerator.type] = classGenerator.properties
        .where((PropertyGenerator p) =>
            p.propertyType == PropertyType.PERSISTENT_OBJECT)
        .map((PropertyGenerator p) => [p.name, p.type])
        .toList();
    output.write('}\n\n');
  }

  void generateOuputForProperty(PropertyGenerator propertyGenerator) {
    //output.write(propertyGenerator.commentLine);
    if (propertyGenerator.propertyType == PropertyType.SIMPLE) {
      output
          .write('  ${propertyGenerator.type} get ${propertyGenerator.name} => '
              "getProperty('${propertyGenerator.name}');\n");
      output.write(
          '  set ${propertyGenerator.name} (${propertyGenerator.type} value) => '
          "setProperty('${propertyGenerator.name}',value);\n");
    }
    if (propertyGenerator.propertyType == PropertyType.PERSISTENT_OBJECT) {
      output.write(
          '  ${propertyGenerator.type} get ${propertyGenerator.name} => '
          "getLinkedObject('${propertyGenerator.name}', ${propertyGenerator.type});\n");
      String capitalized =
          propertyGenerator.name.substring(0, 1).toUpperCase() +
              propertyGenerator.name.substring(1);
      output.write('  set${capitalized}Id(int value) => '
          "setForeignKey('${propertyGenerator.name}',value);\n");
    }
    if (propertyGenerator.propertyType == PropertyType.PERSISTENT_LIST) {
      output.write(
          '  ${propertyGenerator.type} get ${propertyGenerator.name} => '
          "getPersistentList(${propertyGenerator.listElementType}.value('${propertyGenerator.name}'));\n");
    }
  }

  void generateOuputForTableSchema(ClassGenerator classGenerator) {
    output.write('class \$${classGenerator.type} {\n');
    List<PropertyGenerator> allProperties = [];
//      schema.Fields.id,
//      schema.Fields.deleted,
//      schema.Fields.modifiedDate,
//      schema.Fields.modifiedTime
//    ].map((schema.Field fld) {
//      Field metaField = new Field(label: fld.label, title: fld.title);
//      return new PropertyGenerator()
//        ..name = fld.id
//        ..type = fld.type
//        ..field = metaField
//        ..propertyType = PropertyType.SIMPLE;
//    }).toList();
    allProperties.addAll(classGenerator.properties);

    allProperties.forEach((propertyGenerator) {
      Type fieldType =
          propertyGenerator.propertyType == PropertyType.PERSISTENT_OBJECT
              ? int
              : propertyGenerator.type;
      output.write(
          "  static Field<$fieldType> get ${propertyGenerator.name} =>\n");
      output.write(
          "      const Field<$fieldType>(id: '${propertyGenerator.name}',label: '${propertyGenerator.field.label}',title: '${propertyGenerator.field.title}',\n");
      output.write(
          "          type: ${propertyGenerator.type},logChanges: ${propertyGenerator.field.logChanges}, foreignKey: ${propertyGenerator.propertyType == PropertyType.PERSISTENT_OBJECT},externalKey: ${propertyGenerator.field.externalKey});\n");
    });
    var fields = classGenerator.properties
        .map((PropertyGenerator e) => "          '${e.name}': ${e.name}")
        .toList()
        .join(',\n');
    output.writeln(" static TableSchema schema = new TableSchema(");
    output.writeln("      tableName: '${classGenerator.type}',");
    output.writeln("      logChanges: ${classGenerator.table.logChanges},");
    output.writeln("      isView: ${classGenerator.table.isView},");
    output.writeln("      cacheValues: ${classGenerator.table.cacheValues},");
    output.writeln("      createScript: '''\n${classGenerator.table.createScript}''',");
    output.writeln("      superSchema: \$${classGenerator.superClass}.schema,");
    output.writeln('      fields: {\n$fields\n      });');
    output.writeln('}\n');
  }

  generateFieldDescriptors(List<PropertyGenerator> simpleProperties) {}

  processAll() {
    _classesOrdered.forEach(processClass);
  }

  processClass(Type classType) {
    var classMirror = classMirrors[classType];
    var generatorClass = new ClassGenerator();
    classGenerators.add(generatorClass);
    generatorClass.type = classMirror.reflectedType;
    if (!classMirror.metadata.isEmpty) {
      classMirror.metadata.where((m) => m.reflectee is Table).forEach((m) {
        generatorClass.table = m.reflectee as Table;
      });
    } else {
      generatorClass.table = new Table();
    }
    generatorClass.superClass = classMirror.superclass.reflectedType.toString();
    if (generatorClass.superClass == 'Object') {
      generatorClass.superClass = 'PersistentObject';
    }
    classMirror.declarations.forEach((Symbol name, DeclarationMirror vm) =>
        processProperty(generatorClass, name, vm));
  }

  processProperty(ClassGenerator classGenerator, name, DeclarationMirror vm) {
    if (vm is VariableMirror) {
      PropertyGenerator property = new PropertyGenerator();
      classGenerator.properties.add(property);
      property.name = MirrorSystem.getName(name);
      property.processVariableMirror(vm);
    }
  }
}

class PropertyGenerator {
//  PropertyDescriptor descriptor;
  String name;
  Field field;

  Type type;
  Type listElementType;
  PropertyType propertyType = PropertyType.SIMPLE;
  String toString() => 'PropertyGenerator($name,$type,$propertyType)';
  String get commentLine => '  // $type $name\n';

  processVariableMirror(VariableMirror vm) {
    vm.metadata.where((m) => m.reflectee is Field).forEach((m) {
      field = m.reflectee as Field;
    });
    if (field == null) {
      field = const Field();
    }
    Type t = vm.type.reflectedType;
    type = t;
    if (t == int ||
        t == double ||
        t == String ||
        t == DateTime ||
        t == bool ||
        t == num) {
      return;
    }
    propertyType = PropertyType.PERSISTENT_OBJECT;
  }
}

class ClassGenerator {
  Table table;
  Type type;
  String superClass;
  List<PropertyGenerator> properties = new List<PropertyGenerator>();
  String toString() => 'ClassGenerator($properties)';
}
