class TerminalSnippet {
  const TerminalSnippet({
    required this.id,
    required this.label,
    required this.text,
    this.hidden = false,
    this.submit = true,
  });

  final String id;
  final String label;
  final String text;
  final bool hidden;
  final bool submit;

  bool get isValid => id.isNotEmpty && label.trim().isNotEmpty;

  TerminalSnippet copyWith({
    String? id,
    String? label,
    String? text,
    bool? hidden,
    bool? submit,
  }) {
    return TerminalSnippet(
      id: id ?? this.id,
      label: label ?? this.label,
      text: text ?? this.text,
      hidden: hidden ?? this.hidden,
      submit: submit ?? this.submit,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
      'text': text,
      'hidden': hidden,
      'submit': submit,
    };
  }

  static TerminalSnippet? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final id = json['id'];
    final label = json['label'];
    final text = json['text'];
    if (id is! String || label is! String || text is! String) {
      return null;
    }
    final snippet = TerminalSnippet(
      id: id,
      label: label,
      text: text,
      hidden: json['hidden'] == true,
      submit: json['submit'] != false,
    );
    return snippet.isValid ? snippet : null;
  }

  @override
  bool operator ==(Object other) {
    return other is TerminalSnippet &&
        other.id == id &&
        other.label == label &&
        other.text == text &&
        other.hidden == hidden &&
        other.submit == submit;
  }

  @override
  int get hashCode => Object.hash(id, label, text, hidden, submit);
}
