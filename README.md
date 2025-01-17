# Arabic shaper for Haxe

A library to correctly shape Arabic text and deal with BIDI for Haxe

## Install and how to use

Install it with:

```
haxelib install hx_arabic_shaper
```

Or if you want to use the git version:

```
haxelib git hx_arabic_shaper https://github.com/TerryCavanagh/hx_arabic_shaper.git
```

if you aren't going to use this library in a OpenFL/Lime project and you are using Haxe 3.x, install [unifill](https://github.com/mandel59/unifill) with:

```
haxelib install unifill
```

Add it to your `build.hxml` (or similar) with:

```hxml
-lib hx_arabic_shaper
```

or add it to your `project.xml` if you are using OpenFL/Lime with:

```xml
<haxelib>hx_arabic_shaper</haxelib>
```

You'll need to initialize it to build the ligatures cache and dispose it to destroy that cache:

```haxe
import hx_arabic_shaper.ArabicReshaper;
import hx_arabic_shaper.bidi.UBA;

...

public static function init() {
  // your init code
  // change the config if you need it, it's optional
  var config = ArabicReshaper.getDefaultConfig();
  config.delete_harakat = true;
  ArabicReshaper.init(config);
}

...

public static function dispose() {
  // your dispose code
  ArabicReshaper.dispose();
}
```

You can only enable or disable ligatures **before** initializing the reshaper. Once initialized changing the ligatures config won't do anything. Check [ReshaperConfig.hx](src/hx_arabic_shaper/ReshaperConfig.hx) for the full list of options and ligatures you can enable or disable.

After that, you have two options to shape Arabic text:

- If you only need the final string you can do the following:

```haxe
function print(text:String) {
  // Get the shaped text
  var shaped = ArabicReshaper.reshape(text);
  // Process the BIDI algorithm
  var bidi = UBA.display(shaped);
  // Render it
}
```

- If you need to pass extra information you can call: `ArabicReshaper.bidi_and_shape()` which will process the bidi and shaping algorithms at the same time returning an array of `CharData` with extra information per character. You can pass an extra callback to the function to save custom data inside `CharData.userdata` if you need it.

## Gotchas

- Mixing LTR and RTL text in the same sentence may not work correctly. You'll need to use the [Unicode directional formatting codes](https://www.unicode.org/reports/tr9/#Directional_Formatting_Codes) to force part of the text one way or the other depending on the result you want to achieve.
- Shaping numbers is finicky. Depending on what you want to achieve you'll need to use those Unicode directional formatting codes to format them correctly.
- The BIDI algorithm might work with other languages but it's untested.

If you find any issues feel free to report them. It'd be really helpful if you could check if the issue can be reproduced in the original library before opening the issue here. Thanks!

## Credits

- Arabic reshaper: Ported and tweaked from Python to Haxe from https://github.com/mpcabd/python-arabic-reshaper Original author: Abdullah Diab (mpcabd) and contributors
- BIDI algorithm: Ported and tweaked from GDScript to Haxe from https://github.com/3akev/godot-arabic-text Original author: 3akev and contributors
- `UTF8String`: Copied from [Lime](https://github.com/haxelime/lime) Original author: Joshua Granick (jgranick) and contributors

## License

This work is licensed under MIT License.
