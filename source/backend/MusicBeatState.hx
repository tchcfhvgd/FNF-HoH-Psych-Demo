package backend;

import flixel.FlxSubState;
import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;
#if mobile
import mobile.MobileControls;
import mobile.flixel.FlxVirtualPad;
import flixel.FlxCamera;
import flixel.input.actions.FlxActionInput;
import flixel.util.FlxDestroyUtil;
#end

class MusicBeatState extends FlxUIState {
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	public static var checkHitbox:Bool = false;
	public static var checkDUO:Bool = false;

	public var controls(get, never):Controls;

	        #if mobile
		public static var mobileControls:MobileControls;
		public static var virtualPad:FlxVirtualPad;
		//var trackedInputsMobileControls:Array<FlxActionInput> = [];
		//var trackedInputsVirtualPad:Array<FlxActionInput> = [];

		public function addVirtualPad(DPad:FlxDPadMode, Action:FlxActionMode)
		{
		    if (virtualPad != null)
			removeVirtualPad();

			virtualPad = new FlxVirtualPad(DPad, Action);
		        add(virtualPad);
                        Controls.checkState = true;
		        Controls.CheckPress = true;
			//controls.setVirtualPadUI(virtualPad, DPad, Action);
			//trackedInputsVirtualPad = controls.trackedInputsUI;
			//controls.trackedInputsUI = [];
		}

		public function removeVirtualPad()
		{
			if (virtualPad != null)
			remove(virtualPad);
		}

		#if mobile
	        public function noCheckPress() 
	        {
		        Controls.CheckPress = false;
	        }
	        #end
	
	        public function addMobileControls(DefaultDrawTarget:Bool = true)
		{
			if (mobileControls != null)
			removeMobileControls();

			mobileControls = new MobileControls();
			Controls.CheckPress = true;

			switch (MobileControls.mode)
			{
				case 'Pad-Right' | 'Pad-Left' | 'Pad-Custom':
				//controls.setVirtualPadNOTES(mobileControls.virtualPad, RIGHT_FULL, NONE);
				checkHitbox = false;
				checkDUO = false;
				Controls.CheckKeyboard = false;
				case 'Pad-Duo':
				//controls.setVirtualPadNOTES(mobileControls.virtualPad, BOTH_FULL, NONE);
				checkHitbox = false;
				checkDUO = true;
				Controls.CheckKeyboard = false;
				case 'Hitbox':
				//controls.setHitBox(mobileControls.hitbox);
				checkHitbox = true;
				checkDUO = false;
				Controls.CheckKeyboard = false;
				case 'Keyboard':
				checkHitbox = false;
				checkDUO = false;
			        Controls.CheckKeyboard = true;
			}

			var camControls:FlxCamera = new FlxCamera();
			FlxG.cameras.add(camControls, DefaultDrawTarget);
			camControls.bgColor.alpha = 0;

			mobileControls.cameras = [camControls];
			mobileControls.visible = false;
			add(mobileControls);
			Controls.CheckControl = true;
		}

		public function removeMobileControls()
		{
			if (mobileControls != null)
			remove(mobileControls);
		}

		public function addVirtualPadCamera(DefaultDrawTarget:Bool = true)
		{
			if (virtualPad != null)
			{
				var camControls:FlxCamera = new FlxCamera();
				FlxG.cameras.add(camControls, DefaultDrawTarget);
				camControls.bgColor.alpha = 0;
				virtualPad.cameras = [camControls];
			}
		}
		#end

		override function destroy()
		{
			super.destroy();

			#if mobile
			if (virtualPad != null)
			virtualPad = FlxDestroyUtil.destroy(virtualPad);

			if (mobileControls != null)
			mobileControls = FlxDestroyUtil.destroy(mobileControls);
			#end
		}
	
	private function get_controls() {
		return Controls.instance;
	}

	public static var camBeat:FlxCamera;

