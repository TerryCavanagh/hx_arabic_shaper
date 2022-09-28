package hx_arabic_shaper.bidi;

import hx_arabic_shaper.bidi.Statics;
import hx_arabic_shaper.bidi.algorithm.*;
import hx_arabic_shaper.utils.DynamicAccess;
import hx_arabic_shaper.utils.UTF8String;

class UBA {

  public static function display_paragraph(string:UTF8String):UTF8String {
    var data = Statics._get_data_struct();

    data.chars = Paragraph.preprocess_text(string);
    data.level = Paragraph.get_paragraph_level(data.chars);

    Explicit.explicit_levels_and_directions(data);
    PrepareImplicit.preparations_for_implicit_processing(data);
    ResolveWeak.resolve_weak_types(data);
    ResolveNeutral.resolve_neutral_and_isolate_formatting_types(data);
    ResolveImplicit.resolve_implicit_levels(data);

    // acording to UAX #9, at this point, we can inser shaping & paragraph wrapping.
    // up to this point, no actual reordering happened. Just metadata juggling.

    ReorderResolved.reorder_resolved_levels(data);

    var chars = data.chars.map(function(ch) return ch.ch);
    var result:UTF8String = chars.join("");

    return result;
  }

  public static function display(text:UTF8String):UTF8String {
    var result = [];

    for (line in text.split("\n")) {
      result.push(display_paragraph(line));
    }

    return result.join("\n");
  }

}