package mobile;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import backend.Controls;
import options.BaseOptionsMenu;
import options.Option;
import openfl.Lib;

using StringTools;

class AndroidSettingsSubState extends BaseOptionsMenu
{
final hintOptions:Array<String> = ["No Gradient", "No Gradient (Old)", "Gradient", "Hidden"];
	
	public function new()
	{
		title = 'Mobile Controls Settings';
		rpcTitle = 'Mobile Controls Settings Menu'; // hi, you can ask what is that, i will answer it's all what you needed lol.

		var option:Option = new Option('Vpad Opacity', // mariomaster was here again
			'Changes Vpad Opacity -yeah ', 'padalpha', 'float');
		option.scrollSpeed = 1.6;
		option.minValue = 0.1; // prevent invisible vpad
		option.maxValue = 1;
		option.changeValue = 0.01;
		option.decimals = 2;
		addOption(option);

		var option:Option = new Option('Hitbox Opacity', // mariomaster is dead :00000
			'Changes Hitbox opacity -what', 'hitboxalpha', 'float');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.01;
		option.decimals = 2;
		addOption(option);

		var option:Option = new Option('Hitbox Design',
			'Choose how your hitbox should look like.',
			'hitboxType',
			'string',
			hintOptions);
			addOption(option);

		super();
	}
}