package hx_arabic_shaper;

import hx_arabic_shaper.Ligatures.LIGATURES;
import hx_arabic_shaper.Letters;
import hx_arabic_shaper.ReshaperConfig;
import hx_arabic_shaper.utils.UTF8String;
import hx_arabic_shaper.utils.DynamicAccess;
import hx_arabic_shaper.utils.ArrayMap;

using StringTools;

class ArabicReshaper {
	// This work is licensed under the MIT License.
	// To view a copy of this license, visit https://opensource.org/licenses/MIT
	// Ported and tweaked from Java to Python by Abdullah Diab (mpcabd), from Better Arabic Reshaper
	// [https://github.com/agawish/Better-Arabic-Reshaper/]
	// Email: mpcabd@gmail.com
	// Website: http://mpcabd.xyz
	
	// Ported and tweaked from Python to Haxe by mrcdk
	
	public static var ISOLATED = Letters.ISOLATED;
	public static var TATWEEL = Letters.TATWEEL;
	public static var ZWJ = Letters.ZWJ;
	public static var LETTERS = Letters.LETTERS;
	public static var FINAL = Letters.FINAL;
	public static var INITIAL = Letters.INITIAL;
	public static var MEDIAL = Letters.MEDIAL;
	public static var UNSHAPED = Letters.UNSHAPED;

	static var config = getDefaultConfig();

	static var HARAKAT_RE:EReg = null;
	static var LIGATURE_RE:EReg = null;
	static var group_index_to_ligature_forms:ArrayMap<Int, Array<Dynamic>> = new ArrayMap();
	static var group_index_to_ligature_name:ArrayMap<Int, String> = new ArrayMap();

	static var initialized = false;

	public static function getDefaultConfig() {
		return new ReshaperConfig();
	}

	public static function init(?reshaper_config:ReshaperConfig) {
		
		if(initialized) {
			return;
		}

		if(reshaper_config != null) {
			config = reshaper_config;
		}

		HARAKAT_RE = new EReg('[\u0610-\u061a\u064b-\u065f\u0670\u06d6-\u06dc\u06df-\u06e8\u06ea-\u06ed\u08d4-\u08e1\u08d4-\u08ed\u08e3-\u08ff]', "gu");
		
		var ligature_matches = [];
		var idx = 1;
		for(ligature in LIGATURES) {
			var name = ligature[0];
			if(!config.ligature_config.get(name, false)) {
				continue;
			}
			var replacement:Array<Dynamic> = ligature[1];
			ligature_matches.push('(${replacement[0]})');
			group_index_to_ligature_forms.set(idx, replacement[1]);
			group_index_to_ligature_name.set(idx, name);
			idx++;
		}
		var matches = ligature_matches.join("|");
		LIGATURE_RE = new EReg(ligature_matches.join("|"), "gu");

		initialized = true;
	}

	public static function dispose() {
		HARAKAT_RE = null;
		LIGATURE_RE = null;
		group_index_to_ligature_forms = new ArrayMap();
		group_index_to_ligature_name = new ArrayMap();

		initialized = false;
	}

