#library("objectory_mirror_requirements_test");
#import("domain_model.dart");
#import("dart:mirrors");
// Possibility to use mirrors currently blocked by lack of VariableMirror.type implementation
// Full support required: For example in class Article we have to reflect on comments as a List of Comment. 
//    class Article {
//      ...   
//      List<Comment> comments
//    }
//       

main() {
  var domainModelLib = currentMirrorSystem().libraries['domain_model'];  
  domainModelLib.classes.forEach((name,classMirror) {    
    if (classMirror.superinterfaces.length > 0 && classMirror.superinterfaces[0].simpleName == 'PersistentObject') {      
      print(classMirror.simpleName);
      classMirror.variables.forEach((name,field) {        
        print(" field $name ${field.simpleName} ${field.type}");
        if (field.type.simpleName == 'List') {
          var tv = field.type.typeVariables["E"];          
          print('       $tv');
          // last unimplemented feature:
          //print(tv.type);
          //print(field.type.typeArguments);          
        }
      });       
    }      
  });    
}