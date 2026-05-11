import 'package:dart_quill_delta/dart_quill_delta.dart';

import 'converter_options.dart';
import 'delta_importer.dart';
import 'options/html_options.dart';

/// Base class for non-HTML importers that convert their source format into
/// an intermediate HTML string and delegate the HTML -> Delta step to an
/// injected [DeltaImporter<String, HtmlOptions>].
///
/// Subclasses implement [toHtml]. The injected [htmlImporter] runs the
/// HTML decode pass.
///
/// Why a base class (not mixin): the inner [htmlImporter] is constructor-
/// injected so tests can substitute a mock. Dart 3 mixins cannot declare
/// generative constructors with parameters.
///
/// Why HTML pivot: every embed adapter operates on HTML DOM, so any format
/// that pivots through HTML automatically gets the full embed adapter
/// catalog (image, video, mention, table, etc.) for free.
abstract base class HtmlPivotImporter<TIn, TOpts extends ConverterOptions>
    implements DeltaImporter<TIn, TOpts> {
  const HtmlPivotImporter({required this.htmlImporter});

  /// HTML -> Delta importer used for the pivot stage.
  final DeltaImporter<String, HtmlOptions> htmlImporter;

  /// Convert [input] (in this importer's source format) into an HTML string.
  /// May be a fragment or full document; the downstream [htmlImporter]
  /// handles both.
  Future<String> toHtml(TIn input, TOpts options);

  @override
  Future<Delta> import(TIn input, {TOpts? options}) async {
    final opts = options ?? defaultOptions;
    final html = await toHtml(input, opts);
    return htmlImporter.import(html);
  }
}
