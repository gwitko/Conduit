import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/c.dart';
import 'package:re_highlight/languages/cmake.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/csharp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/diff.dart';
import 'package:re_highlight/languages/dockerfile.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/ini.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/less.dart';
import 'package:re_highlight/languages/lua.dart';
import 'package:re_highlight/languages/makefile.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/nginx.dart';
import 'package:re_highlight/languages/perl.dart';
import 'package:re_highlight/languages/php.dart';
import 'package:re_highlight/languages/plaintext.dart';
import 'package:re_highlight/languages/properties.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/r.dart';
import 'package:re_highlight/languages/ruby.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/scss.dart';
import 'package:re_highlight/languages/shell.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/re_highlight.dart';

/// Syntax mode for a file, chosen by extension (or well-known file name).
///
/// Returns the Re-Highlight language id plus its [Mode]; unknown files fall
/// back to plain text so the editor still works.
({String id, Mode mode}) codeLanguageForFile(String fileName) {
  final lower = fileName.toLowerCase();
  final byName = switch (lower) {
    'dockerfile' || 'containerfile' => (id: 'dockerfile', mode: langDockerfile),
    'makefile' || 'gnumakefile' => (id: 'makefile', mode: langMakefile),
    'cmakelists.txt' => (id: 'cmake', mode: langCmake),
    _ => null,
  };
  if (byName != null) {
    return byName;
  }
  final dot = lower.lastIndexOf('.');
  final extension = dot == -1 ? '' : lower.substring(dot + 1);
  return switch (extension) {
    'dart' => (id: 'dart', mode: langDart),
    'js' || 'mjs' || 'cjs' || 'jsx' => (id: 'javascript', mode: langJavascript),
    'ts' || 'mts' || 'cts' || 'tsx' => (id: 'typescript', mode: langTypescript),
    'py' || 'pyi' => (id: 'python', mode: langPython),
    'rb' => (id: 'ruby', mode: langRuby),
    'go' => (id: 'go', mode: langGo),
    'rs' => (id: 'rust', mode: langRust),
    'java' => (id: 'java', mode: langJava),
    'kt' || 'kts' => (id: 'kotlin', mode: langKotlin),
    'swift' => (id: 'swift', mode: langSwift),
    'c' || 'h' => (id: 'c', mode: langC),
    'cc' || 'cpp' || 'cxx' || 'hh' || 'hpp' => (id: 'cpp', mode: langCpp),
    'cs' => (id: 'csharp', mode: langCsharp),
    'php' => (id: 'php', mode: langPhp),
    'sh' || 'bash' || 'zsh' => (id: 'bash', mode: langBash),
    'ksh' => (id: 'shell', mode: langShell),
    'json' => (id: 'json', mode: langJson),
    'yaml' || 'yml' => (id: 'yaml', mode: langYaml),
    'xml' || 'plist' || 'svg' || 'xsl' => (id: 'xml', mode: langXml),
    'html' || 'htm' => (id: 'xml', mode: langXml),
    'css' => (id: 'css', mode: langCss),
    'scss' => (id: 'scss', mode: langScss),
    'less' => (id: 'less', mode: langLess),
    'sql' => (id: 'sql', mode: langSql),
    'md' || 'markdown' => (id: 'markdown', mode: langMarkdown),
    'ini' || 'toml' || 'cfg' || 'conf' => (id: 'ini', mode: langIni),
    'properties' || 'env' => (id: 'properties', mode: langProperties),
    'mk' => (id: 'makefile', mode: langMakefile),
    'cmake' => (id: 'cmake', mode: langCmake),
    'nginx' => (id: 'nginx', mode: langNginx),
    'lua' => (id: 'lua', mode: langLua),
    'pl' || 'pm' => (id: 'perl', mode: langPerl),
    'r' => (id: 'r', mode: langR),
    'diff' || 'patch' => (id: 'diff', mode: langDiff),
    _ => (id: 'plaintext', mode: langPlaintext),
  };
}
