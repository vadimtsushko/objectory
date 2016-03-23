library blog_example;
import 'package:objectory/objectory.dart';
import 'package:objectory/src/http_client_io.dart';
import '../domain_model/domain_model.dart';

main() async {
  objectory = new ObjectoryHttpImpl('http://localhost:7777', registerClasses, dropCollectionsOnStartup: true );
  var authors = new Map<String, Author>();
  var users = new Map<String, User>();
  await objectory.initDomainModel();

  print(
      "===================================================================================");
  print(">> Adding Authors");
  var author = new Author();
  author.name = 'William Shakespeare';
  author.email = 'william@shakespeare.com';
  author.age = 587;
  await author.save();
  author = new Author();
  author.name = 'Jorge Luis Borges';
  author.email = 'jorge@borges.com';
  author.age = 123;
  await author.save();
  var auths = await objectory[Author].find(where.sortBy($Author.age));
  print(
      "===================================================================================");
  print(">> Authors ordered by age ascending");
  for (var auth in auths) {
    authors[auth.name] = auth;
    print("[${auth.name}]:[${auth.email}]:[${auth.age}]");
  }
  print(
      "===================================================================================");
  print(">> Adding Users");
  var user = new User();
  user.name = 'John Doe';
  user.login = 'jdoe';
  user.email = 'john@doe.com';
  await user.save();
  user = new User();
  user.name = 'Lucy Smith';
  user.login = 'lsmith';
  user.email = 'lucy@smith.com';
  await user.save();
  var usrs = await objectory[User].find(where.sortBy($User.login));
  print(
      "===================================================================================");
  print(">> >> Users ordered by login ascending");
  for (var user in usrs) {
    print("[${user.login}]:[${user.name}]:[${user.email}]");
    users[user.login] = user;
  }
  print(
      "===================================================================================");
  print(">> Adding articles");
  var article = new Article();
  article.title = 'Caminando por Buenos Aires';
  article.body = 'Las callecitas de Buenos Aires tienen ese no se que...';
  article.author = authors['Jorge Luis Borges'];
  var comment = new BlogComment();
  comment.date = new DateTime.fromMillisecondsSinceEpoch(
      new DateTime.now().millisecondsSinceEpoch - 780987497);
  comment.body = "Well, you may do better...";
  comment.user = users['lsmith'];
  article.comments.add(comment);
  await article.save();
  comment = new BlogComment();
  comment.date = new DateTime.fromMillisecondsSinceEpoch(
      new DateTime.now().millisecondsSinceEpoch - 90987497);
  comment.body = "I love this article!";
  comment.user = users['jdoe'];
  article.comments.add(comment);
  await article.save();

  article = new Article();
  article.title = 'I must have seen thy face before';
  article.body = 'Thine eyes call me in a new way';
  article.author = authors['William Shakespeare'];
  comment = new BlogComment();
  comment.date = new DateTime.fromMillisecondsSinceEpoch(
      new DateTime.now().millisecondsSinceEpoch - 20987497);
  comment.body = "great article!";
  comment.user = users['jdoe'];
  article.comments.add(comment);
  await article.save();
  var articles = await objectory[Article].find();
  print(
      "===================================================================================");
  print(">> Printing articles");
  for (var article in articles) {
    await printArticle(article);
  }
  await objectory.close();
}

printArticle(article) async {
  await article.fetchLinks();
  print("${article.author.name}:${article.title}:${article.body}");
  for (var comment in article.comments) {
    print("     ${comment.date}:${comment.user.name}: ${comment.body}");
  }
}
