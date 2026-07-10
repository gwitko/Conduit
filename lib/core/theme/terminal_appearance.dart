enum TerminalFontOption { systemMonospace, atkynsonNerdFont }

const terminalFontSizeDefault = 13.5;
const terminalFontSizeMin = 4.0;
const terminalFontSizeMax = 30.0;
const terminalFontSizeStep = 0.5;
const terminalFontSizeDivisions = 52;

double clampTerminalFontSize(num size) {
  return size.clamp(terminalFontSizeMin, terminalFontSizeMax).toDouble();
}

double normalizeTerminalFontSize(double size) {
  final normalized =
      (size / terminalFontSizeStep).round() * terminalFontSizeStep;
  return clampTerminalFontSize(normalized);
}

extension TerminalFontOptionDetails on TerminalFontOption {
  String get label => switch (this) {
    TerminalFontOption.systemMonospace => 'System mono',
    TerminalFontOption.atkynsonNerdFont => 'Nerd Font',
  };

  String get fontFamily => switch (this) {
    TerminalFontOption.systemMonospace => 'monospace',
    TerminalFontOption.atkynsonNerdFont => 'AtkynsonMonoNerdFontMono',
  };
}

enum TerminalKeyboardAction {
  escape,
  control,
  alt,
  tab,
  fullscreen,
  arrowUp,
  arrowDown,
  arrowLeft,
  arrowRight,
  home,
  end,
  pageUp,
  pageDown,
  controlC,
  controlD,
  controlZ,
  controlL,
  colon,
  slash,
  pipe,
  dash,
  paste,
  functionKeys,
  tmuxPrefix,
  tmuxScrollback,
  tmuxMenu,
  snippets,
  compose,
}

enum TerminalKeyboardItemKind { builtIn, customText, customControl }

class TerminalKeyboardItem {
  const TerminalKeyboardItem({
    required this.id,
    required this.kind,
    required this.label,
    this.action,
    this.text,
    this.controlKey,
    this.submit = false,
  });

  const TerminalKeyboardItem.builtIn(TerminalKeyboardAction this.action)
    : id = '',
      kind = TerminalKeyboardItemKind.builtIn,
      label = '',
      text = null,
      controlKey = null,
      submit = false;

  final String id;
  final TerminalKeyboardItemKind kind;
  final String label;
  final TerminalKeyboardAction? action;
  final String? text;
  final String? controlKey;
  final bool submit;

  String get stableId {
    final action = this.action;
    if (kind == TerminalKeyboardItemKind.builtIn && action != null) {
      return 'builtIn:${action.name}';
    }
    return id;
  }

  String get displayLabel {
    final action = this.action;
    if (kind == TerminalKeyboardItemKind.builtIn && action != null) {
      return action.label;
    }
    return label;
  }

  @override
  bool operator ==(Object other) {
    return other is TerminalKeyboardItem &&
        other.id == id &&
        other.kind == kind &&
        other.label == label &&
        other.action == action &&
        other.text == text &&
        other.controlKey == controlKey &&
        other.submit == submit;
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, label, action, text, controlKey, submit);
}

const defaultTerminalKeyboardActions = [
  TerminalKeyboardAction.escape,
  TerminalKeyboardAction.control,
  TerminalKeyboardAction.alt,
  TerminalKeyboardAction.tab,
  TerminalKeyboardAction.arrowUp,
  TerminalKeyboardAction.arrowDown,
  TerminalKeyboardAction.arrowLeft,
  TerminalKeyboardAction.arrowRight,
  TerminalKeyboardAction.slash,
  TerminalKeyboardAction.dash,
  TerminalKeyboardAction.pipe,
  TerminalKeyboardAction.paste,
  TerminalKeyboardAction.controlC,
  TerminalKeyboardAction.controlD,
  TerminalKeyboardAction.controlZ,
  TerminalKeyboardAction.controlL,
  TerminalKeyboardAction.colon,
  TerminalKeyboardAction.home,
  TerminalKeyboardAction.end,
  TerminalKeyboardAction.pageUp,
  TerminalKeyboardAction.pageDown,
  TerminalKeyboardAction.functionKeys,
  TerminalKeyboardAction.tmuxPrefix,
  TerminalKeyboardAction.tmuxScrollback,
  TerminalKeyboardAction.tmuxMenu,
  TerminalKeyboardAction.snippets,
  TerminalKeyboardAction.fullscreen,
];

const legacyDefaultTerminalKeyboardActions = [
  TerminalKeyboardAction.escape,
  TerminalKeyboardAction.control,
  TerminalKeyboardAction.alt,
  TerminalKeyboardAction.tab,
  TerminalKeyboardAction.fullscreen,
  TerminalKeyboardAction.arrowUp,
  TerminalKeyboardAction.arrowDown,
  TerminalKeyboardAction.arrowLeft,
  TerminalKeyboardAction.arrowRight,
  TerminalKeyboardAction.home,
  TerminalKeyboardAction.end,
  TerminalKeyboardAction.pageUp,
  TerminalKeyboardAction.pageDown,
  TerminalKeyboardAction.controlC,
  TerminalKeyboardAction.controlD,
  TerminalKeyboardAction.controlZ,
  TerminalKeyboardAction.controlL,
  TerminalKeyboardAction.colon,
  TerminalKeyboardAction.slash,
  TerminalKeyboardAction.pipe,
  TerminalKeyboardAction.dash,
  TerminalKeyboardAction.paste,
  TerminalKeyboardAction.functionKeys,
];

