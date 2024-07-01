package backend;

import openfl.utils.Assets as OpenFlAssets;
import haxe.io.Path;
import haxe.xml.Access;
import haxe.Exception;

/**
 * The class used for translations based on the XMLs inside the translations folders.
 *
 * Made by @NexIsDumb originally for the Poldhub mod (THIS PORT HAS NO OVERRIDEABLE TRANSLATED ASSETS AND ALSO WAS SLIGHTLY EDITED!!!).
 */
class TransManager {
	/**
	 * The current language selected translation map; If the current language it's english, this map will be empty.
	 *
	 * Using this class function it'll never be `null`.
	 */
	public static var transMap(default, null):Map<String, String> = [];

	/**
	 * The default language used inside of the source code.
	 */
	public static inline var DEFAULT_LANGUAGE:String = 'English';

	/**
	 * The default font used.
	 */
	public static inline var DEFAULT_FONT:String = 'perpetua.ttf';

	/**
	 * The default font used for the ui.
	 */
	public static inline var DEFAULT_UI_FONT:String = 'trajan.ttf';

	/**
	 * The font found inside the language's file (CAN BE `null`!!).
	 */
	public static var languageFont:String = null;

	/**
	 * Returns the current font.
	 */
	inline public static function get_curFont():String
		return languageFont == null ? DEFAULT_UI_FONT : languageFont;

	/**
	 * Returns the current ui font.
	 */
	inline public static function get_curUIFont():String
		return languageFont == null ? DEFAULT_FONT : languageFont;

	/**
	 * Returns the current language.
	 */
	inline public static function get_curLanguage():String
		return ClientPrefs.data.language;

	/**
	 * Returns if the current language is the default one (`DEFAULT_LANGUAGE`).
	 */
	inline public static function is_defaultLanguage():Bool
		return ClientPrefs.data.language == DEFAULT_LANGUAGE;

	/**
	 * Returns if any translation is loaded.
	 */
	inline public static function is_anyTransLoaded():Bool
		return transMap != [];

	/**
	 * Changes the translations map.
	 *
	 * If `name` is `null`, it's gonna use the current language.
	 */
	public static function setTransl(?name:String) {
		if (name == null)
			name = get_curLanguage();
		transMap = loadLanguage(name);
	}

	/**
	 * This is for checking a translation, `defString` it's just the string that gets returned just in case it won't find the translation OR the current language selected is ``DEFAULT_LANGUAGE``.
	 *
	 * If `id` is `null` then it's gonna search using `defString`.
	 */
	public static function checkTransl(defString:String, ?id:String):String {
		if (id == null)
			id = defString;
		if (transMap.exists(id))
			return transMap.get(id);
		else
			return defString;
	}

	/**
	 * Returns an array that specifies which translations were found (EMBED ONLY cuz better :) ).
	 */
	public static function translList():Array<String> {
		var translations = [];
		#if !sys
		for (l in OpenFlAssets.list()) {
			var d = Path.directory(l);
			if (d.startsWith(Paths.transMainFolder())) {
				d = (d.replace(Paths.transMainFolder(), "").split("/"))[0];
				if (!translations.contains(d))
					translations.push(d);
			}
		}
		#else
		for (file in FileSystem.readDirectory(Paths.transMainFolder())) {
			var path = new haxe.io.Path(file);
			if (!FileSystem.isDirectory(haxe.io.Path.join([Paths.transMainFolder(), file])) && path.ext == "xml" && !translations.contains(file))
				translations.push(path.file);
		}
		#end
		return translations;
	}

	/**
	 * Returns a map of translations based on its xml.
	 */
	public static function loadLanguage(name:String):Map<String, String> {
		if (!Paths.fileExists(name + ".xml", TEXT, false, "translations"))
			return _returnAndNullFont([]);

		var xml = null;
		try {
			xml = new Access(Xml.parse(Paths.getTextFromFile(name + ".xml", false, "translations")));
		} catch (e) {
			var err = 'Error while parsing the language\'s xml: ${Std.string(e)}';
			FlxG.log.error(err);
			throw new Exception(err);
		}
		if (xml == null)
			return _returnAndNullFont([]);
		if (!xml.hasNode.translations) {
			FlxG.log.warn("A translation xml file requires a translations root element.");
			return _returnAndNullFont([]);
		}

		var leMap:Map<String, String> = [];
		var transNode = xml.node.translations;
		for (node in transNode.elements) {
			switch (node.name) {
				case "trans":
					if (!node.has.id) {
						FlxG.log.warn("A translation node requires an ID attribute.");
						continue;
					}
					if (!node.has.string) {
						FlxG.log.warn("A translation node requires a string attribute.");
						continue;
					}

					leMap.set(node.att.resolve("id"), node.att.resolve("string"));
			}
		}

		languageFont = transNode.has.font ? transNode.att.resolve("font") : null;
		return leMap;
	}

	private static inline function _returnAndNullFont(val:Map<String, String>):Map<String, String> {
		if (val == null || val == [])
			languageFont = null;

		return val;
	}
}