	override function create() {
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		super.create();

		if (!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
	}

	public static var timePassedOnState:Float = 0;

	override function update(elapsed:Float) {
		// everyStep();
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep) {
			if (curStep > 0)
				stepHit();

			if (PlayState.SONG != null) {
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		handleDebug();

		if (FlxG.save.data != null)
			FlxG.save.data.fullscreen = FlxG.fullscreen;

		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

		super.update(elapsed);
	}

	public function handleDebug() {
		#if (RELEASE_DEBUG && sys)
		if (!FlxG.keys.pressed.SHIFT)
			return;

		if (FlxG.keys.justPressed.Z) {
			FlxTransitionableState.skipNextTransOut = true;
			FlxTransitionableState.skipNextTransIn = true;
			MusicBeatState.switchState(new states.debug.DebugSongSelect());
		}
		if (FlxG.keys.justPressed.X) {
			FlxTransitionableState.skipNextTransOut = true;
			FlxTransitionableState.skipNextTransIn = true;
			MusicBeatState.switchState(new states.debug.DebugStateSelect());
		}

		if (FlxG.keys.justPressed.Q) {
			DataSaver.allowSaving = !DataSaver.allowSaving;
			showMessage('Allow Saving: ' + DataSaver.allowSaving);
		}
		if (FlxG.keys.justPressed.E) {
			openSubState(new states.debug.DebugSaveEditorSubState());
		}
		#end
	}

	private function updateSection():Void {
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo) {
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void {
		if (curStep < 0)
			return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length) {
			if (PlayState.SONG.notes[i] != null) {
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep)
					break;

				curSection++;
			}
		}

		if (curSection > lastSection)
			sectionHit();
	}

	private function updateBeat():Void {
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void {
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null) {
		if (nextState == null)
			nextState = FlxG.state;
		if (nextState == FlxG.state) {
			resetState();
			return;
		}

		if (FlxTransitionableState.skipNextTransIn)
			FlxG.switchState(nextState);
		else
			startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState() {
		if (FlxTransitionableState.skipNextTransIn)
			FlxG.resetState();
		else
			startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null) {
		if (nextState == null)
			nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.6, false));
		if (nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public static function getState():MusicBeatState {
		return cast(FlxG.state, MusicBeatState);
	}

	public function stepHit():Void {
		stagesFunc(function(stage:BaseStage) {
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0)
			beatHit();
	}

	public var stages:Array<BaseStage> = [];

	public function beatHit():Void {
		// trace('Beat: ' + curBeat);
		stagesFunc(function(stage:BaseStage) {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void {
		// trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		stagesFunc(function(stage:BaseStage) {
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	function stagesFunc(func:BaseStage->Void) {
		for (stage in stages)
			if (stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection() {
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	var _message:FlxText;
	var message(get, null):FlxText;

	function get_message():FlxText {
		if (_message == null) {
			_message = new FlxText(0, 0, FlxG.width);
			_message.size = 26;
			_message.borderSize = 1.25;
			_message.alignment = CENTER;
			_message.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			_message.scrollFactor.set();
			_message.screenCenterXY();
			_message.alpha = 0;
		}

		return _message;
	}

	var messageTween:FlxTween;

	public function showMessage(text:String = "", level = 0, delayUntilFade:Float = 0.5):Void {
		// TODO: Add message queue
		message.alpha = 1;

		message.color = switch (level) {
			case 0: 0xFFffffff; // Info
			case 1: 0xFFff0000; // Error
			case 2: 0xFFffFF00; // Warning
			case 3: 0xFF00FF00; // Good
			default: 0xFFffffff;
		}
		message.text = text;

		message.screenCenterXY();

		remove(message, true);
		add(message);

		message.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		if (messageTween != null) {
			messageTween.cancel();
		}
		messageTween = FlxTween.tween(message, {alpha: 0}, 1.3, {
			startDelay: delayUntilFade,
			onComplete: (v) -> {
				remove(message, true);
			}
		});
	}

	#if RELEASE_DEBUG
	var inSaveEditor:Bool = false;
	#end

	override function openSubState(SubState:FlxSubState):Void {
		#if RELEASE_DEBUG
		if ((SubState is states.debug.DebugSaveEditorSubState)) {
			inSaveEditor = true;
		}
		#end
		super.openSubState(SubState);
	}

	override function closeSubState():Void {
		#if RELEASE_DEBUG
		if ((subState is states.debug.DebugSaveEditorSubState)) {
			inSaveEditor = false;
		}
		#end
		super.closeSubState();
	}

	@:allow(flixel.FlxGame)
	override function tryUpdate(elapsed:Float):Void {
		if (#if RELEASE_DEBUG !inSaveEditor && #end (persistentUpdate || subState == null)) {
			update(elapsed);
		}

		if (_requestSubStateReset) {
			_requestSubStateReset = false;
			resetSubState();
		}
		if (subState != null) {
			subState.tryUpdate(elapsed);
		}
	}
}
