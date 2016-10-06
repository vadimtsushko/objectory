library schema_generator;

import 'dart:mirrors';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:objectory/src/persistent_object.dart';
//import 'package:objectory/src/field.dart';
//
//export 'package:objectory/src/field.dart';


class Field {
  final String label;
  final String title;
  final bool logChanges;
  const Field({this.label: '', this.title: '', this.logChanges: true});
}

class Table {
  final bool logChanges;
  const Table({this.logChanges: true});
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
      output.write('registerClasses() {\n');
      for (Type cls in _classesOrdered) {
        var linkedTypeMap = {};
        for (List each in _linkedTypes[cls]) {
          linkedTypeMap["'${each.first}'"] = each.last;
        }

        output.write(
            '  objectory.registerClass($cls,()=>new $cls(),()=>new List<$cls>(), $linkedTypeMap);\n');
      }
      output.write('}\n');
    }

//    output.write('\n\n /// Postgresql DB Schema \n');
//    output.write('/*\n');
//    classGenerators.forEach((cls) {
//      generateOuputForTable(cls);
//    });
//    output.write('*/\n');
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
        'class ${classGenerator.persistentClassName} extends PersistentObject {\n');
    output.writeln(
        "  TableSchema get \$schema => \$${classGenerator.persistentClassName}.schema;");
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
      output.write(
          '  set ${propertyGenerator.name} (${propertyGenerator.type} value) => '
          "setLinkedObject('${propertyGenerator.name}',value);\n");
    }
    if (propertyGenerator.propertyType == PropertyType.PERSISTENT_LIST) {
      output.write(
          '  ${propertyGenerator.type} get ${propertyGenerator.name} => '
          "getPersistentList(${propertyGenerator.listElementType},'${propertyGenerator.name}');\n");
    }
  }

//  void generateOuputForTableColumn(PropertyGenerator propertyGenerator) {
//    //output.write(propertyGenerator.commentLine);
//    if (propertyGenerator.propertyType == PropertyType.SIMPLE) {
//      output.write('  "${propertyGenerator.name}" ');
//      if (propertyGenerator.type == String) {
//        output.write('CHARACTER VARYING (255) NOT NULL DEFAULT '',\n');
//      } else if (propertyGenerator.type == bool) {
//        output.write('BOOLEAN NOT NULL DEFAULT FALSE,\n');
//      } else if (propertyGenerator.type == DateTime) {
//        output.write('timestamp,\n');
//      } else if (propertyGenerator.type == int) {
//        output.write('integer,\n');
//      } else if (propertyGenerator.type == num) {
//        output.write('double precision,\n');
//      } else {
//        throw new Exception('Not supported type');
//      }
//    } else if (propertyGenerator.propertyType ==
//        PropertyType.PERSISTENT_OBJECT) {
//      output.write('  "${propertyGenerator.name}" character varying(255),\n');
//    } else {
//      throw new Exception(
//          'Not supported type: ${PropertyType.PERSISTENT_LIST}');
//    }
//  }

  void generateOuputForTableSchema(ClassGenerator classGenerator) {
    output.write('class \$${classGenerator.type} {\n');
    classGenerator.properties.forEach((propertyGenerator) {
      output.write("  static Field get ${propertyGenerator.name} =>\n");
      output.write(
          "      const Field(id: '${propertyGenerator.name}',label: '${propertyGenerator.field.label}',title: '${propertyGenerator.field.title}',\n");
      output.write(
          "          type: ${propertyGenerator.type},logChanges: ${propertyGenerator.field.logChanges}, foreignKey: ${propertyGenerator.propertyType == PropertyType.PERSISTENT_OBJECT});\n");
    });
    var fields = classGenerator.properties
        .map((PropertyGenerator e) => "'${e.name}': ${e.name}")
        .toList()
        .join(',');
    output.writeln(" static TableSchema schema = new TableSchema(");
    output.writeln("      tableName: '${classGenerator.type}',");
    output.writeln("      logChanges: ${classGenerator.table.logChanges},");
    output.writeln('      fields: {$fields});');
    output.writeln('}\n');
  }

  generateFieldDescriptors(List<PropertyGenerator> simpleProperties) {
//    output.writeln("  static final List<PropertyDescriptor> simpleFields = [");
//    var comma = '';
//    for (var property in simpleProperties) {
//      var label = property.label == null ? property.name : property.label;
//      output.writeln(
//          "    ${comma}const PropertyDescriptor('${property.name}', PropertyType.${property.type}, '$label')");
//      comma = ',';
//    }
//    output.writeln("  ];");
  }

//  bool isEmbeddedPersistent(PropertyGenerator propertyGenerator) {
//    if (propertyGenerator.propertyType != PropertyType.PERSISTENT_OBJECT) {
//      return false;
//    }
//    ClassGenerator targetClass = classGenerators.firstWhere(
//        (cg) => cg.type == propertyGenerator.type,
//        orElse: () => null);
//    if (targetClass == null) {
//      throw new StateError(
//          'Not found class ${propertyGenerator.type} in prototype schema');
//    }
//    return targetClass.isEmbedded;
//  }

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
  PropertyDescriptor descriptor;
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
    Type t = vm.type.reflectedType;
    type = t;
    if (t == int || t == double || t == String || t == DateTime || t == bool) {
      return;
    }

    if (vm.type.simpleName == #List) {
      propertyType = PropertyType.PERSISTENT_LIST;
      if (vm.type.typeArguments.length != 1) {
        throw new StateError('List property $name should use type argument');
      }
      ;
      listElementType = vm.type.typeArguments.first.reflectedType;
      return;
    }
    propertyType = PropertyType.PERSISTENT_OBJECT;
  }
}

class ClassGenerator {
  Table table;
  Type type;
  String asClass;
  String get persistentClassName => asClass == null ? '$type' : asClass;
  List<PropertyGenerator> properties = new List<PropertyGenerator>();
  String toString() => 'ClassGenerator($properties)';
}
