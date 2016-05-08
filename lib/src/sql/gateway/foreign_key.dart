part of gateway;

class ForeignKey {
  final String references;
  final String column;
  String onDeleteResponse;
  String onUpdateResponse;

  ForeignKey(String this.references, String this.column);

  ForeignKey onDelete(String response) {
    onDeleteResponse = response;
    return this;
  }

  ForeignKey onUpdate(String response) {
    onUpdateResponse = response;
    return this;
  }
}
