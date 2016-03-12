library schema_generator;

import 'dart:mirrors';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:objectory/src/persistent_object.dart';

///<-- Metadata
class Embedded {
  const Embedded();
}

const embedded = const Embedded();

class SimpleProperty {
  const SimpleProperty();
}

const simpleProperty = const SimpleProperty();

class AsClass {
  final String value;
  const AsClass(this.value);
}

class Label {
  final String value;
  const Label(this.value);
}

const label = const Label('TEST');

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
      bool schemaClasses: true,
      bool register: true}) {
    if (header) {
      output.write(HEADER);
    }
    classGenerators.forEach((cls) {
      if (schemaClasses) {
        generateOuputForSchemaClass(cls);
      }
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
    var embeddedModifier = classGenerator.isEmbedded ? 'Embedded' : '';
    output.write(
        'class ${classGenerator.persistentClassName} extends ${embeddedModifier}PersistentObject {\n');
    output.writeln(
        "  String get collectionName => '${classGenerator.persistentClassName}';");
    if (!classGenerator.isEmbedded) {
      output.writeln("  List<String> get \$allFields => \$${classGenerator
              .persistentClassName}.allFields;");
    }
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
      if (isEmbeddedPersistent(propertyGenerator)) {
        output.write(
            '  ${propertyGenerator.type} get ${propertyGenerator.name} => '
            "getEmbeddedObject(${propertyGenerator.type},'${propertyGenerator.name}');\n");
      } else {
        output.write(
            '  ${propertyGenerator.type} get ${propertyGenerator.name} => '
            "getLinkedObject('${propertyGenerator.name}', ${propertyGenerator.type});\n");
        output.write(
            '  set ${propertyGenerator.name} (${propertyGenerator.type} value) => '
            "setLinkedObject('${propertyGenerator.name}',value);\n");
      }
    }
    if (propertyGenerator.propertyType == PropertyType.PERSISTENT_LIST) {
      output.write(
          '  ${propertyGenerator.type} get ${propertyGenerator.name} => '
          "getPersistentList(${propertyGenerator.listElementType},'${propertyGenerator.name}');\n");
    }
  }

  void generateOuputForSchemaClass(ClassGenerator classGenerator) {
    output.write('class \$${classGenerator.type} {\n');
    var staticModifier = 'static ';
    var propertyNamePrefix = "'";
    if (classGenerator.isEmbedded) {
      staticModifier = '';
      propertyNamePrefix = "_pathToMe + '.";
      output.write("  String _pathToMe;\n");
      output.write("  \$${classGenerator.type}(this._pathToMe);\n");
    }
    classGenerator.properties.forEach((propertyGenerator) {
      if (isEmbeddedPersistent(propertyGenerator)) {
        var propName = classGenerator.isEmbedded
            ? "_pathToMe + '.${propertyGenerator.name}'"
            : "'${propertyGenerator.name}'";
        output.write(
            "  ${staticModifier}final \$${propertyGenerator.type} ${propertyGenerator.name} = new \$${propertyGenerator.type}($propName);\n");
      } else {
        output.write(
            "  ${staticModifier}String get ${propertyGenerator.name} => ${propertyNamePrefix}${propertyGenerator.name}';\n");
      }
    });
    var simpleProperties = classGenerator.properties
        .where((e) => !isEmbeddedPersistent(e))
        .map((PropertyGenerator e) => e.name)
        .toList()
        .toString();
    var embeddedProperties = classGenerator.properties
        .where((e) => isEmbeddedPersistent(e))
        .map((PropertyGenerator e) => e.name)
        .toList();
    var chunkForEmbeddedProperies = '';
    if (embeddedProperties.isNotEmpty) {
      chunkForEmbeddedProperies =
          "..addAll($embeddedProperties.expand((e)=>e.allFields))";
    }
    if (!classGenerator.isEmbedded) {
//      output.write(
//          "  List<String> get allFields => ${simpleProperties}${chunkForEmbeddedProperies};\n");
//    } else {
      output.write(
          "  static final List<String> allFields = $simpleProperties${chunkForEmbeddedProperies};\n");
    }

    var fields = classGenerator.properties
        .where((e) => e.propertyType == PropertyType.SIMPLE)
        .toList();
    generateFieldDescriptors(fields);
    output.write('}\n\n');
  }

  generateFieldDescriptors(List<PropertyGenerator> simpleProperties) {
    output.writeln("  static final List<PropertyDescriptor> simpleFields = [");
    var comma = '';
    for (var property in simpleProperties) {
      var label = property.label == null ? property.name : property.label;
      output.writeln(
          "    ${comma}const PropertyDescriptor('${property.name}', PropertyType.${property.type}, '$label')");
      comma = ',';
    }
    output.writeln("  ];");
  }

  bool isEmbeddedPersistent(PropertyGenerator propertyGenerator) {
    if (propertyGenerator.propertyType != PropertyType.PERSISTENT_OBJECT) {
      return false;
    }
    ClassGenerator targetClass = classGenerators.firstWhere(
        (cg) => cg.type == propertyGenerator.type,
        orElse: () => null);
    if (targetClass == null) {
      throw new StateError(
          'Not found class ${propertyGenerator.type} in prototype schema');
    }
    return targetClass.isEmbedded;
  }

  processAll() {
    _classesOrdered.forEach(processClass);
  }

  processClass(Type classType) {
    var classMirror = classMirrors[classType];
    var generatorClass = new ClassGenerator();
    classGenerators.add(generatorClass);
    generatorClass.type = classMirror.reflectedType;
    if (!classMirror.metadata.isEmpty) {
      generatorClass.isEmbedded =
          classMirror.metadata.any((m) => m.type.reflectedType == Embedded);
      var asClassMirror = classMirror.metadata.firstWhere(
          (m) => m.type.reflectedType == AsClass,
          orElse: () => null);
      if (asClassMirror != null) {
        generatorClass.asClass = asClassMirror.getField(#value).reflectee;
      }
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
  String label;
  Type type;
  Type listElementType;
  PropertyType propertyType = PropertyType.SIMPLE;
  String toString() => 'PropertyGenerator($name,$type,$propertyType)';
  String get commentLine => '  // $type $name\n';
  processVariableMirror(VariableMirror vm) {
    vm.metadata.where((m) => m.reflectee is Label).forEach((m) {
      var memberLabel = m.reflectee as Label;
      label = memberLabel.value;
    });

    Type t = vm.type.reflectedType;
    type = t;
    if (t == int || t == double || t == String || t == DateTime || t == bool) {
      return;
    }

    if (vm.metadata.any((m) => m.type.reflectedType == SimpleProperty)) {
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
  Type type;
  bool isEmbedded = false;
  String asClass;
  String get persistentClassName => asClass == null ? '$type' : asClass;
  List<PropertyGenerator> properties = new List<PropertyGenerator>();
  String toString() => 'ClassGenerator(isEmbedded=$isEmbedded,$properties)';
}