	public static function reshape(text:UTF8String):UTF8String {
		if (text == null || text.trim() == "") {
			return text;
		}

		if (!initialized) {
			init();
		}

		var output:Array<Array<Dynamic>> = [];

		var LETTER = 0;
		var FORM = 1;
		var NOT_SUPPORTED = -1;

		var delete_harakat = config.delete_harakat;
		var shift_harakat_position = config.shift_harakat_position;
		var delete_tatweel = config.delete_tatweel;
		var support_zwj = config.support_zwj;

		var positions_harakat = new Map<Int, Array<UTF8String>>();
		var isolated_form = config.use_unshaped_instead_of_isolated ? UNSHAPED : ISOLATED;

		for (letter in text.split("")) {
			if (HARAKAT_RE.match(letter)) {
				if (!delete_harakat) {
					var position = output.length - 1;
					if (shift_harakat_position) {
						position -= 1;
					}
					if (!positions_harakat.exists(position)) {
						positions_harakat.set(position, []);
					}

					if (shift_harakat_position) {
						positions_harakat[position].insert(0, letter);
					} else {
						positions_harakat[position].push(letter);
					}
				}
			} else if (letter == TATWEEL && delete_tatweel) {
				// nothing
			} else if (letter == ZWJ && !support_zwj) {
				// nothing
			} else if (!LETTERS.exists(letter)) {
				output.push([letter, NOT_SUPPORTED]);
			} else if (output.length == 0) { // first letter
				output.push([letter, isolated_form]);
			} else {
				var previous_letter = output[output.length - 1];
				if (previous_letter[FORM] == NOT_SUPPORTED) {
					output.push([letter, isolated_form]);
				} else if (!Letters.connects_with_letter_before(letter)) {
					output.push([letter, isolated_form]);
				} else if (!Letters.connects_with_letter_after(previous_letter[LETTER])) {
					output.push([letter, isolated_form]);
				} else if (previous_letter[FORM] == FINAL && !Letters.connects_with_letters_before_and_after(previous_letter[LETTER])) {
					output.push([letter, isolated_form]);
				} else if (previous_letter[FORM] == isolated_form) {
					output[output.length - 1] = [previous_letter[LETTER], INITIAL];
					output.push([letter, FINAL]);
				} else {
					// Otherwise, we will change the previous letter to connect
					// to the current letter
					output[output.length - 1] = [previous_letter[LETTER], MEDIAL];
					output.push([letter, FINAL]);
				}
			}

			// Remove ZWJ if it's the second to last item as it won't be useful
			if (support_zwj && output.length > 1 && output[output.length - 2][LETTER] == ZWJ) {
				output.splice(output.length - 2, 1);
			}
		}

		if (support_zwj && output.length > 1 && output[output.length - 1][LETTER] == ZWJ) {
			output.pop();
		}

		if(config.support_ligatures) {
			// Clean text from Harakat to be able to find ligatures
			text = HARAKAT_RE.replace(text, "");

			// Clean text from Tatweel to find ligatures if delete_tatweel
			if (delete_tatweel) {
				text = text.replace(TATWEEL, "");
			}

			var groups:Array<DynamicAccess> = [];
			var tstart = 0;
			LIGATURE_RE.map(text, function(r) {
				for(idx in group_index_to_ligature_forms.keys()) {
					var matched:UTF8String = r.matched(idx);
					if(matched != null && matched != "") {
						var s = text.indexOf(matched, tstart);
						var e = s + matched.length;
						//trace(text, group_index_to_ligature_name.get(idx), matched, s, e);
						groups.push({
							"index": idx,
							"start": s,
							"end": e,
						});
						tstart = e;
						break;
					}
				}
				return "";
			});

			for(group in groups) {
				var forms = group_index_to_ligature_forms.get(group["index"]);
				var a:Int = group["start"];
				var b:Int = group["end"];
				var a_form = output[a][FORM];
				var b_form = output[b-1][FORM];
				var ligature_form:Null<Int> = null;

				// +-----------+----------+---------+---------+----------+
				// | a   \   b | ISOLATED | INITIAL | MEDIAL  | FINAL    |
				// +-----------+----------+---------+---------+----------+
				// | ISOLATED  | ISOLATED | INITIAL | INITIAL | ISOLATED |
				// | INITIAL   | ISOLATED | INITIAL | INITIAL | ISOLATED |
				// | MEDIAL    | FINAL    | MEDIAL  | MEDIAL  | FINAL    |
				// | FINAL     | FINAL    | MEDIAL  | MEDIAL  | FINAL    |
				// +-----------+----------+---------+---------+----------+

				if (a_form == isolated_form || a_form == INITIAL) {
					if (b_form == isolated_form || b_form == FINAL) {
						ligature_form = ISOLATED;
					} else {
						ligature_form = INITIAL;
					}
				} else {
					if (b_form == isolated_form || b_form == FINAL) {
						ligature_form = FINAL;
					} else {
						ligature_form = MEDIAL;
					}
				}

				var form = forms[ligature_form];
				if(form == "") {
					continue;
				}
				output[a] = [form, NOT_SUPPORTED];
				for (i in a + 1...b) {
					output[i] = ['', NOT_SUPPORTED];
				}
			}
		}

		var result = [];

		if (!delete_harakat && positions_harakat.exists(-1)) {
			result = result.concat(positions_harakat.get(-1));
		}

		for (o in output) {
			var i = output.indexOf(o);
			if (o[LETTER] != null && o[LETTER] != "") {
				if (o[FORM] == NOT_SUPPORTED || o[FORM] == UNSHAPED) {
					result.push(o[LETTER]);
				} else {
					result.push(LETTERS[o[LETTER]][o[FORM]]);
				}
			}

			if (!delete_harakat) {
				if (positions_harakat.exists(i)) {
					result = result.concat(positions_harakat.get(i));
				}
			}
		}

		
		var str_result:UTF8String = result.join("");

		return str_result;
	}
}