const preTrackingTerminalKeyboardActionNames = <String>{
  'escape',
  'control',
  'alt',
  'tab',
  'fullscreen',
  'arrowUp',
  'arrowDown',
  'arrowLeft',
  'arrowRight',
  'home',
  'end',
  'pageUp',
  'pageDown',
  'controlC',
  'controlD',
  'controlZ',
  'controlL',
  'colon',
  'slash',
  'pipe',
  'dash',
  'paste',
  'functionKeys',
  'tmuxPrefix',
  'tmuxScrollback',
  'tmuxMenu',
  'compose',
};

const tmuxTerminalKeyboardActions = [
  TerminalKeyboardAction.tmuxPrefix,
  TerminalKeyboardAction.tmuxScrollback,
  TerminalKeyboardAction.tmuxMenu,
];

const defaultTerminalKeyboardItems = [
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.escape),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.control),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.alt),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.tab),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.arrowUp),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.arrowDown),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.arrowLeft),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.arrowRight),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.slash),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.dash),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.pipe),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.paste),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.controlC),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.controlD),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.controlZ),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.controlL),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.colon),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.home),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.end),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.pageUp),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.pageDown),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.functionKeys),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.tmuxPrefix),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.tmuxScrollback),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.tmuxMenu),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.snippets),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.fullscreen),
];

const tmuxTerminalKeyboardItems = [
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.tmuxPrefix),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.tmuxScrollback),
  TerminalKeyboardItem.builtIn(TerminalKeyboardAction.tmuxMenu),
];

const terminalKeyboardRowHeightDefault = 50.0;
const terminalKeyboardRowHeightMin = 40.0;
const terminalKeyboardRowHeightMax = 80.0;

double clampTerminalKeyboardRowHeight(double height) {
  return height.clamp(
    terminalKeyboardRowHeightMin,
    terminalKeyboardRowHeightMax,
  );
}

class TerminalKeyboardRow {
  const TerminalKeyboardRow({
    required this.items,
    this.height = terminalKeyboardRowHeightDefault,
  });

  final List<TerminalKeyboardItem> items;
  final double height;

  TerminalKeyboardRow copyWith({
    List<TerminalKeyboardItem>? items,
    double? height,
  }) {
    return TerminalKeyboardRow(
      items: items ?? this.items,
      height: height ?? this.height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! TerminalKeyboardRow ||
        other.height != height ||
        other.items.length != items.length) {
      return false;
    }
    for (var index = 0; index < items.length; index += 1) {
      if (other.items[index] != items[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(height, Object.hashAll(items));
}

const defaultTerminalKeyboardRows = [
  TerminalKeyboardRow(items: defaultTerminalKeyboardItems),
];

const terminalKeyboardControlKeys = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
];

extension TerminalKeyboardActionDetails on TerminalKeyboardAction {
  String get label => switch (this) {
    TerminalKeyboardAction.escape => 'Esc',
    TerminalKeyboardAction.control => 'Ctrl',
    TerminalKeyboardAction.alt => 'Alt',
    TerminalKeyboardAction.tab => 'Tab',
    TerminalKeyboardAction.fullscreen => 'Full',
    TerminalKeyboardAction.arrowUp => 'Up',
    TerminalKeyboardAction.arrowDown => 'Down',
    TerminalKeyboardAction.arrowLeft => 'Left',
    TerminalKeyboardAction.arrowRight => 'Right',
    TerminalKeyboardAction.home => 'Home',
    TerminalKeyboardAction.end => 'End',
    TerminalKeyboardAction.pageUp => 'PgUp',
    TerminalKeyboardAction.pageDown => 'PgDn',
    TerminalKeyboardAction.controlC => '^C',
    TerminalKeyboardAction.controlD => '^D',
    TerminalKeyboardAction.controlZ => '^Z',
    TerminalKeyboardAction.controlL => '^L',
    TerminalKeyboardAction.colon => ':',
    TerminalKeyboardAction.slash => '/',
    TerminalKeyboardAction.pipe => '|',
    TerminalKeyboardAction.dash => '-',
    TerminalKeyboardAction.paste => 'Paste',
    TerminalKeyboardAction.functionKeys => 'Fn',
    TerminalKeyboardAction.tmuxPrefix => 'Tmux',
    TerminalKeyboardAction.tmuxScrollback => 'Scroll',
    TerminalKeyboardAction.tmuxMenu => 'Tmux+',
    TerminalKeyboardAction.snippets => 'Snip',
    TerminalKeyboardAction.compose => 'Compose',
  };
}
