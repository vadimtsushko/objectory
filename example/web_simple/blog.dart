library blog_example;
import 'package:objectory/objectory_browser.dart';
import '../domain_model/domain_model.dart';
import 'dart:html' as html;
const DefaultUri = '127.0.0.1:8181';
main(){
  objectory = new ObjectoryWebsocketBrowserImpl(DefaultUri,registerClasses,true);
  var authors = new Map<String,Author>();
  var users = new Map<String,User>();
  objectory.initDomainModel().then((_) {
    print("===================================================================================");
    print(">> Adding Authors");
    var author = new Author();
    author.name = 'William Shakespeare';
    author.email = 'william@shakespeare.com';
    author.age = 587;
    author.save();
    author = new Author();
    author.name = 'Jorge Luis Borges';
    author.email = 'jorge@borges.com';
    author.age = 123;
    author.save();
    return objectory[Author].find(where.sortBy('age'));
  }).then((auths){
    print("===================================================================================");
    print(">> Authors ordered by age ascending");
    for (var auth in auths) {
      authors[auth.name] = auth;
      print("[${auth.name}]:[${auth.email}]:[${auth.age}]");
    }
    print("===================================================================================");
    print(">> Adding Users");
    var user = new User();
    user.name = 'John Doe';
    user.login = 'jdoe';
    user.email = 'john@doe.com';
    user.save();
    user = new User();
    user.name = 'Lucy Smith';
    user.login = 'lsmith';
    user.email = 'lucy@smith.com';
    user.save();
    return objectory[User].find(where.sortBy('login'));
  }).then((usrs){
    print("===================================================================================");
    print(">> >> Users ordered by login ascending");
    for (var user in usrs) {
      print("[${user.login}]:[${user.name}]:[${user.email}]");
      users[user.login] = user;
    }
    print("===================================================================================");
    print(">> Adding articles");
    var article = new Article();
    article.title = 'Caminando por Buenos Aires';
    article.body = 'Las callecitas de Buenos Aires tienen ese no se que...';
    article.author = authors['Jorge Luis Borges'];
    var comment = new BlogComment();
    comment.date = new DateTime.fromMillisecondsSinceEpoch(new DateTime.now().millisecondsSinceEpoch - 780987497);
    comment.body = "Well, you may do better...";
    comment.user = users['lsmith'];
    article.comments.add(comment);
    objectory.save(article);
    comment = new BlogComment();
    comment.date = new DateTime.fromMillisecondsSinceEpoch(new DateTime.now().millisecondsSinceEpoch - 90987497);
    comment.body = "I love this article!";
    comment.user = users['jdoe'];
    article.comments.add(comment);
    article.save();

    article = new Article();
    article.title = 'I must have seen thy face before';
    article.body = 'Thine eyes call me in a new way';
    article.author = authors['William Shakespeare'];
    comment = new BlogComment();
    comment.date = new DateTime.fromMillisecondsSinceEpoch(new DateTime.now().millisecondsSinceEpoch - 20987497);
    comment.body = "great article!";
    comment.user = users['jdoe'];
    article.comments.add(comment);
    article.save();
    return objectory[Article].find();
  }).then((articles){
    return Future.wait(articles.map((article) => printArticle(article)));
  }).then((_) {
   objectory.close();
  });
}

print(message) {
  var textElement = html.querySelector('#text');
  textElement.innerHtml = '${textElement.innerHtml}<br>\n${message.toString()}';
}

Future printArticle(article) {
  var completer = new Completer();
  article.fetchLinks().then((__) {
    print("${article.author.name}:&nbsp;&nbsp;${article.title}:&nbsp;&nbsp;${article.body}");
    for (var comment in article.comments) {
      print("&nbsp;&nbsp;&nbsp;${comment.date}:&nbsp;&nbsp;${comment.user.name}:&nbsp;&nbsp;${comment.body}");
    }
    completer.complete(true);
  });
  return completer.future;
}
