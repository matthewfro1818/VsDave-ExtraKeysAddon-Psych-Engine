package;

import openfl.filters.ShaderFilter;
import WiggleEffect.ChromAbEffect;
import FlxPerspectiveSprite.FlxPerspectiveTrail;
import flixel.graphics.FlxGraphic;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import Note.EventNote;
import openfl.events.KeyboardEvent;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.util.FlxSave;
import animateatlas.AtlasFrameMaker;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import Conductor.Rating;
import openfl.display.Sprite;
import flixel.addons.display.FlxBackdrop;
#if sys
import sys.FileSystem;
#end

#if VIDEOS_ALLOWED
import vlc.MP4Handler;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();

	public static var mania:Int = 0;
	public static var keyAmmount:Int = 4;

	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var boyfriendGroup:FlxSpriteGroup;
	public var bfGroup:FlxSpriteGroup;
	public var dadGroup:FlxTypedSpriteGroup<FlxPerspectiveSprite>;
	public var trailGroup:FlxTypedSpriteGroup<FlxPerspectiveTrail>;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;
	public var extraVocals:Array<FlxSound> = [];

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	
	public var player:Character = null;
	public var opponent:Character = null;
	public var currentOpponentStrums:FlxTypedGroup<StrumNote>;
	public var currentPlayerStrums:FlxTypedGroup<StrumNote>;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var renderedStrumLineNotes:FlxTypedGroup<StrumNote>;
	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	public var ratingsData:Array<Rating> = [];
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleSmokes:FlxSpriteGroup;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var trainSound:FlxSound;

	var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT', 'singUP', 'singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	var precacheList:Map<String, String> = new Map<String, String>();

	public static var god:Bool = false;
	public static var trueDiff:Bool = false;
	public var chrom:ChromAbEffect = new ChromAbEffect();
	public static var spawnedWindowThisFrame:Bool = false;

	var bindPopups:Array<FlxText> = [];

	//bg stuff
	var baldi:BGSprite;
	var spotLight:FlxSprite;
	var spotLightPart:Bool;
	var spotLightScaler:Float = 1.3;
	var lastSinger:Character;

	var crowdPeople:FlxTypedGroup<BGSprite> = new FlxTypedGroup<BGSprite>();
	
	var interdimensionBG:BGSprite;
	var currentInterdimensionBG:String;
	var nimbiLand:BGSprite;
	var nimbiSign:BGSprite;
	var flyingBgChars:FlxTypedGroup<FlyingBGChar> = new FlxTypedGroup<FlyingBGChar>();
	public static var isGreetingsCutscene:Bool;
	var originalPosition:FlxPoint = new FlxPoint();
	var daveFlying:Bool;
	var pressingKey5Global:Bool = false;

	var highway:FlxSprite;
	var bambiSpot:FlxSprite;
	var bfSpot:FlxSprite;
	var originalBFScale:FlxPoint;
	var originBambiPos:FlxPoint;
	var originBFPos:FlxPoint;

	var tristan:BGSprite;
	var curTristanAnim:String;

	var desertBG:BGSprite;
	var desertBG2:BGSprite;
	var sign:BGSprite;
    var georgia:BGSprite;
	var train:BGSprite;
	var trainSpeed:Float;

	var vcr:VCRDistortionShader;

	var place:BGSprite;
	var stageCheck:String = 'stage';

	// FUCKING UHH particles
	var emitter:FlxEmitter;
	var smashPhone:Array<Int> = new Array<Int>();

	//recursed
	var darkSky:BGSprite;
	var darkSky2:BGSprite;
	var darkSkyStartPos:Float = 1280;
	var resetPos:Float = -2560;
	var freeplayBG:BGSprite;
	var daveBG:String;
	var bambiBG:String;
	var tristanBG:String;
	var charBackdrop:FlxBackdrop;
	var alphaCharacters:FlxTypedGroup<Alphabet> = new FlxTypedGroup<Alphabet>();
	var daveSongs:Array<String> = ['House', 'Insanity', 'Polygonized', 'Bonus Song'];
	var bambiSongs:Array<String> = ['Blocked', 'Corn-Theft', 'Maze', 'Mealie'];
	var tristanSongs:Array<String> = ['Adventure', 'Vs-Tristan'];
	var tristanInBotTrot:BGSprite; 

	var missedRecursedLetterCount:Int = 0;
	var recursedCovers:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	var isRecursed:Bool = false;
	var recursedUI:FlxTypedGroup<FlxObject> = new FlxTypedGroup<FlxObject>();

	var timeLeft:Float;
	var timeGiven:Float;
	var timeLeftText:FlxText;

	var noteCount:Int;
	var notesLeft:Int;
	var notesLeftText:FlxText;

	var preRecursedHealth:Float;
	var preRecursedSkin:String;
	var rotateCamToRight:Bool;
	var camRotateAngle:Float = 0;

	var rotatingCamTween:FlxTween;

	static var DOWNSCROLL_Y:Float;
	static var UPSCROLL_Y:Float;

	var switchSide:Bool;

	public var subtitleManager:SubtitleManager;
	
	public var guitarSection:Bool;
	public var dadStrumAmount = 4;
	public var playerStrumAmount = 4;
	
	//explpit
	var expungedBG:BGSprite;
	public static var scrollType:String;
	var preDadPos:FlxPoint = new FlxPoint();

	//window stuff
	var expungedScroll = new Sprite();
	var expungedSpr = new Sprite();
	var windowProperties:Array<Dynamic> = new Array<Dynamic>();
	var expungedWindowMode:Bool = false;
	var expungedOffset:FlxPoint = new FlxPoint();
	var expungedMoving:Bool = true;

	//indignancy
	var vignette:FlxSprite;
	
	//five night
	var time:FlxText;
	var times:Array<Int> = [12, 1, 2, 3, 4, 5];
	var night:FlxText;
	var powerLeft:Float = 100;
	var powerRanOut:Bool;
	var powerDrainer:Float = 1;
	var powerMeter:FlxSprite;
	var powerLeftText:FlxText;
	var powerDown:FlxSound;
	var usage:FlxText;

	var door:BGSprite;
	var doorButton:BGSprite;
	var doorClosed:Bool;
	var doorChanging:Bool;

	var banbiWindowNames:Array<String> = ['when you realize you have school this monday', 'industrial society and its future', 'my ears burn', 'i got that weed card', 'my ass itch', 'bruh', 'alright instagram its shoutout time'];

	var barType:String;

	var noteWidth:Float = 0;

	public static var shaggyVoice:Bool = false;
	var isShaggy:Bool = false;
	var legs:FlxSprite;
	var shaggyT:FlxTrail;
	var legT:FlxTrail;
	var shx:Float;
	var shy:Float;
	var sh_r:Float = 60;

	public static var globalFunny:CharacterFunnyEffect = CharacterFunnyEffect.None;

	public var localFunny:CharacterFunnyEffect = CharacterFunnyEffect.None;

	public static var characteroverride:String = "none";
	public static var formoverride:String = "none";

	public var dadStrums:FlxTypedGroup<StrumNote>;

	var funnyFloatyBoys:Array<String> = ['dave-angey', 'bambi-3d', 'expunged', 'bambi-unfair', 'exbungo', 'dave-festival-3d', 'dave-3d-recursed', 'bf-3d'];

	var iconRPC:String = "";

	var boyfriendOldIcon:String = 'bf-old';

	var notestuffs:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	var notestuffsGuitar:Array<String> = ['LEFT', 'DOWN', 'MIDDLE', 'UP', 'RIGHT'];

	public static var curmult:Array<Float> = [1, 1, 1, 1];
	public static var curmultDefine:Array<Float> = [1, 1, 1, 1];

	public var curbg:BGSprite;
	public var black:BGSprite;
	public var pre3dSkin:String;
	#if SHADERS_ENABLED
	public static var screenshader:Shaders.PulseEffect = new PulseEffect();
	public static var lazychartshader:Shaders.GlitchEffect = new Shaders.GlitchEffect();
	public static var blockedShader:BlockedGlitchEffect;
	public var dither:DitherEffect = new DitherEffect();
	#end

	var kadeEngineWatermark:FlxText;
	var creditsWatermark:FlxText;
	var songName:FlxText;

	public static var theFunne:Bool = true;
	var activateSunTweens:Bool;

	var inFiveNights:Bool = false;

	public var crazyBatch:String = "shutdown /r /t 0";

	public var backgroundSprites:FlxTypedGroup<BGSprite> = new FlxTypedGroup<BGSprite>();
	var revertedBG:FlxTypedGroup<BGSprite> = new FlxTypedGroup<BGSprite>();

	var canFloat:Bool = true;

	var possibleNotes:Array<Note> = [];

	var glitch:FlxSprite;
	var tweenList:Array<FlxTween> = new Array<FlxTween>();
	var pauseTweens:Array<FlxTween> = new Array<FlxTween>();

	var bfTween:ColorTween;

	var tweenTime:Float;

	var songPosBar:FlxBar;
	var songPosBG:FlxSprite;

	var bfNoteCamOffset:Array<Float> = new Array<Float>();
	var dadNoteCamOffset:Array<Float> = new Array<Float>();

	var video:MP4Handler;
	public var modchart:ExploitationModchartType;
	public static var modchartoption:Bool = true;
	var weirdBG:FlxSprite;

	var mcStarted:Bool = false; 
	public var noMiss:Bool = false;
	public var creditsPopup:CreditsPopUp;
	public var blackScreen:FlxSprite;

	var nightColor:FlxColor = 0xFF878787;
	public var sunsetColor:FlxColor = FlxColor.fromRGB(255, 143, 178);

	public var hasTriggeredDumbshit:Bool = false;
	var AUGHHHH:String;
	var AHHHHH:String;

	public static var curmult:Array<Float> = [1, 1, 1, 1];
	public static var curmultDefine:Array<Float> = [1, 1, 1, 1];

	public var curbg:BGSprite;
	public var pre3dSkin:String;
	#if SHADERS_ENABLED
	public static var screenshader:Shaders.PulseEffect = new PulseEffect();
	public static var lazychartshader:Shaders.GlitchEffect = new Shaders.GlitchEffect();
	public static var blockedShader:BlockedGlitchEffect;
	public var dither:DitherEffect = new DitherEffect();
	#end

	private var BAMBICUTSCENEICONHURHURHUR:HealthIcon;

	private var STUPDVARIABLETHATSHOULDNTBENEEDED:FlxSprite;

	public var elapsedtime:Float = 0;

	public var elapsedexpungedtime:Float = 0;

	public var exbungo_funny:FlxSound;

	override public function create()
	{
		Paths.clearStoredMemory();

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default

		if (mania == 1) {
			notestuffs = ['LEFT', 'DOWN', 'UP', 'UP', 'RIGHT'];
			curmultDefine = [curmult[0], curmult[1], curmult[2], curmult[2], curmult[3]];
		}
		if (mania == 2) {
			notestuffs = ['LEFT', 'UP', 'RIGHT', 'LEFT', 'DOWN', 'RIGHT'];
			curmultDefine = [curmult[0], curmult[2], curmult[3], curmult[0], curmult[1], curmult[3]];
		}
		if (mania == 3) {
			notestuffs = ['LEFT', 'UP', 'RIGHT', 'UP', 'LEFT', 'DOWN', 'RIGHT'];
			curmultDefine = [curmult[0], curmult[2], curmult[3], curmult[2], curmult[0], curmult[1], curmult[3]];
		}
		if (mania == 4) {
			notestuffs = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'UP', 'LEFT', 'DOWN', 'UP', 'RIGHT'];
			curmultDefine = [curmult[0], curmult[1], curmult[2], curmult[3], curmult[2], curmult[0], curmult[1], curmult[2], curmult[3]];
		}
		if (mania == 5) {
			notestuffs = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'LEFT', 'DOWN', 'UP', 'RIGHT', 'LEFT', 'DOWN', 'UP', 'RIGHT'];
			curmultDefine = [curmult[0], curmult[1], curmult[2], curmult[3], curmult[0], curmult[1], curmult[2], curmult[3], curmult[0], curmult[1], curmult[2], curmult[3]];
		}

		dadStrumAmount = Main.keyAmmo[mania];
		playerStrumAmount = Main.keyAmmo[mania];

		if (formoverride == 'supershaggy') {
			shaggyT = new FlxTrail(boyfriend, null, 3, 6, 0.3, 0.002);
			bfTrailGroup.add(shaggyT);
		}
		if (formoverride == 'godshaggy') {
			legs = new FlxSprite(-850, -850);
			legs.frames = Paths.getSparrowAtlas('characters/shaggy_god', 'shared');
			legs.animation.addByPrefix('legs', "solo_legs", 30);
			legs.animation.play('legs');
			legs.antialiasing = true;
			legs.flipX = true;
			legs.updateHitbox();
			legs.offset.set(legs.frameWidth / 2, 10);
			legs.alpha = 0;

			legT = new FlxTrail(legs, null, 5, 7, 0.3, 0.001);
			bfTrailGroup.add(legT);

			shaggyT = new FlxTrail(boyfriend, null, 5, 7, 0.3, 0.001);
			bfTrailGroup.add(shaggyT);

			bfGroup.add(legs);
		}

		//Ratings
		ratingsData.push(new Rating('sick')); //default rating

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		this.bgColor = FlxColor.TRANSPARENT;
		camGame.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		mania = SONG.mania;
		keyAmmount = Note.keyAmmo[SONG.mania];

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = SONG.stage;
		//trace('stage is: ' + curStage);
		if(SONG.stage == null || SONG.stage.length < 1) {
			switch (songName)
			{
				case 'house' | 'insanity' | 'supernovae' | 'warmup':
					curStage = 'house';
				case 'polygonized':
					curStage = 'red-void';
				case 'bonus-song':
					curStage = 'inside-house';
				case 'blocked' | 'corn-theft' | 'maze':
					curStage = 'farm';
				case 'indignancy':
					curStage = 'farm-night';
				case 'splitathon' | 'mealie' | 'shredder':
					curStage = 'farm-night';
				case 'shredder' | 'greetings':
					curStage = 'festival';
				case 'interdimensional':
					curStage = 'interdimension-void';
				case 'rano':
					curStage = 'backyard';
				case 'cheating':
					curStage = 'green-void';
				case 'unfairness':
					curStage = 'glitchy-void';
				case 'exploitation':
					curStage = 'desktop';
				case 'kabunga':
					curStage = 'exbungo-land';
				case 'glitch' | 'memory':
					curStage = 'house-night';
				case 'secret':
					curStage = 'house-sunset';
				case 'vs-dave-rap' | 'vs-dave-rap-two':
					curStage = 'rapBattle';
				case 'recursed':
					curStage = 'freeplay';
				case 'roofs':
					curStage = 'roof';
				case 'bot-trot':
					curStage = 'bedroom';
				case 'escape-from-california':
					curStage = 'desert';
				case 'master':
					curStage = 'master';
				case 'overdrive':
					curStage = 'overdrive';
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				case 'ugh' | 'guns' | 'stress':
					curStage = 'tank';
				default:
					curStage = 'stage';
			}
		}
		SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxTypedSpriteGroup<FlxPerspectiveSprite>(DAD_X, DAD_Y);
		trailGroup = new FlxTypedSpriteGroup<FlxPerspectiveTrail>(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		var sprites:FlxTypedGroup<BGSprite> = new FlxTypedGroup<BGSprite>();
		var bgZoom:Float = 0.7;
		var stageName:String = '';
        var bgName:String = '';
        var revertedBG:Bool = false;
		switch (curStage)
		{
			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
				dadbattleSmokes = new FlxSpriteGroup(); //troll'd

			case 'spooky': //Week 2
				if(!ClientPrefs.lowQuality) {
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				} else {
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				//PRECACHE SOUNDS
				precacheList.set('thunder_1', 'sound');
				precacheList.set('thunder_2', 'sound');

			case 'philly': //Week 3
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}

				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
				phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
				phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
				phillyWindow.updateHitbox();
				add(phillyWindow);
				phillyWindow.alpha = 0;

				if(!ClientPrefs.lowQuality) {
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('philly/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				phillyStreet = new BGSprite('philly/street', -40, 50);
				add(phillyStreet);

			case 'limo': //Week 4
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if(!ClientPrefs.lowQuality) {
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					//PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					//PRECACHE SOUND
					precacheList.set('dancerdeath', 'sound');
				}

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall': //Week 5 - Cocoa, Eggnog
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if(!ClientPrefs.lowQuality) {
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				precacheList.set('Lights_Shut_off', 'sound');

			case 'mallEvil': //Week 5 - Winter Horrorland
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

			case 'school': //Week 6 - Senpai, Roses
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if(!ClientPrefs.lowQuality) {
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if(!ClientPrefs.lowQuality) {
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if(!ClientPrefs.lowQuality) {
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

			case 'schoolEvil': //Week 6 - Thorns
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				/*if(!ClientPrefs.lowQuality) { //Does this even do something?
					var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
					var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);
				}*/
				var posX = 400;
				var posY = 200;
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				} else {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}

			case 'tank': //Week 7 - Ugh, Guns, Stress
				var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
				add(sky);

				if(!ClientPrefs.lowQuality)
				{
					var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);
					add(clouds);

					var mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();
					add(mountains);

					var buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();
					add(buildings);
				}

				var ruins:BGSprite = new BGSprite('tankRuins',-200,0,.35,.35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();
				add(ruins);

				if(!ClientPrefs.lowQuality)
				{
					var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);
					var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);

					tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tankWatchtower);
				}

				tankGround = new BGSprite('tankRolling', 300, 300, 0.5, 0.5,['BG tank w lighting'], true);
				add(tankGround);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				var ground:BGSprite = new BGSprite('tankGround', -420, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				add(ground);
				moveTank();

				foregroundSprites = new FlxTypedGroup<BGSprite>();
				foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
				foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
				foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));

			case 'house' | 'house-night' | 'house-sunset':
				bgZoom = 0.8;
				
				var skyType:String = '';
				var assetType:String = '';
				switch (bgName)
				{
					case 'house':
						stageName = 'daveHouse';
						skyType = 'sky';
					case 'house-night':
						stageName = 'daveHouse_night';
						skyType = 'sky_night';
						assetType = 'night/';
					case 'house-sunset':
						stageName = 'daveHouse_sunset';
						skyType = 'sky_sunset';
				}
				var bg:BGSprite = new BGSprite('bg', -600, -300, Paths.image('backgrounds/shared/${skyType}'), null, 0.6, 0.6);
				sprites.add(bg);
				add(bg);
				
				var stageHills:BGSprite = new BGSprite('stageHills', -834, -159, Paths.image('backgrounds/dave-house/${assetType}hills'), null, 0.7, 0.7);
				sprites.add(stageHills);
				add(stageHills);

				var grassbg:BGSprite = new BGSprite('grassbg', -1205, 580, Paths.image('backgrounds/dave-house/${assetType}grass bg'), null);
				sprites.add(grassbg);
				add(grassbg);
	
				var gate:BGSprite = new BGSprite('gate', -755, 250, Paths.image('backgrounds/dave-house/${assetType}gate'), null);
				sprites.add(gate);
				add(gate);
	
				var stageFront:BGSprite = new BGSprite('stageFront', -832, 505, Paths.image('backgrounds/dave-house/${assetType}grass'), null);
				sprites.add(stageFront);
				add(stageFront);

				if (SONG.song.toLowerCase() == 'insanity' || localFunny == CharacterFunnyEffect.Recurser)
				{
					var bg:BGSprite = new BGSprite('bg', -600, -200, Paths.image('backgrounds/void/redsky_insanity'), null, 1, 1, true, true);
					bg.alpha = 0.75;
					bg.visible = false;
					add(bg);
					// below code assumes shaders are always enabled which is bad
					voidShader(bg);
				}

				var variantColor = getBackgroundColor(stageName);
				if (stageName != 'daveHouse_night')
				{
					stageHills.color = variantColor;
					grassbg.color = variantColor;
					gate.color = variantColor;
					stageFront.color = variantColor;
				}
			case 'inside-house':
				bgZoom = 0.6;
				stageName = 'insideHouse';

				var bg:BGSprite = new BGSprite('bg', -1000, -350, Paths.image('backgrounds/inside_house'), null);
				sprites.add(bg);
				add(bg);

			case 'farm' | 'farm-night' | 'farm-sunset':
				bgZoom = 0.8;

				switch (bgName.toLowerCase())
				{
					case 'farm-night':
						stageName = 'bambiFarmNight';
					case 'farm-sunset':
						stageName = 'bambiFarmSunset';
					default:
						stageName = 'bambiFarm';
				}
	
				var skyType:String = stageName == 'bambiFarmNight' ? 'sky_night' : stageName == 'bambiFarmSunset' ? 'sky_sunset' : 'sky';
				
				var bg:BGSprite = new BGSprite('bg', -600, -200, Paths.image('backgrounds/shared/' + skyType), null, 0.6, 0.6);
				sprites.add(bg);
				add(bg);

				if (SONG.song.toLowerCase() == 'maze')
				{
					var sunsetBG:BGSprite = new BGSprite('sunsetBG', -600, -200, Paths.image('backgrounds/shared/sky_sunset'), null, 0.6, 0.6);
					sunsetBG.alpha = 0;
					sprites.add(sunsetBG);
					add(sunsetBG);

					var nightBG:BGSprite = new BGSprite('nightBG', -600, -200, Paths.image('backgrounds/shared/sky_night'), null, 0.6, 0.6);
					nightBG.alpha = 0;
					sprites.add(nightBG);
					add(nightBG);
					if (isStoryMode)
					{
						health -= 0.2;
					}
				}
				var flatgrass:BGSprite = new BGSprite('flatgrass', 350, 75, Paths.image('backgrounds/farm/gm_flatgrass'), null, 0.65, 0.65);
				flatgrass.setGraphicSize(Std.int(flatgrass.width * 0.34));
				flatgrass.updateHitbox();
				sprites.add(flatgrass);
				
				var hills:BGSprite = new BGSprite('hills', -173, 100, Paths.image('backgrounds/farm/orangey hills'), null, 0.65, 0.65);
				sprites.add(hills);
				
				var farmHouse:BGSprite = new BGSprite('farmHouse', 100, 125, Paths.image('backgrounds/farm/funfarmhouse', 'shared'), null, 0.7, 0.7);
				farmHouse.setGraphicSize(Std.int(farmHouse.width * 0.9));
				farmHouse.updateHitbox();
				sprites.add(farmHouse);

				var grassLand:BGSprite = new BGSprite('grassLand', -600, 500, Paths.image('backgrounds/farm/grass lands', 'shared'), null);
				sprites.add(grassLand);

				var cornFence:BGSprite = new BGSprite('cornFence', -400, 200, Paths.image('backgrounds/farm/cornFence', 'shared'), null);
				sprites.add(cornFence);
				
				var cornFence2:BGSprite = new BGSprite('cornFence2', 1100, 200, Paths.image('backgrounds/farm/cornFence2', 'shared'), null);
				sprites.add(cornFence2);

				var bagType = FlxG.random.int(0, 1000) == 0 ? 'popeye' : 'cornbag';
				var cornBag:BGSprite = new BGSprite('cornFence2', 1200, 550, Paths.image('backgrounds/farm/$bagType', 'shared'), null);
				sprites.add(cornBag);
				
				var sign:BGSprite = new BGSprite('sign', 0, 350, Paths.image('backgrounds/farm/sign', 'shared'), null);
				sprites.add(sign);

				var variantColor:FlxColor = getBackgroundColor(stageName);
				
				flatgrass.color = variantColor;
				hills.color = variantColor;
				farmHouse.color = variantColor;
				grassLand.color = variantColor;
				cornFence.color = variantColor;
				cornFence2.color = variantColor;
				cornBag.color = variantColor;
				sign.color = variantColor;
				
				add(flatgrass);
				add(hills);
				add(farmHouse);
				add(grassLand);
				add(cornFence);
				add(cornFence2);
				add(cornBag);
				add(sign);

				if (['blocked', 'corn-theft', 'maze', 'mealie', 'indignancy'].contains(SONG.song.toLowerCase()) && !MathGameState.failedGame && FlxG.random.int(0, 4) == 0)
				{
					FlxG.mouse.visible = true;
					baldi = new BGSprite('baldi', 400, 110, Paths.image('backgrounds/farm/baldo', 'shared'), null, 0.65, 0.65);
					baldi.setGraphicSize(Std.int(baldi.width * 0.31));
					baldi.updateHitbox();
					baldi.color = variantColor;
					sprites.insert(members.indexOf(hills), baldi);
					insert(members.indexOf(hills), baldi);
				}

				if (SONG.song.toLowerCase() == 'splitathon')
				{
					var picnic:BGSprite = new BGSprite('picnic', 1050, 650, Paths.image('backgrounds/farm/picnic_towel_thing', 'shared'), null);
					sprites.insert(sprites.members.indexOf(cornBag), picnic);
					picnic.color = variantColor;
					insert(members.indexOf(cornBag), picnic);
				}
			case 'festival':
				bgZoom = 0.7;
				stageName = 'festival';
				
				var mainChars:Array<Dynamic> = null;
				switch (SONG.song.toLowerCase())
				{
					case 'shredder':
						mainChars = [
							//char name, prefix, size, x, y, flip x
							['dave', 'idle', 0.8, 175, 100],
							['tristan', 'bop', 0.4, 800, 325]
						];
					case 'greetings':
						if (isGreetingsCutscene)
						{
							mainChars = [
								['bambi', 'bambi idle', 0.9, 400, 350],
								['tristan', 'bop', 0.4, 800, 325]
							];
						}
						else
						{
							mainChars = [
								['dave', 'idle', 0.8, 175, 100],
								['bambi', 'bambi idle', 0.9, 700, 350],
							];
						}
					case 'interdimensional':
						mainChars = [
							['bambi', 'bambi idle', 0.9, 400, 350],
							['tristan', 'bop', 0.4, 800, 325]
						];
				}
				var bg:BGSprite = new BGSprite('bg', -400, -230, Paths.image('backgrounds/shared/sky_festival'), null, 0.6, 0.6);
				sprites.add(bg);
				add(bg);

				var flatGrass:BGSprite = new BGSprite('flatGrass', 800, -100, Paths.image('backgrounds/festival/gm_flatgrass'), null, 0.7, 0.7);
				sprites.add(flatGrass);
				add(flatGrass);

				var farmHouse:BGSprite = new BGSprite('farmHouse', -300, -150, Paths.image('backgrounds/festival/farmHouse'), null, 0.7, 0.7);
				sprites.add(farmHouse);
				add(farmHouse);
				
				var hills:BGSprite = new BGSprite('hills', -1000, -100, Paths.image('backgrounds/festival/hills'), null, 0.7, 0.7);
				sprites.add(hills);
				add(hills);

				var corn:BGSprite = new BGSprite('corn', -1000, 120, 'backgrounds/festival/corn', [
					new Animation('corn', 'idle', 5, true, [false, false])
				], 0.85, 0.85, true, true);
				corn.animation.play('corn');
				sprites.add(corn);
				add(corn);

				var cornGlow:BGSprite = new BGSprite('cornGlow', -1000, 120, 'backgrounds/festival/cornGlow', [
					new Animation('cornGlow', 'idle', 5, true, [false, false])
				], 0.85, 0.85, true, true);
				cornGlow.blend = BlendMode.ADD;
				cornGlow.animation.play('cornGlow');
				sprites.add(cornGlow);
				add(cornGlow);
				
				var backGrass:BGSprite = new BGSprite('backGrass', -1000, 475, Paths.image('backgrounds/festival/backGrass'), null, 0.85, 0.85);
				sprites.add(backGrass);
				add(backGrass);
				
				var crowd = new BGSprite('crowd', -500, -150, 'backgrounds/festival/crowd', [
					new Animation('idle', 'crowdDance', 24, true, [false, false])
				], 0.85, 0.85, true, true);
				crowd.animation.play('idle');
				sprites.add(crowd);
				crowdPeople.add(crowd);
				add(crowd);
				
				for (i in 0...mainChars.length)
				{					
					var crowdChar = new BGSprite(mainChars[i][0], mainChars[i][3], mainChars[i][4], 'backgrounds/festival/mainCrowd/${mainChars[i][0]}', [
						new Animation('idle', mainChars[i][1], 24, false, [false, false], null)
					], 0.85, 0.85, true, true);
					crowdChar.setGraphicSize(Std.int(crowdChar.width * mainChars[i][2]));
					crowdChar.updateHitbox();
					sprites.add(crowdChar);
					crowdPeople.add(crowdChar);
					add(crowdChar);
				}
				
				var frontGrass:BGSprite = new BGSprite('frontGrass', -1300, 600, Paths.image('backgrounds/festival/frontGrass'), null, 1, 1);
				sprites.add(frontGrass);
				add(frontGrass);

				var stageGlow:BGSprite = new BGSprite('stageGlow', -450, 300, 'backgrounds/festival/generalGlow', [
					new Animation('glow', 'idle', 5, true, [false, false])
				], 0, 0, true, true);
				stageGlow.blend = BlendMode.ADD;
				stageGlow.animation.play('glow');
				sprites.add(stageGlow);
				add(stageGlow);

			case 'backyard':
				bgZoom = 0.7;
				stageName = 'backyard';

				var festivalSky:BGSprite = new BGSprite('bg', -400, -400, Paths.image('backgrounds/shared/sky_festival'), null, 0.6, 0.6);
				sprites.add(festivalSky);
				add(festivalSky);

				if (SONG.song.toLowerCase() == 'rano')
				{
					var sunriseBG:BGSprite = new BGSprite('sunriseBG', -600, -400, Paths.image('backgrounds/shared/sky_sunrise'), null, 0.6, 0.6);
					sunriseBG.alpha = 0;
					sprites.add(sunriseBG);
					add(sunriseBG);

					var skyBG:BGSprite = new BGSprite('bg', -600, -400, Paths.image('backgrounds/shared/sky'), null, 0.6, 0.6);
					skyBG.alpha = 0;
					sprites.add(skyBG);
					add(skyBG);
				}

				var hills:BGSprite = new BGSprite('hills', -1330, -432, Paths.image('backgrounds/backyard/hills', 'shared'), null, 0.75, 0.75, true);
				sprites.add(hills);
				add(hills);

				var grass:BGSprite = new BGSprite('grass', -800, 150, Paths.image('backgrounds/backyard/supergrass', 'shared'), null, 1, 1, true);
				sprites.add(grass);
				add(grass);

				var gates:BGSprite = new BGSprite('gates', 564, -33, Paths.image('backgrounds/backyard/gates', 'shared'), null, 1, 1, true);
				sprites.add(gates);
				add(gates);
				
				var bear:BGSprite = new BGSprite('bear', -1035, -710, Paths.image('backgrounds/backyard/bearDude', 'shared'), null, 0.95, 0.95, true);
				sprites.add(bear);
				add(bear);

				var house:BGSprite = new BGSprite('house', -1025, -323, Paths.image('backgrounds/backyard/house', 'shared'), null, 0.95, 0.95, true);
				sprites.add(house);
				add(house);

				var grill:BGSprite = new BGSprite('grill', -489, 452, Paths.image('backgrounds/backyard/grill', 'shared'), null, 0.95, 0.95, true);
				sprites.add(grill);
				add(grill);

				var variantColor = getBackgroundColor(stageName);

				hills.color = variantColor;
				bear.color = variantColor;
				grass.color = variantColor;
				gates.color = variantColor;
				house.color = variantColor;
				grill.color = variantColor;
			case 'desktop':
				bgZoom = 0.5;
				stageName = 'desktop';

				expungedBG = new BGSprite('void', -600, -200, '', null, 1, 1, false, true);
				expungedBG.loadGraphic(Paths.image('backgrounds/void/exploit/creepyRoom', 'shared'));
				expungedBG.setPosition(0, 200);
				expungedBG.setGraphicSize(Std.int(expungedBG.width * 2));
				expungedBG.scrollFactor.set();
				expungedBG.antialiasing = false;
				sprites.add(expungedBG);
				add(expungedBG);
				voidShader(expungedBG);
			case 'red-void' | 'green-void' | 'glitchy-void':
				bgZoom = 0.7;

				var bg:BGSprite = new BGSprite('void', -600, -200, '', null, 1, 1, false, true);
				
				switch (bgName.toLowerCase())
				{
					case 'red-void':
						bgZoom = 0.8;
						bg.loadGraphic(Paths.image('backgrounds/void/redsky', 'shared'));
						stageName = 'daveEvilHouse';
					case 'green-void':
						stageName = 'cheating';
						bg.loadGraphic(Paths.image('backgrounds/void/cheater'));
						bg.setPosition(-700, -350);
						bg.setGraphicSize(Std.int(bg.width * 2));
					case 'glitchy-void':
						bg.loadGraphic(Paths.image('backgrounds/void/scarybg'));
						bg.setPosition(0, 200);
						bg.setGraphicSize(Std.int(bg.width * 3));
						stageName = 'unfairness';
				}
				sprites.add(bg);
				add(bg);
				voidShader(bg);
			case 'interdimension-void':
				bgZoom = 0.6;
				stageName = 'interdimension';

				var bg:BGSprite = new BGSprite('void', -700, -350, Paths.image('backgrounds/void/interdimensions/interdimensionVoid'), null, 1, 1, false, true);
				bg.setGraphicSize(Std.int(bg.width * 1.75));
				sprites.add(bg);
				add(bg);

				voidShader(bg);
				
				interdimensionBG = bg;
			case 'exbungo-land':
				bgZoom = 0.7;
				stageName = 'kabunga';
				
				var bg:BGSprite = new BGSprite('bg', -320, -160, Paths.image('backgrounds/void/exbongo/Exbongo'), null, 1, 1, true, true);
				bg.setGraphicSize(Std.int(bg.width * 1.5));
				sprites.add(bg);
				add(bg);

				var circle:BGSprite = new BGSprite('circle', -30, 550, Paths.image('backgrounds/void/exbongo/Circle'), null);
				sprites.add(circle);	
				add(circle);

				place = new BGSprite('place', 860, -15, Paths.image('backgrounds/void/exbongo/Place'), null);
				sprites.add(place);	
				add(place);
				
				voidShader(bg);
			case 'rapBattle':
				bgZoom = 1;
				stageName = 'rapLand';

				var bg:BGSprite = new BGSprite('rapBG', -640, -360, Paths.image('backgrounds/rapBattle'), null);
				sprites.add(bg);
				add(bg);
			case 'freeplay':
				bgZoom = 0.4;
				stageName = 'freeplay';
				
				darkSky = new BGSprite('darkSky', darkSkyStartPos, 0, Paths.image('recursed/darkSky'), null, 1, 1, true);
				darkSky.scale.set((1 / bgZoom) * 2, 1 / bgZoom);
				darkSky.updateHitbox();
				darkSky.y = (FlxG.height - darkSky.height) / 2;
				add(darkSky);
				
				darkSky2 = new BGSprite('darkSky', darkSky.x - darkSky.width, 0, Paths.image('recursed/darkSky'), null, 1, 1, true);
				darkSky2.scale.set((1 / bgZoom) * 2, 1 / bgZoom);
				darkSky2.updateHitbox();
				darkSky2.x = darkSky.x - darkSky.width;
				darkSky2.y = (FlxG.height - darkSky2.height) / 2;
				add(darkSky2);

				freeplayBG = new BGSprite('freeplay', 0, 0, daveBG, null, 0, 0, true);
				freeplayBG.setGraphicSize(Std.int(freeplayBG.width * 2));
				freeplayBG.updateHitbox();
				freeplayBG.screenCenter();
				freeplayBG.color = FlxColor.multiply(0xFF4965FF, FlxColor.fromRGB(44, 44, 44));
				freeplayBG.alpha = 0;
				add(freeplayBG);
				
				charBackdrop = new FlxBackdrop(Paths.image('recursed/daveScroll'), 1, 1, true, true);
				charBackdrop.antialiasing = true;
				charBackdrop.scale.set(2, 2);
				charBackdrop.screenCenter();
				charBackdrop.color = FlxColor.multiply(charBackdrop.color, FlxColor.fromRGB(44, 44, 44));
				charBackdrop.alpha = 0;
				add(charBackdrop);


				initAlphabet(daveSongs);
			case 'roof':
				bgZoom = 0.8;
				stageName = 'roof';
				var roof:BGSprite = new BGSprite('roof', -584, -397, Paths.image('backgrounds/gm_house5', 'shared'), null, 1, 1, true);
				roof.setGraphicSize(Std.int(roof.width * 2));
				roof.antialiasing = false;
				add(roof);
			case 'bedroom':
				bgZoom = 0.8;
				stageName = 'bedroom';
				
				var sky:BGSprite = new BGSprite('nightSky', -285, 318, Paths.image('backgrounds/bedroom/sky', 'shared'), null, 0.8, 0.8, true);
				sprites.add(sky);
				add(sky);

				var bg:BGSprite = new BGSprite('bg', -687, 0, Paths.image('backgrounds/bedroom/bg', 'shared'), null, 1, 1, true);
				sprites.add(bg);
				add(bg);

				var baldi:BGSprite = new BGSprite('baldi', 788, 788, Paths.image('backgrounds/bedroom/bed', 'shared'), null, 1, 1, true);
				sprites.add(baldi);
				add(baldi);

				tristanInBotTrot = new BGSprite('tristan', 888, 688, 'backgrounds/bedroom/TristanSitting', [
					new Animation('idle', 'daytime', 24, true, [false, false]),
					new Animation('idleNight', 'nighttime', 24, true, [false, false])
				], 1, 1, true, true);
				tristanInBotTrot.setGraphicSize(Std.int(tristanInBotTrot.width * 0.8));
				tristanInBotTrot.animation.play('idle');
				add(tristanInBotTrot);
				if (formoverride == 'tristan' || formoverride == 'tristan-golden' || formoverride == 'tristan-golden-glowing') {
					remove(tristanInBotTrot);	
			    }
			case 'office':
				bgZoom = 0.9;
				stageName = 'office';
				
				var backFloor:BGSprite = new BGSprite('backFloor', -500, -310, Paths.image('backgrounds/office/backFloor'), null, 1, 1);
				sprites.add(backFloor);
				add(backFloor);
			case 'desert':
				bgZoom = 0.5;
				stageName = 'desert';

				var bg:BGSprite = new BGSprite('bg', -900, -400, Paths.image('backgrounds/shared/sky'), null, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 2));
				bg.updateHitbox();
				sprites.add(bg);
				add(bg);

				var sunsetBG:BGSprite = new BGSprite('sunsetBG', -900, -400, Paths.image('backgrounds/shared/sky_sunset'), null, 0.2, 0.2);
				sunsetBG.setGraphicSize(Std.int(sunsetBG.width * 2));
				sunsetBG.updateHitbox();
				sunsetBG.alpha = 0;
				sprites.add(sunsetBG);
				add(sunsetBG);
				
				var nightBG:BGSprite = new BGSprite('nightBG', -900, -400, Paths.image('backgrounds/shared/sky_night'), null, 0.2, 0.2);
				nightBG.setGraphicSize(Std.int(nightBG.width * 2));
				nightBG.updateHitbox();
				nightBG.alpha = 0;
				sprites.add(nightBG);
				add(nightBG);
				
				desertBG = new BGSprite('desert', -786, -500, Paths.image('backgrounds/wedcape_from_cali_backlground', 'shared'), null, 1, 1, true);
				desertBG.setGraphicSize(Std.int(desertBG.width * 1.2));
				desertBG.updateHitbox();
				sprites.add(desertBG);
				add(desertBG);

				desertBG2 = new BGSprite('desert2', desertBG.x - desertBG.width, desertBG.y, Paths.image('backgrounds/wedcape_from_cali_backlground', 'shared'), null, 1, 1, true);
				desertBG2.setGraphicSize(Std.int(desertBG2.width * 1.2));
				desertBG2.updateHitbox();
				sprites.add(desertBG2);
				add(desertBG2);
				
				sign = new BGSprite('sign', 500, 450, Paths.image('california/leavingCalifornia', 'shared'), null, 1, 1, true);
				sprites.add(sign);
				add(sign);

				train = new BGSprite('train', -800, 500, 'california/train', [
					new Animation('idle', 'trainRide', 24, true, [false, false])
				], 1, 1, true, true);
				train.animation.play('idle');
				train.setGraphicSize(Std.int(train.width * 2.5));
				train.updateHitbox();
				train.antialiasing = false;
				sprites.add(train);
				add(train);
			case 'master':
				bgZoom = 0.4;
				stageName = 'master';

				var space:BGSprite = new BGSprite('space', -1724, -971, Paths.image('backgrounds/shared/sky_space'), null, 1.2, 1.2);
				space.setGraphicSize(Std.int(space.width * 10));
				space.antialiasing = false;
				sprites.add(space);
				add(space);
	
				var land:BGSprite = new BGSprite('land', 675, 555, Paths.image('backgrounds/dave-house/land'), null, 0.9, 0.9);
				sprites.add(land);
				add(land);
			case 'overdrive':
				bgZoom = 0.8;
				stageName = 'overdrive';

				var stfu:BGSprite = new BGSprite('stfu', -583, -383, Paths.image('backgrounds/stfu'), null, 1, 1);
				sprites.add(stfu);
				add(stfu);
		}

		switch(Paths.formatToSongPath(SONG.song))
		{
			case 'stress':
				GameOverSubstate.characterName = 'bf-holding-gf-dead';
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup); //Needed for blammed lights

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		add(trailGroup);
		add(dadGroup);
		add(boyfriendGroup);

		switch(curStage)
		{
			case 'spooky':
				add(halloweenWhite);
			case 'tank':
				add(foregroundSprites);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end


		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush)
			luaArray.push(new FunkinLua(luaFile));
		#end

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				case 'tank':
					gfVersion = 'gf-tankmen';
				default:
					gfVersion = 'gf';
			}

			switch(Paths.formatToSongPath(SONG.song))
			{
				case 'stress':
					gfVersion = 'pico-speaker';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);

			if(gfVersion == 'pico-speaker')
			{
				if(!ClientPrefs.lowQuality)
				{
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetShit(20, 600, true);
					firstTank.strumTime = 10;
					tankmanRun.add(firstTank);

					for (i in 0...TankmenBG.animationNotes.length)
					{
						if(FlxG.random.bool(16)) {
							var tankBih = tankmanRun.recycle(TankmenBG);
							tankBih.strumTime = TankmenBG.animationNotes[i][0];
							tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
							tankmanRun.add(tankBih);
						}
					}
				}
			}
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		switch(curStage)
		{
			case 'limo':
				resetFastCar();
				addBehindGF(fastCar);

			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice
				addBehindDad(evilTrail);
		}



		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		renderedStrumLineNotes = new FlxTypedGroup<StrumNote>();

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();


		if (ClientPrefs.getGameplaySetting('opponentplay', false))
		{
			player = dad;
			opponent = boyfriend;
			currentPlayerStrums = opponentStrums;
			currentOpponentStrums = playerStrums;	
		}
		else 
		{
			player = boyfriend;
			opponent = dad;
			currentPlayerStrums = playerStrums;
			currentOpponentStrums = opponentStrums;
		}


		if (SONG.song.toLowerCase() == 'godspeed')
			vocalsToAdd = ['-opponent']; //put all in one thing because vocal crackling shit from resyncs

		// startCountdown();

		generateSong(SONG.song);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
			if(OpenFlAssets.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			#end
		}
		for (event in eventPushedMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_events/' + event + '.lua');
			if(OpenFlAssets.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			#end
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection();

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		renderedStrumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		add(renderedStrumLineNotes);
		add(grpNoteSplashes);
		add(notes);

		add(botplayTxt);


		if (god && !ClientPrefs.performanceMode)
		{
			camGame.setFilters([new ShaderFilter(chrom.shader)]);
			camHUD.setFilters([new ShaderFilter(chrom.shader)]);
			camOther.setFilters([new ShaderFilter(chrom.shader)]);
		}


		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/data/' + Paths.formatToSongPath(SONG.song) + '/' ));// using push instead of insert because these should run after everything else
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					if(gf != null) gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if(daSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);

				case 'ugh' | 'guns' | 'stress':
					tankIntro();

				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if(ClientPrefs.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');
		}

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnLuas('onCreatePost', []);

		super.create();

		Paths.clearUnusedMemory();

		for (key => type in precacheList)
		{
			//trace('Key $key is type $type');
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}
		CustomFadeTransition.nextCamera = camOther;

		if (!revertedBG)
		{
			defaultCamZoom = bgZoom;
			curStage = stageName;
		}

		return sprites;
	}
	function initAlphabet(songList:Array<String>)
	{
		for (letter in alphaCharacters)
		{
			alphaCharacters.remove(letter);
			remove(letter);
		}
		var startWidth = 640;
		var width:Float = startWidth;
		var row:Float = 0;
		
		while (row < FlxG.height)
		{
			while (width < FlxG.width * 2.5)
			{
				for (i in 0...songList.length)
				{
					var curSong = songList[i];
					var song = new Alphabet(0, 0, curSong, true);
					song.x = width;
					song.y = row;

					width += song.width + 20;
					alphaCharacters.add(song);
					add(song);
					
					if (width > FlxG.width * 2.5)
					{
						break;
					}
				}
			}
			row += 120;
			width = startWidth;
		}
		for (char in alphaCharacters)
		{
			for (letter in char.characters)
			{
				letter.alpha = 0;
			}
		}
		for (char in alphaCharacters)
		{
			char.unlockY = true;
			for (alphaChar in char.characters)
			{
				alphaChar.velocity.set(new FlxRandom().float(-50, 50), new FlxRandom().float(-50, 50));
				alphaChar.angularVelocity = new FlxRandom().int(30, 50);

				alphaChar.setPosition(new FlxRandom().float(-FlxG.width / 2, FlxG.width * 2.5), new FlxRandom().float(0, FlxG.height * 2.5));}
			}
		}
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	function voidShader(background:BGSprite)
	{
		#if SHADERS_ENABLED
		var testshader:Shaders.GlitchEffect = new Shaders.GlitchEffect();
		testshader.waveAmplitude = 0.1;
		testshader.waveFrequency = 5;
		testshader.waveSpeed = 2;
		
		background.shader = testshader.shader;
		#end
		curbg = background;
	}
	function changeInterdimensionBg(type:String)
	{
		for (sprite in backgroundSprites)
		{
			backgroundSprites.remove(sprite);
			remove(sprite);
		}
		interdimensionBG = new BGSprite('void', -600, -200, '', null, 1, 1, false, true);
		backgroundSprites.add(interdimensionBG);
		add(interdimensionBG);
		switch (type)
		{
			case 'interdimension-void':
				interdimensionBG.loadGraphic(Paths.image('backgrounds/void/interdimensions/interdimensionVoid'));
				interdimensionBG.setPosition(-700, -350);
				interdimensionBG.setGraphicSize(Std.int(interdimensionBG.width * 1.75));
			case 'spike-void':
				interdimensionBG.loadGraphic(Paths.image('backgrounds/void/interdimensions/spike'));
				interdimensionBG.setPosition(-200, 0);
				interdimensionBG.setGraphicSize(Std.int(interdimensionBG.width * 3));
			case 'darkSpace':
				interdimensionBG.loadGraphic(Paths.image('backgrounds/void/interdimensions/darkSpace'));
				interdimensionBG.setPosition(-200, 0);
				interdimensionBG.setGraphicSize(Std.int(interdimensionBG.width * 2.75));
			case 'hexagon-void':
				interdimensionBG.loadGraphic(Paths.image('backgrounds/void/interdimensions/hexagon'));
				interdimensionBG.setPosition(-200, 0);
				interdimensionBG.setGraphicSize(Std.int(interdimensionBG.width * 3));
			case 'nimbi-void':
				interdimensionBG.loadGraphic(Paths.image('backgrounds/void/interdimensions/nimbi/nimbiVoid'));
				interdimensionBG.setPosition(-200, 0);
				interdimensionBG.setGraphicSize(Std.int(interdimensionBG.width * 2.75));

				nimbiLand = new BGSprite('nimbiLand', 200, 100, Paths.image('backgrounds/void/interdimensions/nimbi/nimbi_land'), null, 1, 1, false, true);
				backgroundSprites.add(nimbiLand);
				nimbiLand.setGraphicSize(Std.int(nimbiLand.width * 1.5));
				insert(members.indexOf(flyingBgChars), nimbiLand);

				nimbiSign = new BGSprite('sign', 800, -73, Paths.image('backgrounds/void/interdimensions/nimbi/sign'), null, 1, 1, false, true);
				backgroundSprites.add(nimbiSign);
				nimbiSign.setGraphicSize(Std.int(nimbiSign.width * 0.2));
				insert(members.indexOf(flyingBgChars), nimbiSign);
		}
		voidShader(interdimensionBG);
		currentInterdimensionBG = type;
	}
	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));

		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) {
			doPush = true;
		}
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:MP4Handler = new MP4Handler();
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			startAndEnd();
			return;
		}
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function tankIntro()
	{
		var cutsceneHandler:CutsceneHandler = new CutsceneHandler();

		var songName:String = Paths.formatToSongPath(SONG.song);
		dadGroup.alpha = 0.00001;
		camHUD.visible = false;
		//inCutscene = true; //this would stop the camera movement, oops

		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
		tankman.antialiasing = ClientPrefs.globalAntialiasing;
		addBehindDad(tankman);
		cutsceneHandler.push(tankman);

		var tankman2:FlxSprite = new FlxSprite(16, 312);
		tankman2.antialiasing = ClientPrefs.globalAntialiasing;
		tankman2.alpha = 0.000001;
		cutsceneHandler.push(tankman2);
		var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
		gfDance.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfDance);
		var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
		gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfCutscene);
		var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
		picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(picoCutscene);
		var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(boyfriendCutscene);

		cutsceneHandler.finishCallback = function()
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			moveCamera(true);
			startCountdown();

			dadGroup.alpha = 1;
			camHUD.visible = true;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
		};

		camFollow.set(dad.x + 280, dad.y + 170);
		switch(songName)
		{
			case 'ugh':
				cutsceneHandler.endTime = 12;
				cutsceneHandler.music = 'DISTORTO';
				precacheList.set('wellWellWell', 'sound');
				precacheList.set('killYou', 'sound');
				precacheList.set('bfBeep', 'sound');

				var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell'));
				FlxG.sound.list.add(wellWellWell);

				tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankman.animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;

				// Well well well, what do we got here?
				cutsceneHandler.timer(0.1, function()
				{
					wellWellWell.play(true);
				});

				// Move camera to BF
				cutsceneHandler.timer(3, function()
				{
					camFollow.x += 750;
					camFollow.y += 100;
				});

				// Beep!
				cutsceneHandler.timer(4.5, function()
				{
					boyfriend.playAnim('singUP', true);
					boyfriend.specialAnim = true;
					FlxG.sound.play(Paths.sound('bfBeep'));
				});

				// Move camera to Tankman
				cutsceneHandler.timer(6, function()
				{
					camFollow.x -= 750;
					camFollow.y -= 100;

					// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
					tankman.animation.play('killYou', true);
					FlxG.sound.play(Paths.sound('killYou'));
				});

			case 'guns':
				cutsceneHandler.endTime = 11.5;
				cutsceneHandler.music = 'DISTORTO';
				tankman.x += 40;
				tankman.y += 10;
				precacheList.set('tankSong2', 'sound');

				var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
				FlxG.sound.list.add(tightBars);

				tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
				tankman.animation.play('tightBars', true);
				boyfriend.animation.curAnim.finish();

				cutsceneHandler.onStart = function()
				{
					tightBars.play(true);
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
				};

				cutsceneHandler.timer(4, function()
				{
					gf.playAnim('sad', true);
					gf.animation.finishCallback = function(name:String)
					{
						gf.playAnim('sad', true);
					};
				});

			case 'stress':
				cutsceneHandler.endTime = 35.5;
				tankman.x -= 54;
				tankman.y -= 14;
				gfGroup.alpha = 0.00001;
				boyfriendGroup.alpha = 0.00001;
				camFollow.set(dad.x + 400, dad.y + 170);
				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.y += 100;
				});
				precacheList.set('stressCutscene', 'sound');

				tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
				addBehindDad(tankman2);

				if (!ClientPrefs.lowQuality)
				{
					gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
					gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
					gfDance.animation.play('dance', true);
					addBehindGF(gfDance);
				}

				gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				gfCutscene.animation.play('dieBitch', true);
				gfCutscene.animation.pause();
				addBehindGF(gfCutscene);
				if (!ClientPrefs.lowQuality)
				{
					gfCutscene.alpha = 0.00001;
				}

				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				addBehindGF(picoCutscene);
				picoCutscene.alpha = 0.00001;

				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('idle', true);
				boyfriendCutscene.animation.curAnim.finish();
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);

				tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
				tankman.animation.play('godEffingDamnIt', true);

				var calledTimes:Int = 0;
				var zoomBack:Void->Void = function()
				{
					var camPosX:Float = 630;
					var camPosY:Float = 425;
					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);
					FlxG.camera.zoom = 0.8;
					cameraSpeed = 1;

					calledTimes++;
					if (calledTimes > 1)
					{
						foregroundSprites.forEach(function(spr:BGSprite)
						{
							spr.y -= 100;
						});
					}
				}

				cutsceneHandler.onStart = function()
				{
					cutsceneSnd.play(true);
				};

				cutsceneHandler.timer(15.2, function()
				{
					FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);
					gfCutscene.animation.finishCallback = function(name:String)
					{
						if(name == 'dieBitch') //Next part
						{
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						}
						else
						{
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.animation.play('anim', true);

							boyfriendGroup.alpha = 1;
							boyfriendCutscene.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String)
							{
								if(name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
								}
							};

							picoCutscene.animation.finishCallback = function(name:String)
							{
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};
							gfCutscene.animation.finishCallback = null;
						}
					};
				});

				cutsceneHandler.timer(17.5, function()
				{
					zoomBack();
				});

				cutsceneHandler.timer(19.5, function()
				{
					tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankman2.animation.play('lookWhoItIs', true);
					tankman2.alpha = 1;
					tankman.visible = false;
				});

				cutsceneHandler.timer(20, function()
				{
					camFollow.set(dad.x + 500, dad.y + 170);
				});

				cutsceneHandler.timer(31.2, function()
				{
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = function(name:String)
					{
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
						}
					};

					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
				});

				cutsceneHandler.timer(32.2, function()
				{
					zoomBack();
				});
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', [], false);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);

			var under:Underlay = new Underlay(currentPlayerStrums);
			insert(0, under);




			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);


			if (SONG.mania == 2)
			{
				for (i in 0...keyAmmount)
				{
					var bind = new FlxText(currentPlayerStrums.members[i].x+(currentPlayerStrums.members[i].width/2), currentPlayerStrums.members[i].y+currentPlayerStrums.members[i].height, 20);
					bind.text = FlxKey.toStringMap.get(keysArray[i][0]);
					bind.x -= (bind.width/2);
					if (ClientPrefs.downScroll)
					{
						bind.y = currentPlayerStrums.members[i].y-currentPlayerStrums.members[i].height;
					}
					bind.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
					bind.borderSize = 2;
					bind.cameras = [camHUD];
					add(bind);
					bindPopups.push(bind);
	
					bind.alpha = 0;
					FlxTween.tween(bind, {y: bind.y + 10,alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
				}
				new FlxTimer().start(4, function(tmr:FlxTimer)
				{
					for (i in 0...bindPopups.length)
					{
						var bind = bindPopups[i];
						FlxTween.tween(bind, {y: bind.y - 10,alpha: 0}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i), onComplete: function(twn:FlxTween) {
							remove(bind);
							bind.kill();
						}});
					}
				});
			}

			var swagCounter:Int = 0;


			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if(curStage == 'mall') {
					if(!ClientPrefs.lowQuality)
						upperBoppers.dance(true);

					bottomBoppers.dance(true);
					santa.dance(true);
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.cameras = [camHUD];
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						insert(members.indexOf(notes), countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.cameras = [camHUD];
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						insert(members.indexOf(notes), countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.cameras = [camHUD];
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						insert(members.indexOf(notes), countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
					case 4:
				}

				notes.forEachAlive(function(note:Note) {
					if(ClientPrefs.opponentStrums || Note.checkMustPress(note.mustPress))
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(ClientPrefs.middleScroll && Note.checkMustPress(!note.mustPress)) {
							note.alpha *= 0.35;
						}
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad (obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function updateScore(miss:Bool = false)
	{
		scoreTxt.text = 'Score: ' + songScore
		+ ' | Misses: ' + songMisses
		+ ' | Rating: ' + ratingName
		+ (ratingName != '?' ? ' (${Highscore.floorDecimal(ratingPercent * 100, 2)}%) - $ratingFC' : '');

		if(ClientPrefs.scoreZoom && !miss && !cpuControlled)
		{
			if(scoreTxtTween != null) {
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();
		for (v in extraVocals)
			v.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
		}
		for (v in extraVocals)
			if (Conductor.songPosition <= v.length)
				v.time = time;
		vocals.play();
		for (v in extraVocals)
			v.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = onSongComplete;
		vocals.play();
		for (v in extraVocals)
			v.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			for (v in extraVocals)
				v.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		switch(curStage)
		{
			case 'tank':
				if(!ClientPrefs.lowQuality) tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});
		}

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end



		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	public var vocalsToAdd:Array<String> = [];
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		for (i in vocalsToAdd)
		{
			var v = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song, i));
			FlxG.sound.list.add(v);
			if (v != null)
				extraVocals.push(v);
		}
			

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % keyAmmount);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > keyAmmount-1)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<keyAmmount));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<keyAmmount));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > Math.floor((keyAmmount-1)/2)) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > Math.floor((keyAmmount-1)/2)) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Dadbattle Spotlight':
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;

				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				add(dadbattleLight);
				add(dadbattleSmokes);

				var offsetX = 200;
				var smoke:BGSprite = new BGSprite('smoke', -1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				dadbattleSmokes.add(smoke);
				var smoke:BGSprite = new BGSprite('smoke', 1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				dadbattleSmokes.add(smoke);


			case 'Philly Glow':
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				insert(members.indexOf(phillyStreet), blammedLightsBlack);

				phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
				phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
				phillyWindowEvent.updateHitbox();
				phillyWindowEvent.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);


				phillyGlowGradient = new PhillyGlow.PhillyGlowGradient(-400, 225); //This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				if(!ClientPrefs.flashing) phillyGlowGradient.intendedAlpha = 0.7;

				precacheList.set('philly/particle', 'image'); //precache particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlow.PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua

	private function generateStaticArrows(player:Int, regenerate:Bool = false, fadeIn:Bool = true):Void
	{
		var note_order:Array<Int> = [0,1,2,3];
		if (mania == 1) note_order = [0, 1, 2, 3, 4];
		if (mania == 2) note_order = [0, 1, 2, 3, 4, 5];
		if (mania == 3) note_order = [0, 1, 2, 3, 4, 5, 6];
		if (mania == 4) note_order = [0, 1, 2, 3, 4, 5, 6, 7, 8];
		if (mania == 5) note_order = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
		if (localFunny == CharacterFunnyEffect.Bambi)
		{
			note_order = [2,2,2,2];
		}
		else if (localFunny == CharacterFunnyEffect.Tristan)
		{
			note_order = [0,3,2,1];
		}
		for (i in 0...Main.keyAmmo[mania])
		{
			var arrowType:Int = note_order[i];
			var strumType:String = '';
			if ((funnyFloatyBoys.contains(dad.curCharacter) || dad.curCharacter == "nofriend") && player == 0 || funnyFloatyBoys.contains(boyfriend.curCharacter) && player == 1)
			{
				strumType = '3D';
			}
			else
			{
				switch (curStage)
				{
					default:
						if (SONG.song.toLowerCase() == "overdrive")
							strumType = 'top10awesome';
				}
			}
			if (pressingKey5Global)
			{
				strumType = 'shape';
			}
			var babyArrow:StrumNote = new StrumNote(0, strumLine.y, strumType, arrowType, player == 1);

			if (!isStoryMode && fadeIn)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			babyArrow.x += Note.swagWidth * Math.abs(i);
			babyArrow.x += 78 + 78 / 4; // playerStrumAmount
			babyArrow.x += ((FlxG.width / 2) * player);
			babyArrow.x -= Note.posRest[mania];
			babyArrow.playAnim('static');
			
			babyArrow.baseX = babyArrow.x;
			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				dadStrums.add(babyArrow);
			}
			strumLineNotes.add(babyArrow);
		}
	}
	function generateGhNotes(player:Int)
	{
		for (i in 0...5)
		{
			var arrowType:Int = i;
			if (localFunny == CharacterFunnyEffect.Bambi)
			{
				arrowType = 2;
			}
			var babyArrow:StrumNote = new StrumNote(0, strumLine.y, 'gh', i, false);

			babyArrow.x += 160 * 0.7 * Math.abs(i);
			babyArrow.x += 78;
			babyArrow.baseX = babyArrow.x;
			dadStrums.add(babyArrow);
			strumLineNotes.add(babyArrow);
		}
	}
	function regenerateStaticArrows(player:Int, fadeIn = true)
	{
		switch (player)
		{
			case 0:
				dadStrums.forEach(function(spr:StrumNote)
				{
					dadStrums.remove(spr);
					strumLineNotes.remove(spr);
					remove(spr);
					spr.destroy();
				});
			case 1:
				playerStrums.forEach(function(spr:StrumNote)
				{
					playerStrums.remove(spr);
					strumLineNotes.remove(spr);
					remove(spr);
					spr.destroy();
				});
		}
		generateStaticArrows(player, false, fadeIn);
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.sineInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				for (v in extraVocals)
					v.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if(carTimer != null) carTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}
	public function throwThatBitchInThere(guyWhoComesIn:String = 'bambi', guyWhoFliesOut:String = 'dave')
	{
		hasTriggeredDumbshit = true;
		if(BAMBICUTSCENEICONHURHURHUR != null)
		{
			remove(BAMBICUTSCENEICONHURHURHUR);
		}
		BAMBICUTSCENEICONHURHURHUR = new HealthIcon(guyWhoComesIn, false);
		BAMBICUTSCENEICONHURHURHUR.changeState(iconP2.getState());
		BAMBICUTSCENEICONHURHURHUR.y = healthBar.y - (BAMBICUTSCENEICONHURHURHUR.height / 2);
		add(BAMBICUTSCENEICONHURHURHUR);
		BAMBICUTSCENEICONHURHURHUR.cameras = [camHUD];
		BAMBICUTSCENEICONHURHURHUR.x = -100;
		FlxTween.linearMotion(BAMBICUTSCENEICONHURHURHUR, -100, BAMBICUTSCENEICONHURHURHUR.y, iconP2.x, BAMBICUTSCENEICONHURHURHUR.y, 0.3, true, {ease: FlxEase.expoInOut});
		AUGHHHH = guyWhoComesIn;
		AHHHHH = guyWhoFliesOut;
		new FlxTimer().start(0.3, FlingCharacterIconToOblivionAndBeyond);
	}


	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			if(carTimer != null) carTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}

			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();
		for (v in extraVocals)
			v.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
		}
		for (v in extraVocals)
			if (Conductor.songPosition <= v.length)
				v.time = Conductor.songPosition;

		vocals.play();
		for (v in extraVocals)
			v.play();
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	override public function update(elapsed:Float)
	{
		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}*/
		callOnLuas('onUpdate', [elapsed]);

		if (god)
		{
			chrom.strength = FlxMath.lerp(chrom.strength, 0, elapsed*10);
			chrom.update(elapsed);
		}
		

		switch (curStage)
		{
			case 'tank':
				moveTank(elapsed);
			case 'schoolEvil':
				if(!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished) {
					bgGhouls.visible = false;
				}
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;

				if(phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.members.length-1;
					while (i > 0)
					{
						var particle = phillyGlowParticles.members[i];
						if(particle.alpha < 0)
						{
							particle.kill();
							phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}
						--i;
					}
				}
			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoParticles.forEach(function(spr:BGSprite) {
						if(spr.animation.curAnim.finished) {
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch(limoKillingState) {
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length) {
								if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 130) {
									switch(i) {
										case 0 | 3:
											if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if(limoMetalPole.x > FlxG.width * 2) {
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x > FlxG.width * 1.5) {
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if(limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x < -275) {
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if(Math.round(bgLimo.x) == -150) {
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if(limoKillingState > 2) {
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length) {
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if(heyTimer > 0) {
					heyTimer -= elapsed;
					if(heyTimer <= 0) {
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		trailGroup.sort(FlxPerspectiveSprite.sortByZTrail, FlxSort.ASCENDING);
		//dadGroup.sort(FlxPerspectiveSprite.sortByZ, FlxSort.ASCENDING);
		dadGroup.sort( 
			function(order:Int, sprite1:FlxPerspectiveSprite, sprite2:FlxPerspectiveSprite):Int
			{
				return FlxSort.byValues(order, sprite1.z, sprite2.z);
			},
		FlxSort.ASCENDING);
		notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		notes.sort(FlxPerspectiveSprite.sortByZ, FlxSort.ASCENDING);

		renderedStrumLineNotes.sort(    //sort by id first
			function(order:Int, sprite1:StrumNote, sprite2:StrumNote):Int
			{
				return FlxSort.byValues(order, sprite1.ID, sprite2.ID);
			},
		FlxSort.ASCENDING);
		renderedStrumLineNotes.sort(FlxPerspectiveSprite.sortByZ, FlxSort.ASCENDING); //then sort by z

		setOnLuas('curDecStep', curDecStep);
		setOnLuas('curDecBeat', curDecBeat);

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', [], false);
			if(ret != FunkinLua.Function_Stop) {
				openPauseMenu();
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}



		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (iconP2.isAnimated)
		{
			if (healthBar.percent > 80)
				iconP2.animation.play('losing');
			else
				iconP2.animation.play('normal');
		}
		else 
		{
			if (healthBar.percent > 80)
				iconP2.animation.curAnim.curFrame = 1;
			else
				iconP2.animation.curAnim.curFrame = 0;
		}


		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned=true;
				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene) {
				if(!cpuControlled) {
					keyShit();
				} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
					//boyfriend.animation.curAnim.finish();
				}
				if (ClientPrefs.getGameplaySetting('opponentplay', false))
				{
					if(dad.holdTimer > Conductor.stepCrochet * 0.0011 * dad.singDuration && dad.animation.curAnim.name.startsWith('sing') && !dad.animation.curAnim.name.endsWith('miss'))
						dad.dance();
				}
			}

			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if(!daNote.mustPress) strumGroup = opponentStrums;

				var strumX:Float = strumGroup.members[daNote.noteData].x;
				var strumY:Float = strumGroup.members[daNote.noteData].y;
				var strumZ:Float = strumGroup.members[daNote.noteData].z;
				var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
				var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
				var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
				var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

				daNote.z = strumZ;
				strumX += daNote.offsetX / daNote.getScaleRatioX();
				strumY += daNote.offsetY;
				
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				if (strumScroll) //Downscroll
				{
					//daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
				}
				else //Upscroll
				{
					//daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
				}

				var angleDir = strumDirection * Math.PI / 180;
				if (daNote.copyAngle)
					daNote.angle = strumDirection - 90 + strumAngle;

				if(daNote.copyAlpha)
					daNote.alpha = strumAlpha;

				if(daNote.copyX)
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

				if(daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

					//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					if(strumScroll && daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith('end')) {
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
							if(PlayState.isPixelStage) {
								daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
							} else {
								daNote.y -= 19;
							}
						}
						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				if (Note.checkMustPress(!daNote.mustPress) && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					opponentNoteHit(daNote);
				}

				if(Note.checkMustPress(daNote.mustPress) && cpuControlled) {
					if(daNote.isSustainNote) {
						if(daNote.canBeHit) {
							goodNoteHit(daNote);
						}
					} else if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && Note.checkMustPress(daNote.mustPress))) {
						goodNoteHit(daNote);
					}
				}

				var center:Float = strumY + Note.swagWidth / 2;
				if(strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (Note.checkMustPress(daNote.mustPress) || !daNote.ignoreNote) &&
					((daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
				{
					if (Note.checkMustPress(daNote.mustPress) && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}
		checkEventNote();

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		if (vocals != null)
			{
				if (Conductor.songPosition > vocals.length)
					vocals.volume = 0;
			}

		for (v in extraVocals)
		{
			if (v != null)
			{
				if (Conductor.songPosition > v.length)
					v.volume = 0;
			}
		}

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
		spawnedWindowThisFrame = false;
		elapsedtime += elapsed;

		if (shaggyT != null) {
			shaggyT.color = boyfriend.color;
			shaggyT.visible = boyfriend.alpha >= 0.5;
		}
		if (boyfriend.curCharacter == 'godshaggy') {
			legs.color = boyfriend.color;
			legT.color = boyfriend.color;

			var rotRateSh = curStep / 9.5;
			var sh_toy = shy + -Math.sin(rotRateSh * 2) * sh_r * 0.45;
			var sh_tox = shx -Math.cos(rotRateSh) * sh_r;
			boyfriend.x += (sh_tox - boyfriend.x) / 12;
			boyfriend.y += (sh_toy - boyfriend.y) / 12;

			if (boyfriend.animation.name == 'idle')
			{
				var pene = 0.07;
				boyfriend.angle = Math.sin(rotRateSh) * sh_r * pene / 4;

				legs.alpha = boyfriend.alpha;
				legT.visible = boyfriend.alpha >= 0.5;
				legs.angle = Math.sin(rotRateSh) * sh_r * pene;

				legs.x = boyfriend.x + 150 + Math.cos((legs.angle + 90) * (Math.PI/180)) * 150;
				legs.y = boyfriend.y + 300 + Math.sin((legs.angle + 90) * (Math.PI/180)) * 150;
			}
			else
			{
				boyfriend.angle = 0;
				legs.alpha = 0;
				legT.visible = false;
			}
		}

		if (songName != null && barType == 'ShowTime')
		{
			songName.text = FlxStringUtil.formatTime((FlxG.sound.music.length - FlxG.sound.music.time) / 1000);
		}

		if (startingSong && startTimer != null && !startTimer.active)
			startTimer.active = true;

		if (localFunny == CharacterFunnyEffect.Exbungo)
		{
			FlxG.sound.music.volume = 0;
			exbungo_funny.play();
		}
			
		if (paused && FlxG.sound.music != null && vocals != null && vocals.playing)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}
		if (curbg != null)
		{
			if (curbg.active) // only the polygonized background is active
			{
				#if SHADERS_ENABLED
				var shad = cast(curbg.shader, Shaders.GlitchShader);
				shad.uTime.value[0] += elapsed;
				#end
			}
		}
		if (SONG.song.toLowerCase() == 'escape-from-california')
		{
			var scrollSpeed = 100;
			if (desertBG != null)
			{
				desertBG.x -= trainSpeed * scrollSpeed * elapsed;
			
				if (desertBG.x <= -(desertBG.width) + (desertBG.width - 1280))
				{
					desertBG.x = desertBG.width - 1280;
				}
				desertBG2.x = desertBG.x - desertBG.width;
				desertBG2.y = desertBG.y;
			}
			
			if (sign != null)
			{
				sign.x -= trainSpeed * scrollSpeed * elapsed;
			}
			if (georgia != null)
			{
				georgia.x -= trainSpeed * scrollSpeed * elapsed;
			}
		}

		if (SONG.song.toLowerCase() == 'recursed')
		{
			var scrollSpeed = 150;
			charBackdrop.x -= scrollSpeed * elapsed;
			charBackdrop.y += scrollSpeed * elapsed;

			darkSky.x += 40 * scrollSpeed * elapsed;
			if (darkSky.x >= (darkSkyStartPos * 4) - 1280)
			{
				darkSky.x = resetPos;
			}
			darkSky2.x = darkSky.x - darkSky.width;
			
			var lerpVal = 0.97;
			freeplayBG.alpha = FlxMath.lerp(0, freeplayBG.alpha, lerpVal);
			charBackdrop.alpha = FlxMath.lerp(0, charBackdrop.alpha, lerpVal);
			for (char in alphaCharacters)
			{
				for (letter in char.characters)
				{
					letter.alpha = FlxMath.lerp(0, letter.alpha, lerpVal);
				}
			}
			if (isRecursed)
			{
				timeLeft -= elapsed;
				if (timeLeftText != null)
				{
					timeLeftText.text = FlxStringUtil.formatTime(Math.floor(timeLeft));
				}

				camRotateAngle += elapsed * 5 * (rotateCamToRight ? 1 : -1);

				FlxG.camera.angle = camRotateAngle;
				camHUD.angle = camRotateAngle;

				if (camRotateAngle > 8)
				{
					rotateCamToRight = false;
				}
				else if (camRotateAngle < -8)
				{
					rotateCamToRight = true;
				}
				
				health = FlxMath.lerp(0, 2, timeLeft / timeGiven);
			}
			else
			{
				if (FlxG.camera.angle > 0 || camHUD.angle > 0)
				{
					cancelRecursedCamTween();
				}
			}
		}
		if (SONG.song.toLowerCase() == 'five-nights')
		{
			powerLeft = Math.max(powerLeft - (elapsed / 3) * powerDrainer, 0);
			powerLeftText.text = 'Power Left: ${Math.floor(powerLeft)}%';
			if (powerLeft <= 0 && !powerRanOut && curStep < 1088)
			{
				powerRanOut = true;
				
				boyfriend.stunned = true;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;
	
				vocals.volume = 0;
				FlxG.sound.music.volume = 0;

				FlxTween.tween(camHUD, {alpha: 0}, 1);
				
				for (note in unspawnNotes)
				{
					unspawnNotes.remove(note);
				}

				var black = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
				black.scrollFactor.set();
				black.screenCenter();
				add(black);

				powerDown = new FlxSound().loadEmbedded(Paths.sound('fiveNights/powerOut', 'shared'));
				powerDown.play();
			}
			if (powerRanOut)
			{
				curStep < 1088 ? {
					new FlxTimer().start(FlxG.random.int(2, 4), function(timer:FlxTimer)
					{
						if (FlxG.random.int(0, 4) == 0)
						{
							health = 0;
						}
					}, Std.int(Math.POSITIVE_INFINITY));
				} : {
					powerRanOut = false;

					persistentUpdate = true;
					persistentDraw = true;
					
					camHUD.alpha = 1;
					vocals.volume = 1;
					FlxG.sound.music.volume = 0.8;
					sixAM();
				}
			}
			if (time != null)
			{
				var curTime = Std.int(Math.min(Math.floor(FlxG.sound.music.time / 1000 / (((Conductor.stepCrochet / 1000) * 1088) / times.length - 1)), times.length));
				time.text = times[curTime] + ' AM';
			}
			if ((FlxG.mouse.overlaps(doorButton) && (FlxG.mouse.justPressed || controls.KEY5) && !doorChanging) || 
				(botPlay && !doorChanging && dad.curCharacter == 'nofriend' && (doorClosed ? dad.animation.curAnim.name != 'attack' : dad.animation.curAnim.name == 'attack')))
			{
				changeDoorState(!doorClosed);
			}
			if (dad.curCharacter == 'nofriend' && dad.animation.curAnim.name == 'attack' && dad.animation.curAnim.finished)
			{
				doorClosed ? {
					var slam = new FlxSound().loadEmbedded(Paths.sound('fiveNights/slam'));
					slam.play();
					dad.playAnim('fail');
					dad.animation.finishCallback = function(animation:String)
					{
						new FlxTimer().start(1.25, function(timer:FlxTimer)
						{
							dad.canDance = true;
							dad.canSing = true;
							dad.dance();
						});
					};
					powerLeft -= FlxG.random.int(2, 4);
				} : {
					health = 0;
				}
			}
		}
		if (baldi != null)
		{
			if (FlxG.mouse.overlaps(baldi) && FlxG.mouse.justPressed)
			{
				isStoryMode = false;
				storyPlaylist = [];
				FlxG.switchState(new MathGameState());
			}
		}
		
		var toy = -100 + -Math.sin((curStep / 9.5) * 2) * 30 * 5;
		var tox = -330 -Math.cos((curStep / 9.5)) * 100;

		//welcome to 3d sinning avenue
      if (stageCheck == 'exbungo-land') {
			place.y -= (Math.sin(elapsedtime) * 0.4);
		}
		if (dad.curCharacter == 'recurser')
		{
			toy = 100 + -Math.sin((elapsedtime) * 2) * 300;
			tox = -400 - Math.cos((elapsedtime)) * 200;

			dad.x += (tox - dad.x);
			dad.y += (toy - dad.y);
		}

		if(funnyFloatyBoys.contains(dad.curCharacter.toLowerCase()) && canFloat)
		{
			if (dad.curCharacter.toLowerCase() == "expunged")
			{
				// mentally insane movement
				dad.x += (tox - dad.x) / 12;
				dad.y += (toy - dad.y) / 12;
			}
			else
			{
				dad.y += (Math.sin(elapsedtime) * 0.2);
			}
		}
		if(funnyFloatyBoys.contains(boyfriend.curCharacter.toLowerCase()) && canFloat)
		{
			boyfriend.y += (Math.sin(elapsedtime) * 0.2);
		}
		/*if(funnyFloatyBoys.contains(dadmirror.curCharacter.toLowerCase()))
		{
			dadmirror.y += (Math.sin(elapsedtime) * 0.6);
		}*/

		if(funnyFloatyBoys.contains(gf.curCharacter.toLowerCase()) && canFloat)
		{
			gf.y += (Math.sin(elapsedtime) * 0.2);
		}

		noteWidth = 156 * Note.scales[mania];

		if (modchartoption) {
			if ((SONG.song.toLowerCase() == 'cheating' || localFunny == CharacterFunnyEffect.Dave) && !inCutscene) // fuck you
			{
				var num:Float = 1.5;
				if (mania == 2) num = 1.4;
				if (mania == 3) num = 1.35;
				if (mania == 4) num = 1.3;
				playerStrums.forEach(function(spr:StrumNote)                                               
				{
					spr.x += Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1);
					spr.x -= Math.sin(elapsedtime) * num;
				});
				dadStrums.forEach(function(spr:StrumNote)
				{
					spr.x -= Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1);
					spr.x += Math.sin(elapsedtime) * num;
				});
			}
			if (SONG.song.toLowerCase() == 'unfairness' && !inCutscene) // fuck you x2
			{
				var num:Float = 1;
				if (mania == 2) num = 1.5;
				if (mania == 3) num = 1.75;
				if (mania == 4) num = 2.25;
				playerStrums.forEach(function(spr:StrumNote)
				{
					spr.x = ((FlxG.width / 2) - (noteWidth / 2)) + (Math.sin((elapsedtime + (spr.ID / num))) * 300);
					spr.y = ((FlxG.height / 2) - (noteWidth / 2)) + (Math.cos((elapsedtime + (spr.ID / num))) * 300);
				});
				dadStrums.forEach(function(spr:StrumNote)
				{
					spr.x = ((FlxG.width / 2) - (noteWidth / 2)) + (Math.sin((elapsedtime + (spr.ID)) * 2) * 300);
					spr.y = ((FlxG.height / 2) - (noteWidth / 2)) + (Math.cos((elapsedtime + (spr.ID)) * 2) * 300);
				});
			}
			if (!inCutscene)
			{
				if (localFunny == CharacterFunnyEffect.Recurser)
				{
					playerStrums.forEach(function(spr:StrumNote)
					{
						spr.y = spr.baseY + ((Math.sin(elapsedtime + spr.ID)) * (noteWidth * 0.75));
					});
					dadStrums.forEach(function(spr:StrumNote)
					{
						spr.y = spr.baseY + ((Math.sin(elapsedtime + (spr.ID + 4))) * (noteWidth * 0.75));
					});
				}
			}
	
			if (SONG.song.toLowerCase() == 'exploitation' && !inCutscene && mcStarted) // fuck you
			{
				switch (modchart)
				{
					case ExploitationModchartType.None:
	
					case ExploitationModchartType.Jitterwave:
						playerStrums.forEach(function(spr:StrumNote)
						{
							if (mania == 5) {
								if (spr.ID == 1 || spr.ID == 5 || spr.ID == 9)
								{
									spr.x = playerStrums.members[spr.ID + 1].baseX;
								}
								else if (spr.ID == 2 || spr.ID == 6 || spr.ID == 10)
								{
									spr.x = playerStrums.members[spr.ID - 1].baseX;
								}
								else
								{
									spr.x = spr.baseX;
								}
							} else {
								if (spr.ID == 1)
								{
									spr.x = playerStrums.members[2].baseX;
								}
								else if (spr.ID == 2)
								{
									spr.x = playerStrums.members[1].baseX;
								}
								else
								{
									spr.x = spr.baseX;
								}
							}
							spr.y = ((FlxG.height / 2) - (noteWidth / 2)) + ((Math.sin((elapsedtime + spr.ID) * (((curBeat % 6) + 1) * 0.6))) * 140);
						});
						dadStrums.forEach(function(spr:StrumNote)
						{
							if (mania == 5) {
								if (spr.ID == 1 || spr.ID == 5 || spr.ID == 9)
								{
									spr.x = dadStrums.members[spr.ID + 1].baseX;
								}
								else if (spr.ID == 2 || spr.ID == 6 || spr.ID == 10)
								{
									spr.x = dadStrums.members[spr.ID - 1].baseX;
								}
								else
								{
									spr.x = spr.baseX;
								}
							} else {
								if (spr.ID == 1)
								{
									spr.x = dadStrums.members[2].baseX;
								}
								else if (spr.ID == 2)
								{
									spr.x = dadStrums.members[1].baseX;
								}
								else
								{
									spr.x = spr.baseX;
								}
							}
							spr.y = ((FlxG.height / 2) - (noteWidth / 2)) + ((Math.sin((elapsedtime + spr.ID) * (((curBeat % 6) + 1) * 0.6))) * 140);
						});
						
					case ExploitationModchartType.Cheating:
						playerStrums.forEach(function(spr:StrumNote)
						{
							spr.x += (spr.ID == 1 ? 0.5 : 1) * Math.sin(elapsedtime) * ((spr.ID % 3) == 0 ? 1 : -1);
							spr.x -= (spr.ID == 1 ? 0.5 : 1) * Math.sin(elapsedtime) * (((spr.ID / 3) + 1.2) * (mania == 5 ? 0.1 : 1));
						});
						dadStrums.forEach(function(spr:StrumNote)
						{
							spr.x -= (spr.ID == 1 ? 0.5 : 1) * Math.sin(elapsedtime) * ((spr.ID % 3) == 0 ? 1 : -1);
							spr.x += (spr.ID == 1 ? 0.5 : 1) * Math.sin(elapsedtime) * (((spr.ID / 3) + 1.2) * (mania == 5 ? 0.1 : 1));
						});
	
					case ExploitationModchartType.Sex: 
						playerStrums.forEach(function(spr:StrumNote)
						{
							spr.x = ((FlxG.width / 2) - (noteWidth / 2));
							spr.y = ((FlxG.height / 2) - (noteWidth / 2));
							if (mania == 5) {
								if (spr.ID == 0)
								{
									spr.x -= noteWidth * 6.5;
								}
								if (spr.ID == 2)
								{
									spr.x -= noteWidth * 5.3;
									spr.y += noteWidth * 0.6;
								}
								if (spr.ID == 1)
								{
									spr.x -= noteWidth * 4.1;
									spr.y += noteWidth * 1.2;
								}
								if (spr.ID == 3)
								{
									spr.x -= noteWidth * 2.9;
									spr.y += noteWidth * 1.7;
								}
								if (spr.ID == 4)
								{
									spr.x -= noteWidth * 1.7;
									spr.y += noteWidth * 1.9;
								}
								if (spr.ID == 6)
								{
									spr.x -= noteWidth * 0.5;
									spr.y += noteWidth * 2;
								}
								if (spr.ID == 5)
								{
									spr.x += noteWidth * 0.5;
									spr.y += noteWidth * 2;
								}
								if (spr.ID == 7)
								{
									spr.x += noteWidth * 1.7;
									spr.y += noteWidth * 1.9;
								}
								if (spr.ID == 8)
								{
									spr.x += noteWidth * 2.9;
									spr.y += noteWidth * 1.7;
								}
								if (spr.ID == 10)
								{
									spr.x += noteWidth * 4.1;
									spr.y += noteWidth * 1.2;
								}
								if (spr.ID == 9)
								{
									spr.x += noteWidth * 5.3;
									spr.y += noteWidth * 0.6;
								}
								if (spr.ID == 11)
								{
									spr.x += noteWidth * 6.5;
								}
							} else {
								if (spr.ID == 0)
								{
									spr.x -= noteWidth * 2.5;
								}
								if (spr.ID == 1)
								{
									spr.x += noteWidth * 0.5;
									spr.y += noteWidth;
								}
								if (spr.ID == 2)
								{
									spr.x -= noteWidth * 0.5;
									spr.y += noteWidth;
								}
								if (spr.ID == 3)
								{
									spr.x += noteWidth * 2.5;
								}
							}
							spr.x += Math.sin(elapsedtime * (spr.ID + 1)) * (30 * (mania == 5 ? 0.5 : 1));
							spr.y += Math.cos(elapsedtime * (spr.ID + 1)) * (30 * (mania == 5 ? 0.5 : 1));
						});
						dadStrums.forEach(function(spr:StrumNote)
						{
							spr.x = ((FlxG.width / 2) - (noteWidth / 2));
							spr.y = ((FlxG.height / 2) - (noteWidth / 2));
							spr.x += (noteWidth * (Main.keyAmmo[mania] - 1 - spr.ID)) - ((Main.keyAmmo[mania] / 2) * noteWidth) + (noteWidth * 0.5);
							spr.x += Math.sin(elapsedtime * (spr.ID + 1)) * (-30 * (mania == 5 ? 0.5 : 1));
							spr.y += Math.cos(elapsedtime * (spr.ID + 1)) * (-30 * (mania == 5 ? 0.5 : 1));
						});
					case ExploitationModchartType.Unfairness: //unfairnesses mod chart with a few changes to keep it interesting
						playerStrums.forEach(function(spr:StrumNote)
						{
							//0.62 is a speed modifier. its there simply because i thought the og modchart was a bit too hard.
							spr.x = ((FlxG.width / 2) - (noteWidth / 2)) + (Math.sin(((elapsedtime + (spr.ID * 2 / (mania == 5 ? 3 : 1)))) * 0.62) * 250);
							spr.y = ((FlxG.height / 2) - (noteWidth / 2)) + (Math.cos(((elapsedtime + (spr.ID * 0.5 / (mania == 5 ? 3 : 1)))) * 0.62) * 250);
						});
						dadStrums.forEach(function(spr:StrumNote)
						{
							spr.x = ((FlxG.width / 2) - (noteWidth / 2)) + (Math.sin(((elapsedtime + (spr.ID * 0.5)) * 2) * 0.62) * 250);
							spr.y = ((FlxG.height / 2) - (noteWidth / 2)) + (Math.cos(((elapsedtime + (spr.ID * 2)) * 2) * 0.62) * 250);
						});
	
					case ExploitationModchartType.PingPong:
						var xx = (FlxG.width / 2.4) + (Math.sin(elapsedtime * 1.2) * 400);
						var yy = (FlxG.height / 2) + (Math.sin(elapsedtime * 1.5) * 200) - 50;
						var xx2 = (FlxG.width / 2.4) + (Math.cos(elapsedtime) * 400);
						var yy2 = (FlxG.height / 2) + (Math.cos(elapsedtime * 1.4) * 200) - 50;
						playerStrums.forEach(function(spr:StrumNote)
						{
							var bol = spr.ID == 0 || spr.ID == 2;
							var bol2 = spr.ID == 1 || spr.ID == 3;
							if (mania == 5) bol = spr.ID == 0 || spr.ID == 2 || spr.ID == 4 || spr.ID == 6 || spr.ID == 8 || spr.ID == 10;
							if (mania == 5) bol2 = spr.ID == 1 || spr.ID == 3 || spr.ID == 5 || spr.ID == 7 || spr.ID == 9 || spr.ID == 11;
							spr.x = (xx + (noteWidth / 2)) - (bol ? noteWidth : bol2 ? -noteWidth : 0);
							spr.y = (yy + (noteWidth / 2)) - (spr.ID <= (Main.keyAmmo[mania] / 2 - 1) ? 0 : noteWidth);
							spr.x += Math.sin((elapsedtime + (spr.ID * 3)) / 3) * noteWidth;
						});
						dadStrums.forEach(function(spr:StrumNote)
						{
							var bol = spr.ID == 0 || spr.ID == 2;
							var bol2 = spr.ID == 1 || spr.ID == 3;
							if (mania == 5) bol = spr.ID == 0 || spr.ID == 2 || spr.ID == 4 || spr.ID == 6 || spr.ID == 8 || spr.ID == 10;
							if (mania == 5) bol2 = spr.ID == 1 || spr.ID == 3 || spr.ID == 5 || spr.ID == 7 || spr.ID == 9 || spr.ID == 11;
							spr.x = (xx2 + (noteWidth / 2)) - (bol ? noteWidth : bol2 ? -noteWidth : 0);
							spr.y = (yy2 + (noteWidth / 2)) - (spr.ID <= (Main.keyAmmo[mania] / 2 - 1) ? 0 : noteWidth);
							spr.x += Math.sin((elapsedtime + (spr.ID * (mania == 5 ? 1 : 3))) / 3) * noteWidth;
	
						});
	
					case ExploitationModchartType.Figure8:
						playerStrums.forEach(function(spr:FlxSprite)
						{
							spr.x = ((FlxG.width / 2) - (noteWidth / 2)) + (Math.sin((elapsedtime * 0.3) + spr.ID + 1) * (FlxG.width * 0.4));
							spr.y = ((FlxG.height / 2) - (noteWidth / 2)) + (Math.sin(((elapsedtime * 0.3) + spr.ID) * 3) * (FlxG.height * 0.2));
						});
						dadStrums.forEach(function(spr:FlxSprite)
						{
							spr.x = ((FlxG.width / 2) - (noteWidth / 2)) + (Math.sin((elapsedtime * 0.3) + spr.ID + 1.5) * (FlxG.width * 0.4));
							spr.y = ((FlxG.height / 2) - (noteWidth / 2)) + (Math.sin((((elapsedtime * 0.3) + spr.ID) * -3) + 0.5) * (FlxG.height * 0.2));
						});
					case ExploitationModchartType.ScrambledNotes:
						playerStrums.forEach(function(spr:StrumNote)
						{
							spr.x = (FlxG.width / 2) + (Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1)) * ((mania == 5 ? 20 : 60) * (spr.ID + 1));
							spr.x += Math.sin(elapsedtime - 1) * 40;
							spr.y = (FlxG.height / 2) + (Math.sin(elapsedtime - 69.2) * ((spr.ID % 3) == 0 ? 1 : -1)) * ((mania == 5 ? 25 : 67) * (spr.ID + 1)) - 15;
							spr.y += Math.cos(elapsedtime - 1) * 40;
							spr.x -= 80;
						});
						dadStrums.forEach(function(spr:StrumNote)
						{
							spr.x = (FlxG.width / 2) + (Math.cos(elapsedtime - 1) * ((spr.ID % 2) == 0 ? -1 : 1)) * ((mania == 5 ? 20 : 60) * (spr.ID + 1));
							spr.x += Math.sin(elapsedtime - 1) * 40;
							spr.y = (FlxG.height / 2) + (Math.sin(elapsedtime - 63.4) * ((spr.ID % 3) == 0 ? -1 : 1)) * ((mania == 5 ? 25 : 67) * (spr.ID + 1)) - 15;
							spr.y += Math.cos(elapsedtime - 1) * 40;
							spr.x -= 80;
						});
	
					case ExploitationModchartType.Cyclone:
						playerStrums.forEach(function(spr:StrumNote)
						{
							spr.x = ((FlxG.width / 2) - (noteWidth / 2)) + (Math.sin((spr.ID + 1) * (elapsedtime * 0.15)) * ((mania == 5 ? 25 : 65) * (spr.ID + 1)));
							spr.y = ((FlxG.height / 2) - (noteWidth / 2)) + (Math.cos((spr.ID + 1) * (elapsedtime * 0.15)) * ((mania == 5 ? 25 : 65) * (spr.ID + 1)));
						});
						dadStrums.forEach(function(spr:StrumNote)
						{
							spr.x = ((FlxG.width / 2) - (noteWidth / 2)) + (Math.cos((spr.ID + 1) * (elapsedtime * 0.15)) * ((mania == 5 ? 25 : 65) * (spr.ID + 1)));
							spr.y = ((FlxG.height / 2) - (noteWidth / 2)) + (Math.sin((spr.ID + 1) * (elapsedtime * 0.15)) * ((mania == 5 ? 25 : 65) * (spr.ID + 1)));
						});
				}
			}
		}
		// no more 3d sinning avenue
		if (daveFlying)
		{
			dad.y -= elapsed * 50;
			dad.angle -= elapsed * 6;
		}
		if (tweenList != null && tweenList.length != 0)
		{
			for (tween in tweenList)
			{
				if (tween.active && !tween.finished && !activateSunTweens)
					tween.percent = FlxG.sound.music.time / tweenTime;
			}
		}
        
		#if SHADERS_ENABLED
		FlxG.camera.setFilters([new ShaderFilter(screenshader.shader)]); // this is very stupid but doesn't effect memory all that much so
		#end
		if (shakeCam && eyesoreson)
		{
			// var shad = cast(FlxG.camera.screen.shader,Shaders.PulseShader);
			FlxG.camera.shake(0.010, 0.010);
		}

		#if SHADERS_ENABLED
		screenshader.shader.uTime.value[0] += elapsed;
		lazychartshader.shader.uTime.value[0] += elapsed;
		if (blockedShader != null)
		{
			blockedShader.update(elapsed);
		}
		if (shakeCam && eyesoreson)
		{
			screenshader.shader.uampmul.value[0] = 1;
		}
		else
		{
			screenshader.shader.uampmul.value[0] -= (elapsed / 2);
		}
		screenshader.Enabled = shakeCam && eyesoreson;
		#end

		super.update(elapsed);

		switch (SONG.song.toLowerCase())
		{
			case 'overdrive':
				scoreTxt.text = "score: " + Std.string(songScore);
			case 'exploitation':
				scoreTxt.text = 
				"Scor3: " + (songScore * (modchartoption ? FlxG.random.int(1,9) : 1)) + 
				" | M1ss3s: " + (misses * (modchartoption ? FlxG.random.int(1,9) : 1)) + 
				" | Accuracy: " + (truncateFloat(accuracy, 2) * (modchartoption ? FlxG.random.int(1,9) : 1)) + "% ";
			default:
				scoreTxt.text = 
				LanguageManager.getTextString('play_score') + Std.string(songScore) + " | " + 
				LanguageManager.getTextString('play_miss') + misses +  " | " + 
				LanguageManager.getTextString('play_accuracy') + truncateFloat(accuracy, 2) + "%";
		}
		if (noMiss)
		{
			scoreTxt.text += " | NO MISS!!";
		}
		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			// 1 / 1000 chance for Gitaroo Man easter egg
			if (FlxG.random.bool(0.1))
			{
				// gitaroo man easter egg
				FlxG.switchState(new GitarooPause());
			}
			else
			{
				if (SONG.song.toLowerCase() == 'exploitation' && modchartoption) //damn it
				{
					playerStrums.forEach(function(note:StrumNote)
					{
						FlxTween.completeTweensOf(note);
					});
					dadStrums.forEach(function(note:StrumNote)
					{
						FlxTween.completeTweensOf(note);
					});
				}
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			}
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			if(FlxTransitionableState.skipNextTransIn)
			{
				Transition.nextCamera = null;
			}
			
			switch (curSong.toLowerCase())
			{
				case 'supernovae':
					FlxG.switchState(new TerminalCheatingState([
						new TerminalText(0, [['Warning: ', 1], ['Chart Editor access detected', 1],]),
						new TerminalText(200, [['run AntiCheat.dll', 0.5]]),
						new TerminalText(0, [['ERROR: File currently being used by another process. Retrying in 3...', 3]]),
						new TerminalText(200, [['File no longer in use, running AntiCheat.dll..', 2]]),
					], function()
					{
						shakeCam = false;
						#if SHADERS_ENABLED
						screenshader.Enabled = false;
						#end

						isStoryMode = false;
						PlayState.SONG = Song.loadFromJson("cheating"); // you dun fucked up
						isStoryMode = false;
						PlayState.storyWeek = 14;
						FlxG.save.data.cheatingFound = true;
						FlxG.switchState(new PlayState());
					}));
					return;
				case 'cheating':
					FlxG.switchState(new TerminalCheatingState([
						new TerminalText(0, [['Warning: ', 1], ['Chart Editor access detected', 1],]),
						new TerminalText(200, [['run AntiCheat.dll', 3]]),
					], function()
					{
						isStoryMode = false;
						storyPlaylist = [];
						
						shakeCam = false;
						#if SHADERS_ENABLED
						screenshader.Enabled = false;
						#end

						PlayState.SONG = Song.loadFromJson("unfairness"); // you dun fucked up again
						PlayState.storyWeek = 15;
						FlxG.save.data.unfairnessFound = true;
						FlxG.switchState(new PlayState());
					}));
					return;
				case 'unfairness':
					FlxG.switchState(new TerminalCheatingState([
						new TerminalText(0, [
							['bin/plugins/AntiCheat.dll: ', 1],
							['No argument for function "AntiCheatThree"', 1],
						]),
						new TerminalText(100, [['Redirecting to terminal...', 1]])
					], function()
					{
						isStoryMode = false;
						storyPlaylist = [];
						
						shakeCam = false;
						#if SHADERS_ENABLED
						screenshader.Enabled = false;
						#end

						FlxG.switchState(new TerminalState());
					}));
					#if desktop
					DiscordClient.changePresence("I have your IP address", null, null, true);
					#end
					return;
				case 'exploitation' | 'master':
					health = 0;
				case 'recursed':
					ChartingState.hahaFunnyRecursed();
				case 'glitch':
					isStoryMode = false;
					storyPlaylist = [];
					
					PlayState.SONG = Song.loadFromJson("kabunga"); // lol you loser
					isStoryMode = false;
					FlxG.save.data.exbungoFound = true;
					shakeCam = false;
					#if SHADERS_ENABLED
					screenshader.Enabled = false;
					#end
					FlxG.switchState(new PlayState());
					return;
				case 'kabunga':
					fancyOpenURL("https://benjaminpants.github.io/muko_firefox/index.html"); //banger game
					System.exit(0);
				case 'vs-dave-rap':
					PlayState.SONG = Song.loadFromJson("vs-dave-rap-two");
					FlxG.save.data.vsDaveRapTwoFound = true;
					shakeCam = false;
					#if SHADERS_ENABLED
					screenshader.Enabled = false;
					#end
					FlxG.switchState(new PlayState());
					return;
				default:
					#if SHADERS_ENABLED
					resetShader();
					#end
					FlxG.switchState(new ChartingState());
					#if desktop
					DiscordClient.changePresence("Chart Editor", null, null, true);
					#end
			}
		}

		#if debug
		if (FlxG.keys.justPressed.THREE)
		{
			if(FlxTransitionableState.skipNextTransIn)
			{
				Transition.nextCamera = null;
			}
			
			#if SHADERS_ENABLED
			resetShader();
			#end
			FlxG.switchState(new ChartingState());
			#if desktop
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}
		#end

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		var thingy = 0.88; //(144 / Main.fps.currentFPS) * 0.88;
		//still gotta make this fps consistent crap

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, thingy)),Std.int(FlxMath.lerp(150, iconP1.height, thingy)));
		iconP1.updateHitbox();

		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, thingy)),Std.int(FlxMath.lerp(150, iconP2.height, thingy)));
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		if (inFiveNights)
		{
			iconP1.x = (healthBar.x + healthBar.width) - (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) + iconOffset);
			iconP2.x = (healthBar.x + healthBar.width) - (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);
		}
		else
		{
			iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
			iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);
		}

		if (health > 2)
			health = 2;

		if (SONG.song.toLowerCase() != "five-nights")
		{
			if (healthBar.percent < 20)
				iconP1.changeState('losing');
			else
				iconP1.changeState('normal');

			if (healthBar.percent > 80)
				iconP2.changeState('losing');
			else
				iconP2.changeState('normal');
		}
		else
		{
			if (healthBar.percent < 20)
				iconP2.changeState('losing');
			else
				iconP2.changeState('normal');

			if (healthBar.percent > 80)
				iconP1.changeState('losing');
			else
				iconP1.changeState('normal');
		}

		#if debug
		if (FlxG.keys.justPressed.FOUR)
		{
			trace('DUMP LOL:\nDAD POSITION: ${dad.getPosition()}\nBOYFRIEND POSITION: ${boyfriend.getPosition()}\nGF POSITION: ${gf.getPosition()}\nCAMERA POSITION: ${camFollow.getPosition()}');
		}
		/*if (FlxG.keys.justPressed.FIVE)
		{
			FlxG.switchState(new CharacterDebug(dad.curCharacter));
		}
		if (FlxG.keys.justPressed.SEMICOLON)
		{
			FlxG.switchState(new CharacterDebug(boyfriend.curCharacter));
		}
		if (FlxG.keys.justPressed.COMMA)
		{
			FlxG.switchState(new CharacterDebug(gf.curCharacter));
		}
		if (FlxG.keys.justPressed.EIGHT)
			FlxG.switchState(new AnimationDebug(dad.curCharacter));
		if (FlxG.keys.justPressed.SIX)
			FlxG.switchState(new AnimationDebug(boyfriend.curCharacter));*/
		if (FlxG.keys.justPressed.TWO) //Go 10 seconds into the future :O
		{
			FlxG.sound.music.pause();
			vocals.pause();
			boyfriend.stunned = true;
			Conductor.songPosition += 10000;
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.strumTime + 800 < Conductor.songPosition) {
					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
			for (i in 0...unspawnNotes.length)
			{
				var daNote:Note = unspawnNotes[0];
				if (daNote.strumTime + 800 >= Conductor.songPosition)
				{
					break;
				}

				daNote.active = false;
				daNote.visible = false;

				daNote.kill();
				unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
				daNote.destroy();
			}

			FlxG.sound.music.time = Conductor.songPosition;
			FlxG.sound.music.play();

			vocals.time = Conductor.songPosition;
			vocals.play();
			boyfriend.stunned = false;
		}
		/*if (FlxG.keys.justPressed.THREE)
			FlxG.switchState(new AnimationDebug(gf.curCharacter));*/
		#end
	
		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
				{
					startSong();
				}
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}
		if (crazyZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (health <= 0 && !botPlay)
		{
			if(!perfectMode)
			{
				boyfriend.stunned = true;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;
	
				vocals.stop();
				FlxG.sound.music.stop();
				
				#if SHADERS_ENABLED
				screenshader.shader.uampmul.value[0] = 0;
				screenshader.Enabled = false;
				#end
			}

			if (!shakeCam)
			{
				if(!perfectMode)
				{
					gameOver();
				}
			}
			else
			{
				CharacterSelectState.unlockCharacter('bambi-3d');
				if (isStoryMode)
				{
					switch (SONG.song.toLowerCase())
					{
						case 'blocked' | 'corn-theft' | 'maze':
							FlxG.openURL("https://www.youtube.com/watch?v=eTJOdgDzD64");
							System.exit(0);
						default:
							if (shakeCam)
							{
								CharacterSelectState.unlockCharacter('bambi-3d');
							}
							FlxG.switchState(new EndingState('rtxx_ending', 'badEnding'));
					}
				}
				else
				{
					if (!perfectMode)
					{
						if(shakeCam)
						{
							CharacterSelectState.unlockCharacter('bambi-3d');
						}
						gameOver();
					}
				}
			}

			// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (unspawnNotes[0] != null)
		{
			var thing:Int = ((SONG.song.toLowerCase() == 'unfairness' || PlayState.SONG.song.toLowerCase() == 'exploitation') && modchartoption ? 20000 : 1500);

			if (unspawnNotes[0].strumTime - Conductor.songPosition < thing)
			{
				var dunceNote:Note = unspawnNotes[0];
				dunceNote.finishedGenerating = true;

				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);

				if (!dunceNote.isSustainNote && dunceNote.noteStyle != 'guitarHero') {
					dunceNote.updateHitbox();
					dunceNote.offset.x = dunceNote.frameWidth / 2;
					dunceNote.offset.y = dunceNote.frameHeight / 2;
			
					dunceNote.offset.x -= noteWidth / 2;
					dunceNote.offset.y -= noteWidth / 2;
				}
			}
		}
		var currentSection = SONG.notes[Math.floor(curStep / 16)];

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}
				if (daNote.noteStyle == 'recursed' && daNote.isSustainNote) // kinda weird bug...
				{
					daNote.x -= daNote.width / 2;
					daNote.x += noteWidth / 2;
				}
				if (daNote.mustPress && (Conductor.songPosition >= daNote.strumTime) && daNote.health != 2 && daNote.noteStyle == 'phone')
				{
					daNote.health = 2;
					dad.playAnim(dad.animation.getByName("singThrow") == null ? 'singSmash' : 'singThrow', true);
				}
				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent)
				{
					if (SONG.song != 'Warmup')
						camZooming = true; 

					var altAnim:String = "";
					var healthtolower:Float = 0.02;

					if (currentSection != null)
					{
						if (daNote.noteStyle == 'phone-alt')
						{
							altAnim = '-alt';
						}
						if (currentSection.altAnim)
							if (SONG.song.toLowerCase() != "cheating")
							{
								altAnim = '-alt';
							}
							else
							{
								healthtolower = 0.005;
							}
					}
					if (inFiveNights && !daNote.isSustainNote)
					{
						dadCombo++;
						createScorePopUp(0, 0, true, FlxG.random.int(0,10) == 0 ? "good" : "sick", dadCombo, "3D");
					}

					cameraMoveOnNote(noteToPlay, 'dad');
					
					dadStrums.forEach(function(sprite:StrumNote)
					{
						if (Math.abs(Math.round(Math.abs(daNote.noteData)) % dadStrumAmount) == sprite.ID)
						{
							if (daNote.noteStyle != 'guitarHero') {
								sprite.playAnim('confirm', true);
								sprite.animation.finishCallback = function(name:String)
								{
									sprite.playAnim('static', true);
								}
							} else {
								sprite.animation.play('confirm', true);
								if (sprite.animation.curAnim.name == 'confirm')
								{
									sprite.centerOffsets();
									sprite.offset.x -= 13;
									sprite.offset.y -= 13;
								}
								else
								{
									sprite.centerOffsets();
								}
								sprite.animation.finishCallback = function(name:String)
								{
									sprite.animation.play('static', true);
									sprite.centerOffsets();
								}
							}
						}
						sprite.pressingKey5 = daNote.noteStyle == 'shape';
					});

					daNote.hitByOpponent = true;

					if (UsingNewCam)
					{
						focusOnDadGlobal = true;
						ZoomCam(true);
					}

					switch (SONG.song.toLowerCase())
					{
						case 'cheating':
							health -= healthtolower;
						case 'unfairness':
							var healthadj = 3;
							switch (storyDifficulty) {
								case 0: healthadj = 4;
							}
							health -= (healthtolower / healthadj);
						case 'exploitation':
							if (((health + (FlxEase.backInOut(health / 16.5)) - 0.002) >= 0) && !(curBeat >= 320 && curBeat <= 330))
							{
								health += ((FlxEase.backInOut(health / 16.5)) * (curBeat <= 160 ? 0.25 : 1)) - 0.002; //some training wheels cuz rapparep say mod too hard
							}
						case 'mealie':
							if (curBeat >= 464 && curBeat <= 592) {
								health -= (healthtolower / 1.5);
							}
						case 'five-nights':
							if ((health - 0.023) > 0)
							{
								health -= 0.023;
							}
							else
							{
								health = 0.001;
							}
					}
					// boyfriend.playAnim('hit',true);
					dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					if (!daNote.isSustainNote) {
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}
				if(daNote.mustPress && botPlay) {
					if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.prevNote.wasGoodHit)) {
						goodNoteHit(daNote);
						boyfriend.holdTimer = 0;
					}
				}

				var strumY:Float = 0;
				if (!guitarSection) strumY = playerStrums.members[daNote.noteData].y;
				if(!daNote.mustPress) strumY = dadStrums.members[daNote.noteData].y;
				var swagWidth = 160 * Note.scales[mania];
				var center:Float = strumY + swagWidth / 2;
				if(daNote.isSustainNote && (daNote.mustPress || (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))))
				{
					if (scrollType == 'downscroll')
					{
						if(daNote.y - daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
						else
							daNote.clipRect = null;
					}
					else if (scrollType == 'upscroll')
					{
						if (daNote.y + daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
						else
							daNote.clipRect = null;
					}
				}

				if (daNote.MyStrum != null)
				{
					daNote.y = yFromNoteStrumTime(daNote, daNote.MyStrum, scrollType == 'downscroll');
				}
				else
				{
					daNote.y = yFromNoteStrumTime(daNote, strumLine, scrollType == 'downscroll');
				}
				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));
				var noteSpeed = (daNote.LocalScrollSpeed == 0 ? 1 : daNote.LocalScrollSpeed);
				
				if (daNote.wasGoodHit && daNote.isSustainNote && Conductor.songPosition >= (daNote.strumTime + daNote.height + 10))
				{
					destroyNote(daNote);
				}
				if (!daNote.wasGoodHit && daNote.mustPress && daNote.finishedGenerating && Conductor.songPosition >= daNote.strumTime + (350 / (0.45 * FlxMath.roundDecimal(SONG.speed * noteSpeed, 2))))
				{
					if (!botPlay) {
						if (!noMiss)
							noteMiss(daNote.originalType, daNote);
	
						vocals.volume = 0;
					}

					destroyNote(daNote);
				}
			});
		}

		ZoomCam(focusOnDadGlobal);

		if (!inCutscene && !botPlay)
			keyShit();

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end

		if (updatevels)
		{
			stupidx *= 0.98;
			stupidy += elapsed * 6;
			if (BAMBICUTSCENEICONHURHURHUR != null)
			{
				BAMBICUTSCENEICONHURHURHUR.x += stupidx;
				BAMBICUTSCENEICONHURHURHUR.y += stupidy;
			}
		}
                }
	function THROWPHONEMARCELLO(e:FlxTimer = null):Void
	{
		STUPDVARIABLETHATSHOULDNTBENEEDED.animation.play("throw_phone");
		new FlxTimer().start(5.5, function(timer:FlxTimer)
		{ 
			if(isStoryMode) {
				FlxG.sound.music.stop();
				nextSong();
			}
			else {
				FlxG.switchState(new FreeplayState());
			}
		});
	}

	function ZoomCam(focusondad:Bool):Void
	{
		var bfplaying:Bool = false;
		if (focusondad)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (!bfplaying)
				{
					if (daNote.mustPress)
					{
						bfplaying = true;
					}
				}
			});
			if (UsingNewCam && bfplaying)
			{
				return;
			}
		}
		if (!lockCam)
		{
			if (focusondad)
			{
				camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);

				switch (dad.curCharacter)
				{
					case 'playrobot':
						camFollow.x = dad.getMidpoint().x + 50;
					case 'playrobot-shadow':
						camFollow.x = dad.getMidpoint().x + 50;
						camFollow.y -= 100;
					case 'dave-angey' | 'dave-festival-3d' | 'dave-3d-recursed':
						camFollow.y = dad.getMidpoint().y;
					case 'nofriend':
						camFollow.x = dad.getMidpoint().x + 50;
						camFollow.y = dad.getMidpoint().y - 50;
					case 'bambi-3d':
						camFollow.x = dad.getMidpoint().x;
						camFollow.y -= 50;
				}

				if (SONG.song.toLowerCase() == 'warmup')
				{
					tweenCamIn();
				}

				bfNoteCamOffset[0] = 0;
				bfNoteCamOffset[1] = 0;

				camFollow.x += dadNoteCamOffset[0];
				camFollow.y += dadNoteCamOffset[1];
			}
			else
			{
				camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
	
				switch (boyfriend.curCharacter)
				{
					case 'bf-pixel':
						camFollow.x = boyfriend.getMidpoint().x - 200;
						camFollow.y = boyfriend.getMidpoint().y - 250;
					case 'bf-3d':
						camFollow.y += 100;
					case 'dave-angey':
						camFollow.y = boyfriend.getMidpoint().y;
					case 'bambi-3d':
						camFollow.x = boyfriend.getMidpoint().x - 375;
						camFollow.y = boyfriend.getMidpoint().y - 200;
					case 'dave-fnaf':
						camFollow.x += 100;
					case 'shaggy' | 'supershaggy' | 'redshaggy' | 'godshaggy':
						camFollow.x -= 100;
						camFollow.y += 30;
						if (SONG.song.toLowerCase() == 'rano') camFollow.y += 100;
				}
				dadNoteCamOffset[0] = 0;
				dadNoteCamOffset[1] = 0;

				camFollow.x += bfNoteCamOffset[0];
				camFollow.y += bfNoteCamOffset[1];

				if (SONG.song.toLowerCase() == 'warmup')
				{
					FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.sineInOut});
				}
			}
			switch (SONG.song.toLowerCase())
			{
				case 'escape-from-california':
					camFollow.y += 150;
			}
		}
	}

	
	function yFromNoteStrumTime(note:Note, strumLine:FlxSprite, downScroll:Bool):Float
	{
		var change = downScroll ? -1 : 1;
		var speed:Float = SONG.speed;
		if (localFunny == CharacterFunnyEffect.Tristan)
		{
			speed += (Math.sin(elapsedtime / 5)) * 1;
		}
		var val:Float = strumLine.y - (Conductor.songPosition - note.strumTime) * (change * 0.45 * FlxMath.roundDecimal(speed * note.LocalScrollSpeed, 2));
		if (note.isSustainNote && downScroll && note.animation != null)
		{
			if (note.animation.curAnim.name.endsWith('end'))
			{
				val += (note.height * 1.55 * (0.7 / Note.scales[mania]));
			}
			val -= (note.height * 0.2);
		}
		return val;
	}

	function FlingCharacterIconToOblivionAndBeyond(e:FlxTimer = null):Void
	{
		iconP2.changeIcon(AUGHHHH);
		
		BAMBICUTSCENEICONHURHURHUR.changeIcon(AHHHHH);
		BAMBICUTSCENEICONHURHURHUR.changeState(iconP2.getState());
		stupidx = -5;
		stupidy = -5;
		updatevels = true;
	}
	function destroyNote(note:Note)
	{
		note.active = false;
		note.visible = false;
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	function openPauseMenu()
	{
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		// 1 / 1000 chance for Gitaroo Man easter egg
		/*if (FlxG.random.bool(0.1))
		{
			// gitaroo man easter egg
			cancelMusicFadeTween();
			MusicBeatState.switchState(new GitarooPause());
		}
		else {*/
		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
			for (v in extraVocals)
				v.pause();
		}
		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		//}

		#if desktop
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', [], false);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				for (v in extraVocals)
					v.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Dadbattle Spotlight':
				var val:Null<Int> = Std.parseInt(value1);
				if(val == null) val = 0;

				switch(Std.parseInt(value1))
				{
					case 1, 2, 3: //enable and target dad
						if(val == 1) //enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleSmokes.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if(val > 2) who = boyfriend;
						//2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer) {
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleSmokes, {alpha: 0}, 1, {onComplete: function(twn:FlxTween)
						{
							dadbattleSmokes.visible = false;
						}});
				}

			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if(curStage == 'mall') {
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;

			case 'Philly Glow':
				var lightId:Int = Std.parseInt(value1);
				if(Math.isNaN(lightId)) lightId = 0;

				var doFlash:Void->Void = function() {
					var color:FlxColor = FlxColor.WHITE;
					if(!ClientPrefs.flashing) color.alphaFloat = 0.5;

					FlxG.camera.flash(color, 0.15, null, true);
				};

				var chars:Array<Character> = [boyfriend, gf, dad];
				switch(lightId)
				{
					case 0:
						if(phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;
							phillyWindowEvent.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
							curLightEvent = -1;

							for (who in chars)
							{
								who.color = FlxColor.WHITE;
							}
							phillyStreet.color = FlxColor.WHITE;
						}

					case 1: //turn on
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length-1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if(!phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
						}
						else if(ClientPrefs.flashing)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;
						if(!ClientPrefs.flashing) charColor.saturation *= 0.5;
						else charColor.saturation *= 0.75;

						for (who in chars)
						{
							who.color = charColor;
						}
						phillyGlowParticles.forEachAlive(function(particle:PhillyGlow.PhillyGlowParticle)
						{
							particle.color = color;
						});
						phillyGlowGradient.color = color;
						phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						phillyStreet.color = color;

					case 2: // spawn particles
						if(!ClientPrefs.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];
							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlow.PhillyGlowParticle = new PhillyGlow.PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
									phillyGlowParticles.add(particle);
								}
							}
						}
						phillyGlowGradient.bop();
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if(curStage == 'schoolEvil' && !ClientPrefs.lowQuality) {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}

						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnLuas('gfName', gf.curCharacter);
						}
				}
				if (ClientPrefs.getGameplaySetting('opponentplay', false))
				{
					player = dad;
					opponent = boyfriend;
				}
				else 
				{
					player = boyfriend;
					opponent = dad;
				}
				reloadHealthBarColors();

			case 'BG Freaks Expression':
				if(bgGirls != null) bgGirls.swapDanceType();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if(killMe.length > 1) {
					FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], value2);
				} else {
					FunkinLua.setVarInArray(this, value1, value2);
				}
			case 'CreateWindowPopup': 
				var val1:Int = Std.parseInt(value1);
				Main.createFunnyPopup(val1);
			case 'ClearWindows':
				Main.clearExtraWindows(); 

		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection():Void {
		if(SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	//Any way to do this without using a different function? kinda dumb
	private function onSongComplete()
	{
		finishSong(false);
	}
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		for (v in extraVocals)
		{
			v.volume = 0;
			v.pause();
		}
		if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['beat_godspeed', 'fc_godspeed', 'beat_god_godspeed', 'opponent_mode', 'beat_uc', 'beat_mar', 'beat_funny']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		var ret:Dynamic = callOnLuas('onEndSong', [], false);
		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				var songThing = SONG.song;
				if (god || trueDiff)
					songThing = '???';
				Highscore.saveScore(songThing, songScore, storyDifficulty, percent);
				#end
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					WeekData.loadTheFirstEnabledMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				WeekData.loadTheFirstEnabledMod();
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;
		if (vocals != null)
		{
			if (Conductor.songPosition > vocals.length)
				vocals.volume = 0;
		}

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.increase();
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = FlxG.random.int(200, 300);
		comboSpr.velocity.y -= FlxG.random.int(140, 160);
		comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10);

		insert(members.indexOf(renderedStrumLineNotes), rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
		{
			insert(members.indexOf(renderedStrumLineNotes), comboSpr);
		}
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				insert(members.indexOf(renderedStrumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		/*
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002
		});
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey)%keyAmmount;
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			controlHoldArray[key] = true;
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && Note.checkMustPress(daNote.mustPress) && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if(daNote.noteData%keyAmmount == key)
						{
							sortedNotesList.push(daNote);
							//trace('found note '+key);
							//notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else{
					callOnLuas('onGhostTap', [key]);
					if (canMiss) {
						noteMissPress(key);
					}
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = currentPlayerStrums.members[key];
			if(spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if (spawnedWindowThisFrame)
			return;
		if(!cpuControlled && startedCountdown && !paused && key > -1)
		{
			var spr:StrumNote = currentPlayerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			controlHoldArray[key] = false;
			callOnLuas('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	var controlHoldArray:Array<Bool> = [false, false, false, false];

	public function NearlyEquals(value1:Float, value2:Float, unimportantDifference:Float = 10):Bool
	{
		return Math.abs(FlxMath.roundDecimal(value1, 1) - FlxMath.roundDecimal(value2, 1)) < unimportantDifference;
	}

	var upHold:Bool = false;
	var downHold:Bool = false;
	var rightHold:Bool = false;
	var leftHold:Bool = false;
	var centerHold:Bool = false;

	var l1Hold:Bool = false;
	var uHold:Bool = false;
	var r1Hold:Bool = false;
	var l2Hold:Bool = false;
	var dHold:Bool = false;
	var r2Hold:Bool = false;

	var a0Hold:Bool = false;
	var a1Hold:Bool = false;
	var a2Hold:Bool = false;
	var a3Hold:Bool = false;
	var a4Hold:Bool = false;
	var a5Hold:Bool = false;
	var a6Hold:Bool = false;

	var n0Hold:Bool = false;
	var n1Hold:Bool = false;
	var n2Hold:Bool = false;
	var n3Hold:Bool = false;
	var n4Hold:Bool = false;
	var n5Hold:Bool = false;
	var n6Hold:Bool = false;
	var n7Hold:Bool = false;
	var n8Hold:Bool = false;

	var t0Hold:Bool = false;
	var t1Hold:Bool = false;
	var t2Hold:Bool = false;
	var t3Hold:Bool = false;
	var t4Hold:Bool = false;
	var t5Hold:Bool = false;
	var t6Hold:Bool = false;
	var t7Hold:Bool = false;
	var t8Hold:Bool = false;
	var t9Hold:Bool = false;
	var t10Hold:Bool = false;
	var t11Hold:Bool = false;

	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData%keyAmmount] && daNote.canBeHit
				&& Note.checkMustPress(daNote.mustPress) && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote);
				}
			});

			if (controlHoldArray.contains(true) && !endingSong && !ClientPrefs.getGameplaySetting('opponentplay', false)) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				//boyfriend.animation.curAnim.finish();
			}
			
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && Note.checkMustPress(daNote.mustPress) && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;
		health -= daNote.missHealth * healthLoss;
		
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		//For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		if (ClientPrefs.getGameplaySetting('opponentplay', false) && vocalsToAdd.contains('-opponent'))
		{
			if (extraVocals[0] != null)
				extraVocals[0].volume = 0;
		}
		else 
		{
			vocals.volume = 0;
		}
		if(!practiceMode) songScore -= 10;

		totalPlayed++;
		RecalculateRating(true);

		var char:Character = player;
		if(daNote.gfNote) {
			char = gf;
		}

		if(char != null && !daNote.noMissAnimation && char.hasMissAnimations)
		{
			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daNote.animSuffix;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function switchNoteSide()
	{
		for (i in 0...Main.keyAmmo[mania])
		{
			var curOpponentNote = dadStrums.members[i];
			var curPlayerNote = playerStrums.members[i];

			FlxTween.tween(curOpponentNote, {x: curPlayerNote.x}, 0.6, {ease: FlxEase.expoOut, startDelay: 0.01 * i});
			FlxTween.tween(curPlayerNote, {x: curOpponentNote.x}, 0.6, {ease: FlxEase.expoOut, startDelay: 0.01 * i});
		}
		switchSide = !switchSide;
	}

	function switchNotePositions(order:Array<Int>)
	{
		var positions:Array<Float> = [];
		for (i in 0...Main.keyAmmo[mania])
		{
			var curNote = playerStrums.members[i];
			positions.push(curNote.baseX);
		}
		for (i in 0...Main.keyAmmo[mania])
		{
			var curNote = dadStrums.members[i];
			positions.push(curNote.baseX);
		}
		for (i in 0...Main.keyAmmo[mania])
		{
			var curOpponentNote = dadStrums.members[i];
			var curPlayerNote = playerStrums.members[i];

			FlxTween.tween(curOpponentNote, {x: positions[order[i + playerStrumAmount]]}, 0.6, {ease: FlxEase.expoOut, startDelay: 0.01 * i});
			FlxTween.tween(curPlayerNote, {x: positions[order[i]]}, 0.6, {ease: FlxEase.expoOut, startDelay: 0.01 * i});
		}
		switchSide = !switchSide;
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.ghostTapping) return; //fuck it

		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating(true);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(player.hasMissAnimations) {
				player.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
				
			if (ClientPrefs.getGameplaySetting('opponentplay', false) && vocalsToAdd.contains('-opponent'))
			{
				if (extraVocals[0] != null)
					extraVocals[0].volume = 0;
			}
			else 
			{
				vocals.volume = 0;
			}
				
		}
		callOnLuas('noteMissPress', [direction]);
	}

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
					altAnim = '-alt';
				}
			}

			var char:Character = opponent;
			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if(note.gfNote) {
				char = gf;
			}

			if(char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}



		if (SONG.needsVoices)
			vocals.volume = 1;
		

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		StrumPlayAnim(!ClientPrefs.getGameplaySetting('opponentplay', false), Std.int(Math.abs(note.noteData)) % keyAmmount, time);
		note.hitByOpponent = true;

		if (!ClientPrefs.getGameplaySetting('opponentplay', false))
			callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		else 
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				if(!note.noMissAnimation)
				{
					switch(note.noteType) {
						case 'Hurt Note': //Hurt note
							if(boyfriend.animation.getByName('hurt') != null) {
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
					}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				if(combo > 9999) combo = 9999;
				popUpScore(note);
			}
			health += note.hitHealth * healthGain;

			if(!note.noAnimation) {
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if(note.gfNote)
				{
					if(gf != null)
					{
						gf.playAnim(animToPlay + note.animSuffix, true);
						gf.holdTimer = 0;
					}
				}
				else
				{
					player.playAnim(animToPlay + note.animSuffix, true);
					player.holdTimer = 0;
				}

				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(ClientPrefs.getGameplaySetting('opponentplay', false), Std.int(Math.abs(note.noteData)) % keyAmmount, time);
			} else {
				currentPlayerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			


			if (vocalsToAdd.contains('-opponent') && ClientPrefs.getGameplaySetting('opponentplay', false))
			{
				if (extraVocals[0] != null)
					extraVocals[0].volume = 1;
			}
			else 
			{
				vocals.volume = 1;
			}

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;

			if (!ClientPrefs.getGameplaySetting('opponentplay', false))
				callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
			else 
				callOnLuas('opponentNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = currentPlayerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);

	}
	function gameOver()
	{
		#if windows
		if (window != null)
		{
			expungedWindowMode = false;
			window.close();
			//x,y, width, height
			FlxTween.tween(Application.current.window, {x: windowProperties[0], y: windowProperties[1], width: windowProperties[2], height: windowProperties[3]}, 1, {ease: FlxEase.circInOut});

		}
		#end
		var deathSkinCheck = formoverride == "bf" || formoverride == "none" ? SONG.player1 : isRecursed ? boyfriend.curCharacter : formoverride;
		var chance = FlxG.random.int(0, 99);
		if (chance <= 2 && eyesoreson)
		{
			openSubState(new TheFunnySubState(deathSkinCheck));
			#if desktop
				DiscordClient.changePresence("GAME OVER -- "
				+ SONG.song
				+ " ("
				+ storyDifficultyText
				+ ") ",
				"\n what", iconRPC);
			#end
		}
		else
		{
			#if desktop
			if (SONG.song.toLowerCase() == 'exploitation')
			{
				var expungedLines:Array<String> = 
				[
					'i found you.', 
					"i can see you.", 
					'HAHAHHAHAHA', 
					"punishment day is here, this one is removing you.",
					"got you.",
					"try again, if you dare.",
					"nice try.",
					"i could do this all day.",
					"do that again. i like watching you fail."
				];

				var path = CoolSystemStuff.getTempPath() + "/HELLO.txt";

				var randomLine = new FlxRandom().int(0, expungedLines.length);
				File.saveContent(path, expungedLines[randomLine]);
				#if windows
				Sys.command("start " + path);
				#elseif linux
				Sys.command("xdg-open " + path);
				#else
				Sys.command("open " + path);
				#end
			}
			#end

			if (SONG.song.toLowerCase() == 'recursed')
			{
				cancelRecursedCamTween();
			}
			
			if (!inFiveNights)
			{
				if (funnyFloatyBoys.contains(boyfriend.curCharacter))
				{
					openSubState(new GameOverPolygonizedSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, deathSkinCheck));
				}
				else
				{
					openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, deathSkinCheck));
				}
			}
			else
			{
				if (powerDown != null)
				{
					powerDown.stop();
				}
				openSubState(new GameOverFNAF());
			}
			#if desktop
				DiscordClient.changePresence("GAME OVER -- "
				+ SONG.song
				+ " ("
				+ storyDifficultyText
				+ ") ",
				"\nAcc: "
				+ truncateFloat(accuracy, 2)
				+ "% | Score: "
				+ songScore
				+ " | Misses: "
				+ misses, iconRPC);
			#end
		}
		
	}


	function eatShit(ass:String):Void
	{
		if (dialogue[0] == null)
		{
			trace(ass);
		}
		else
		{
			trace(dialogue[0]);
		}
	}

	public function addSplitathonChar(char:String):Void
	{
		boyfriend.stunned = true; //hopefully this stun stuff should prevent BF from randomly missing a note
		
		switchDad(char, new FlxPoint(300, 450), false);
		repositionChar(dad);

		boyfriend.stunned = false;
	}

	public function splitathonExpression(character:String, expression:String):Void
	{
		boyfriend.stunned = true;
		if(splitathonCharacterExpression != null)
		{
			dadGroup.remove(splitathonCharacterExpression);
		}
		switch (character)
		{
			case 'dave':
				splitathonCharacterExpression = new Character(0, 225, 'dave-splitathon');
			case 'bambi':
				splitathonCharacterExpression = new Character(0, 580, 'bambi-splitathon');
		}
		dadGroup.insert(dadGroup.members.indexOf(dad), splitathonCharacterExpression);

		splitathonCharacterExpression.color = getBackgroundColor(curStage);
		splitathonCharacterExpression.canDance = false;
		splitathonCharacterExpression.playAnim(expression, true);
		boyfriend.stunned = false;
	}

	public function preload(graphic:String) //preload assets
	{
		if (boyfriend != null)
		{
			boyfriend.stunned = true;
		}
		var newthing:FlxSprite = new FlxSprite(9000,-9000).loadGraphic(Paths.image(graphic));
		add(newthing);
		remove(newthing);
		if (boyfriend != null)
		{
			boyfriend.stunned = false;
		}
	}
	public function preload2(graphic:String) //preload assets
	{
		if (boyfriend != null)
		{
			boyfriend.stunned = true;
		}
		var newthing:FlxSprite = new FlxSprite(9000,-9000).loadGraphic(graphic);
		add(newthing);
		remove(newthing);
		if (boyfriend != null)
		{
			boyfriend.stunned = false;
		}
	}
	public function repositionChar(char:Character)
	{
		char.x += char.globalOffset[0];
		char.y += char.globalOffset[1];
	}
	function updateSpotlight(bfSinging:Bool)
	{
		var curSinger = bfSinging ? boyfriend : dad;

		if (lastSinger != curSinger)
		{
			gf.canDance = false;
			bfSinging ? gf.playAnim("singRIGHT", true) : gf.playAnim("singLEFT", true);
			gf.animation.finishCallback = function(anim:String)
			{
				gf.canDance = true;
			}

			var positionOffset:FlxPoint = new FlxPoint(0,-150);

			switch (curSinger.curCharacter)
			{
				case 'bambi-new':
					positionOffset.x = -25;
					positionOffset.y += -70;
				case 'bf-pixel':
					positionOffset.y += -225;
			}
			var targetPosition = new FlxPoint(curSinger.getGraphicMidpoint().x - spotLight.width / 2 + positionOffset.x, curSinger.getGraphicMidpoint().y + curSinger.frameHeight / 2 - (spotLight.height) - positionOffset.y);
			
			if (SONG.song.toLowerCase() == 'indignancy')
			{
				targetPosition.y += 80;
			}

			FlxTween.tween(spotLight, {x: targetPosition.x, y: targetPosition.y}, 0.66, {ease: FlxEase.circOut});
			lastSinger = curSinger;
		}
	}

	function switchToNight()
	{
		var bedroomSpr = BGSprite.getBGSprite(backgroundSprites, 'bg');
		var baldiSpr = BGSprite.getBGSprite(backgroundSprites, 'baldi');
		var rubySpr = BGSprite.getBGSprite(backgroundSprites, 'ruby');

		bedroomSpr.loadGraphic(Paths.image('backgrounds/bedroom/night/bg'));
		baldiSpr.loadGraphic(Paths.image('backgrounds/bedroom/night/bed'));
		if (rubySpr != null)
		{
			rubySpr.loadGraphic(Paths.image('backgrounds/bedroom/night/ruby'));
		}
		curStage = 'bedroomNight';

		switchDad('playrobot-shadow', dad.getPosition(), true, false);
		tristanInBotTrot.animation.play('idleNight');
		
		if (formoverride != 'tristan-golden') {
		    boyfriend.color = getBackgroundColor(curStage);
		}

		if (formoverride == 'tristan-golden' || formoverride == 'tristan-golden-glowing') {
			boyfriend.color = FlxColor.WHITE;
            switchBF('tristan-golden-glowing', boyfriend.getPosition(), true, true);
		}
	}
	function nofriendAttack()
	{
		dad.canDance = false;
		dad.canSing = false;
		dad.playAnim('attack', true);
		var runSfx = new FlxSound().loadEmbedded(Paths.soundRandom('fiveNights/run', 1, 2, 'shared'));
		runSfx.play();
	}
	function sixAM()
	{
		FlxG.sound.music.volume = 1;
		vocals.volume = 1;
		camHUD.alpha = 1;

		FlxG.camera.flash(FlxColor.WHITE, 0.5);
		black = new FlxSprite(0, 0).makeGraphic(2560, 1440, FlxColor.BLACK);
		black.screenCenter();
		black.scrollFactor.set();
		black.cameras = [camHUD];
		add(black);

		var sixAM:FlxText = new FlxText(0, 0, 0, "6 AM", 90);
		sixAM.setFormat(Paths.font('fnaf.ttf'), 90, FlxColor.WHITE, CENTER);
		sixAM.antialiasing = false;
		sixAM.scrollFactor.set();
		sixAM.screenCenter();
		sixAM.cameras = [camHUD];
		sixAM.alpha = 0;
		add(sixAM);

		FlxTween.tween(sixAM, {alpha: 1}, 1);

		var crowdSmall = new FlxSound().loadEmbedded(Paths.sound('fiveNights/CROWD_SMALL_CHIL_EC049202', 'shared'));
		crowdSmall.play();
	}
	public function getCamZoom():Float
	{
		return defaultCamZoom;
	}
	public static function resetShader()
	{
		PlayState.instance.shakeCam = false;
		PlayState.instance.camZooming = false;
		#if SHADERS_ENABLED
		screenshader.shader.uampmul.value[0] = 0;
		screenshader.Enabled = false;
		#end
	}

	function sectionStartTime(section:Int):Float
	{
		var daBPM:Float = SONG.bpm;
		var daPos:Float = 0;
		for (i in 0...section)
		{
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	function switchDad(newChar:String, position:FlxPoint, reposition:Bool = true, updateColor:Bool = true)
	{
		if (reposition)
		{
			position.x -= dad.globalOffset[0];
			position.y -= dad.globalOffset[1];
		}
		dadGroup.remove(dad);
		dad = new Character(position.x, position.y, newChar, false);
		dadGroup.add(dad);
		if (FileSystem.exists(Paths.image('ui/iconGrid/${dad.curCharacter}', 'preload')))
		{
			iconP2.changeIcon(dad.curCharacter);
		}
		healthBar.createFilledBar(dad.barColor, boyfriend.barColor);
		
		if (updateColor)
		{
			dad.color = getBackgroundColor(curStage);
		}
		if (reposition)
		{
			repositionChar(dad);
		}
	}
	function switchBF(newChar:String, position:FlxPoint, reposition:Bool = true, updateColor:Bool = true)
	{
		if (reposition)
		{
			position.x -= boyfriend.globalOffset[0];
			position.y -= boyfriend.globalOffset[1];
		}
		bfGroup.remove(boyfriend);
		boyfriend = new Boyfriend(position.x, position.y, newChar);
		bfGroup.add(boyfriend);
		if (FileSystem.exists(Paths.image('ui/iconGrid/${boyfriend.curCharacter}', 'preload')))
		{
			iconP1.changeIcon(boyfriend.curCharacter);
		}
		healthBar.createFilledBar(dad.barColor, boyfriend.barColor);
		
		if (updateColor)
		{
			boyfriend.color = getBackgroundColor(curStage);
		}
		if (reposition)
		{
			repositionChar(boyfriend);
		}
	}
	function switchGF(newChar:String, position:FlxPoint, reposition:Bool = true, updateColor:Bool = true)
	{
		if (reposition)
		{
			position.x -= gf.globalOffset[0];
			position.y -= gf.globalOffset[1];
		}
		gfGroup.remove(gf);
		gf = new Character(position.x, position.y, newChar);
		gfGroup.add(gf);
		
		if (updateColor)
		{
			gf.color = getBackgroundColor(curStage);
		}
		if (reposition)
		{
			repositionChar(gf);
		}
	}

	function makeInvisibleNotes(invisible:Bool)
	{
		if (invisible)
		{
			for (strumNote in strumLineNotes)
			{
				FlxTween.cancelTweensOf(strumNote);
				FlxTween.tween(strumNote, {alpha: 0}, 1);
			}
		}
		else
		{
			for (strumNote in strumLineNotes)
			{
				FlxTween.cancelTweensOf(strumNote);
				FlxTween.tween(strumNote, {alpha: 1}, 1);
			}
		}
	}
	function changeDoorState(closed:Bool)
	{
		doorClosed = closed;
		doorChanging = true;
		FlxG.sound.play(Paths.sound('fiveNights/doorInteract', 'shared'), 1);
		if (doorClosed)
		{
			doorButton.loadGraphic(Paths.image('fiveNights/btn_doorClosed'));
			powerMeter.loadGraphic(Paths.image('fiveNights/powerMeter_2'));
			door.animation.play('doorShut');
			
			powerDrainer = 3;
		}
		else
		{
			doorButton.loadGraphic(Paths.image('fiveNights/btn_doorOpen'));
			powerMeter.loadGraphic(Paths.image('fiveNights/powerMeter'));
			door.animation.play('doorOpen');

			powerDrainer = 1;
		}
		door.animation.finishCallback = function(animation:String)
		{
			doorChanging = false;
		}
	}
	function changeSign(asset:String, ?position:FlxPoint)
	{
		sign.loadGraphic(Paths.image('california/$asset', 'shared'));
		if (position != null)
		{
			sign.setPosition(position.x, position.y);
		}
		else
		{
			sign.setPosition(FlxG.width + sign.width, 450);
		}
	}

	function popupWindow()
	{
		var screenwidth = Application.current.window.display.bounds.width;
		var screenheight = Application.current.window.display.bounds.height;

		// center
		Application.current.window.x = Std.int((screenwidth / 2) - (1280 / 2));
		Application.current.window.y = Std.int((screenheight / 2) - (720 / 2));
		Application.current.window.width = 1280;
		Application.current.window.height = 720;

		window = Application.current.createWindow({
			title: "expunged.dat",
			width: 800,
			height: 800,
			borderless: true,
			alwaysOnTop: true
		});
		#if linux
		//testing stuff
		window.stage.color = 0x00010101;
		#end
		PlatformUtil.getWindowsTransparent();

		preDadPos = dad.getPosition();
		dad.x = 0;
		dad.y = 0;

		FlxG.mouse.useSystemCursor = true;

		generateWindowSprite();

		expungedScroll.scrollRect = new Rectangle();
		expungedScroll.addChild(expungedSpr);
		expungedScroll.scaleX = 0.5;
		expungedScroll.scaleY = 0.5;

		expungedOffset.x = Application.current.window.x;
		expungedOffset.y = Application.current.window.y;

		dad.visible = false;

		var windowX = Application.current.window.x + ((Application.current.window.display.bounds.width) * 0.140625);

		windowSteadyX = windowX;

		FlxTween.tween(expungedOffset, {x: -20}, 2, {ease: FlxEase.elasticOut});

		FlxTween.tween(Application.current.window, {x: windowX}, 2.2, {
			ease: FlxEase.elasticOut,
			onComplete: function(tween:FlxTween)
			{
				ExpungedWindowCenterPos.x = expungedOffset.x;
				ExpungedWindowCenterPos.y = expungedOffset.y;
				expungedMoving = false;
			}
		});

		Application.current.window.onClose.add(function()
		{
			if (window != null)
			{
				window.close();
			}
		}, false, 100);

		Application.current.window.focus();
		expungedWindowMode = true;

		@:privateAccess
		lastFrame = dad._frame;
	}

	function generateWindowSprite()
	{
		var m = new Matrix();
		m.translate(0, 0);
		expungedSpr.graphics.beginBitmapFill(dad.pixels, m);
		expungedSpr.graphics.drawRect(0, 0, dad.pixels.width, dad.pixels.height);
		expungedSpr.graphics.endFill();
	}
	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive()
	{
		//trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			if (gf != null)
			{
				gf.playAnim('hairBlow');
				gf.specialAnim = true;
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		if(gf != null)
		{
			gf.danced = false; //Sets head to the correct position once the animation ends
			gf.playAnim('hairFall');
			gf.specialAnim = true;
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if(gf != null && gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function killHenchmen():Void
	{
		if(!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo') {
			if(limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
				var achieve:String = checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null) {
					startAchievement(achieve);
				} else {
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if(curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	function moveTank(?elapsed:Float = 0):Void
	{
		if(!inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}

	override function destroy() {
		for (lua in luaArray) {
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		#if hscript
		FunkinLua.haxeInterp = null;
		#end
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
			resyncVocals();

		switch (SONG.song.toLowerCase())
		{
			case 'blocked':
				switch (curStep)
				{
					case 128:
						defaultCamZoom += 0.1;
						FlxG.camera.flash(FlxColor.WHITE, 0.5);
						black = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
						black.screenCenter();
						black.alpha = 0;
						add(black);
						FlxTween.tween(black, {alpha: 0.6}, 1);
						makeInvisibleNotes(true);
						subtitleManager.addSubtitle(LanguageManager.getTextString('blocked_sub1'), 0.02, 1);
					case 165:
						subtitleManager.addSubtitle(LanguageManager.getTextString('blocked_sub2'), 0.02, 1);
					case 188:
						subtitleManager.addSubtitle(LanguageManager.getTextString('blocked_sub3'), 0.02, 1);
					case 224:
						subtitleManager.addSubtitle(LanguageManager.getTextString('blocked_sub4'), 0.02, 1);
					case 248:
						subtitleManager.addSubtitle(LanguageManager.getTextString('blocked_sub5'), 0.02, 0.5, {subtitleSize: 60});
					case 256:
						defaultCamZoom -= 0.1;
						FlxG.camera.flash();
						FlxTween.tween(black, {alpha: 0}, 1);
						makeInvisibleNotes(false);
					case 640:
						FlxG.camera.flash();
						black.alpha = 0.6;
						defaultCamZoom += 0.1;
					case 768:
						FlxG.camera.flash();
						defaultCamZoom -= 0.1;
						black.alpha = 0;
					case 1028:
						makeInvisibleNotes(true);
						subtitleManager.addSubtitle(LanguageManager.getTextString('blocked_sub6'), 0.02, 1.5);
					case 1056:
						subtitleManager.addSubtitle(LanguageManager.getTextString('blocked_sub7'), 0.02, 1);
					case 1084:
						subtitleManager.addSubtitle(LanguageManager.getTextString('blocked_sub8'), 0.02, 1);
					case 1104:
						subtitleManager.addSubtitle(LanguageManager.getTextString('blocked_sub9'), 0.02, 1);
					case 1118:
						subtitleManager.addSubtitle(LanguageManager.getTextString('blocked_sub10'), 0.02, 1);
					case 1143:
						subtitleManager.addSubtitle(LanguageManager.getTextString('blocked_sub11'), 0.02, 1, {subtitleSize: 45});
						makeInvisibleNotes(false);
					case 1152:
						FlxTween.tween(black, {alpha: 0.4}, 1);
						defaultCamZoom += 0.3;
					case 1200:
						#if SHADERS_ENABLED
						if(CompatTool.save.data.compatMode != null && CompatTool.save.data.compatMode == false)
							{
								camHUD.setFilters([new ShaderFilter(blockedShader.shader)]);
							}
						#end
						FlxTween.tween(black, {alpha: 0.7}, (Conductor.stepCrochet / 1000) * 8);
					case 1216:
						FlxG.camera.flash(FlxColor.WHITE, 0.5);
						camHUD.setFilters([]);
						remove(black);
						defaultCamZoom -= 0.3;
				}
			case 'corn-theft':
				switch (curStep)
				{
					case 668:
						defaultCamZoom += 0.1;
					case 784:
						defaultCamZoom += 0.1;
					case 848:
						defaultCamZoom -= 0.2;
					case 916:
						FlxG.camera.flash();
					case 935:
						defaultCamZoom += 0.2;
						black = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
						black.screenCenter();
						black.alpha = 0;
						add(black);
						FlxTween.tween(black, {alpha: 0.6}, 1);
						makeInvisibleNotes(true);
						subtitleManager.addSubtitle(LanguageManager.getTextString('ctheft_sub1'), 0.02, 1);
					case 945:
						subtitleManager.addSubtitle(LanguageManager.getTextString('ctheft_sub2'), 0.02, 1);
					case 976:
						subtitleManager.addSubtitle(LanguageManager.getTextString('ctheft_sub3'), 0.02, 0.5);
					case 982:
						subtitleManager.addSubtitle(LanguageManager.getTextString('ctheft_sub4'), 0.02, 1);
					case 992:
						subtitleManager.addSubtitle(LanguageManager.getTextString('ctheft_sub5'), 0.02, 1);
					case 1002:
						subtitleManager.addSubtitle(LanguageManager.getTextString('ctheft_sub6'), 0.02, 0.3);
					case 1007:
						subtitleManager.addSubtitle(LanguageManager.getTextString('ctheft_sub7'), 0.02, 0.3);
					case 1033:
						subtitleManager.addSubtitle("Bye Baa!", 0.02, 0.3, {subtitleSize: 45});
						FlxTween.tween(dad, {alpha: 0}, (Conductor.stepCrochet / 1000) * 6);
						FlxTween.tween(black, {alpha: 0}, (Conductor.stepCrochet / 1000) * 6);
						FlxTween.num(defaultCamZoom, defaultCamZoom + 0.2, (Conductor.stepCrochet / 1000) * 6, {}, function(newValue:Float)
						{
							defaultCamZoom = newValue;
						});
						makeInvisibleNotes(false);
					case 1040:
						defaultCamZoom = 0.8; 
						dad.alpha = 1;
						remove(black);
						FlxG.camera.flash();
				}
			case 'maze':
				switch (curStep)
				{
					case 466:
						defaultCamZoom += 0.2;
						FlxG.camera.flash(FlxColor.WHITE, 0.5);
						black = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
						black.screenCenter();
						black.alpha = 0;
						add(black);
						FlxTween.tween(black, {alpha: 0.6}, 1);
						makeInvisibleNotes(true);
						subtitleManager.addSubtitle(LanguageManager.getTextString('maze_sub1'), 0.02, 1);
					case 476:
						subtitleManager.addSubtitle(LanguageManager.getTextString('maze_sub2'), 0.02, 0.7);
					case 484:
						subtitleManager.addSubtitle(LanguageManager.getTextString('maze_sub3'), 0.02, 1);
					case 498:
						subtitleManager.addSubtitle(LanguageManager.getTextString('maze_sub4'), 0.02, 1);
					case 510:
						subtitleManager.addSubtitle(LanguageManager.getTextString('maze_sub5'), 0.02, 1, {subtitleSize: 60});
						makeInvisibleNotes(false);
					case 528:
						 defaultCamZoom = 0.8;
						black.alpha = 0;
						FlxG.camera.flash();
					case 832:
						defaultCamZoom += 0.2;
						FlxTween.tween(black, {alpha: 0.4}, 1);
					case 838:
						makeInvisibleNotes(true);
						subtitleManager.addSubtitle(LanguageManager.getTextString('maze_sub6'), 0.02, 1);
					case 847:
						subtitleManager.addSubtitle(LanguageManager.getTextString('maze_sub7'), 0.02, 0.5);
					case 856:
						subtitleManager.addSubtitle(LanguageManager.getTextString('maze_sub8'), 0.02, 1);
					case 867:
						subtitleManager.addSubtitle(LanguageManager.getTextString('maze_sub9'), 0.02, 1, {subtitleSize: 40});
					case 879:
						subtitleManager.addSubtitle(LanguageManager.getTextString('maze_sub10'), 0.02, 1);
					case 890:
						subtitleManager.addSubtitle(LanguageManager.getTextString('maze_sub11'), 0.02, 1);
					case 902:
						subtitleManager.addSubtitle(LanguageManager.getTextString('maze_sub12'), 0.02, 1, {subtitleSize: 60});
						makeInvisibleNotes(false);
					case 908:
						FlxTween.tween(black, {alpha: 1}, (Conductor.stepCrochet / 1000) * 4);
					case 912:
						if (!spotLightPart)
						{
							spotLightPart = true;
							defaultCamZoom -= 0.1;
							FlxG.camera.flash(FlxColor.WHITE, 0.5);
	
							spotLight = new FlxSprite().loadGraphic(Paths.image('spotLight'));
							spotLight.blend = BlendMode.ADD;
							spotLight.setGraphicSize(Std.int(spotLight.width * (dad.frameWidth / spotLight.width) * spotLightScaler));
							spotLight.updateHitbox();
							spotLight.alpha = 0;
							spotLight.origin.set(spotLight.origin.x,spotLight.origin.y - (spotLight.frameHeight / 2));
							add(spotLight);
	
							spotLight.setPosition(dad.getGraphicMidpoint().x - spotLight.width / 2, dad.getGraphicMidpoint().y + dad.frameHeight / 2 - (spotLight.height));	
							updateSpotlight(false);
							
							FlxTween.tween(black, {alpha: 0.6}, 1);
							FlxTween.tween(spotLight, {alpha: 0.7}, 1);
						}
					case 1168:
						spotLightPart = false;
						FlxTween.tween(spotLight, {alpha: 0}, 1, {onComplete: function(tween:FlxTween)
						{
							remove(spotLight);
						}});
						FlxTween.tween(black, {alpha: 0}, 1);
					case 1232:
						FlxG.camera.flash();
				}
			case 'greetings':
				switch (curStep)
				{
					case 492:
						var curZoom = defaultCamZoom;
						var time = (Conductor.stepCrochet / 1000) * 20;
						FlxG.camera.fade(FlxColor.WHITE, time, false, function()
						{
							FlxG.camera.fade(FlxColor.WHITE, 0, true, function()
							{
								FlxG.camera.flash(FlxColor.WHITE, 0.5);
							});
						});
						FlxTween.num(curZoom, curZoom + 0.4, time, {onComplete: function(tween:FlxTween)
						{
							defaultCamZoom = 0.7;
						}}, function(newValue:Float)
						{
							defaultCamZoom = newValue;
						});
				}
			case 'recursed':
				switch (curStep)
				{
					case 320:
						defaultCamZoom = 0.6;
						cinematicBars(((Conductor.stepCrochet * 30) / 1000), 400);
					case 352:
						defaultCamZoom = 0.4;
						FlxG.camera.flash();
					case 864:
						FlxG.camera.flash();
						charBackdrop.loadGraphic(Paths.image('recursed/bambiScroll'));
						freeplayBG.loadGraphic(bambiBG);
						freeplayBG.color = FlxColor.multiply(0xFF00B515, FlxColor.fromRGB(44, 44, 44));
						initAlphabet(bambiSongs);
					case 1248:
						defaultCamZoom = 0.6;
						FlxG.camera.flash();
						charBackdrop.loadGraphic(Paths.image('recursed/tristanScroll'));
						freeplayBG.loadGraphic(tristanBG);
						freeplayBG.color = FlxColor.multiply(0xFFFF0000, FlxColor.fromRGB(44, 44, 44));
						initAlphabet(tristanSongs);
					case 1632:
						defaultCamZoom = 0.4;
						FlxG.camera.flash();
				}
			case 'splitathon':
				switch (curStep)
				{
					case 4750:
						dad.canDance = false;
						dad.playAnim('scared', true);
						camHUD.shake(0.015, (Conductor.stepCrochet / 1000) * 50);
					case 4800:
						FlxG.camera.flash(FlxColor.WHITE, 1);
						splitathonExpression('dave', 'what');
						addSplitathonChar("bambi-splitathon");
						if (!hasTriggeredDumbshit)
						{
							throwThatBitchInThere('bambi-splitathon', 'dave-splitathon');
						}
					case 5824:
						FlxG.camera.flash(FlxColor.WHITE, 1);
						splitathonExpression('bambi', 'umWhatIsHappening');
						addSplitathonChar("dave-splitathon");
					case 6080:
						FlxG.camera.flash(FlxColor.WHITE, 1);
						splitathonExpression('dave', 'happy'); 
						addSplitathonChar("bambi-splitathon");
					case 8384:
						FlxG.camera.flash(FlxColor.WHITE, 1);
						splitathonExpression('bambi', 'yummyCornLol');
						addSplitathonChar("dave-splitathon");
					case 4799 | 5823 | 6079 | 8383:
						hasTriggeredDumbshit = false;
						updatevels = false;
				}

			case 'insanity':
				switch (curStep)
				{
					case 384 | 1040:
						defaultCamZoom = 0.9;
					case 448 | 1056:
						defaultCamZoom = 0.8;
					case 512 | 768:
						defaultCamZoom = 1;
					case 640:
						defaultCamZoom = 1.1;
					case 660 | 680:
						FlxG.sound.play(Paths.sound('static'), 0.1);
						dad.visible = false;
						dadmirror.visible = true;
						curbg.visible = true;
						iconP2.changeIcon(dadmirror.curCharacter);
					case 664 | 684:
						dad.visible = true;
						dadmirror.visible = false;
						curbg.visible = false;
						iconP2.changeIcon(dad.curCharacter);
					case 708:
						defaultCamZoom = 0.8;
						dad.playAnim('um', true);

					case 1176:
						FlxG.sound.play(Paths.sound('static'), 0.1);
						dad.visible = false;
						dadmirror.visible = true;
						curbg.loadGraphic(Paths.image('backgrounds/void/redsky', 'shared'));
						if (isShaggy) curbg.y -= 200;
						curbg.alpha = 1;
						curbg.visible = true;
						iconP2.changeIcon(dadmirror.curCharacter);
					case 1180:
						dad.visible = true;
						dadmirror.visible = false;
						iconP2.changeIcon(dad.curCharacter);
						dad.canDance = false;
						dad.animation.play('scared', true);
				}
			case 'interdimensional':
				switch(curStep)
				{
					case 378:
						FlxG.camera.fade(FlxColor.WHITE, 0.3, false);
					case 384:
						black = new FlxSprite(0,0).makeGraphic(2560, 1440, FlxColor.BLACK);
						black.screenCenter();
						black.scrollFactor.set();
						black.alpha = 0.4;
						add(black);
						defaultCamZoom += 0.2;
						FlxG.camera.fade(FlxColor.WHITE, 0.5, true);
					case 512:
						defaultCamZoom -= 0.1;
					case 639:
						FlxG.camera.flash(FlxColor.WHITE, 0.3, false);
						defaultCamZoom -= 0.1; // pooop
						FlxTween.tween(black, {alpha: 0}, 0.5, 
						{
							onComplete: function(tween:FlxTween)
							{
								remove(black);
							}
						});
						changeInterdimensionBg('spike-void');
					case 1152:
						FlxG.camera.flash(FlxColor.WHITE, 0.3, false);
						changeInterdimensionBg('darkSpace');
						
						tweenList.push(FlxTween.color(gf, 1, gf.color, FlxColor.BLUE));
						tweenList.push(FlxTween.color(dad, 1, dad.color, FlxColor.BLUE));
						bfTween = FlxTween.color(boyfriend, 1, boyfriend.color, FlxColor.BLUE);
						flyingBgChars.forEach(function(char:FlyingBGChar)
						{
							tweenList.push(FlxTween.color(char, 1, char.color, FlxColor.BLUE));
						});
					case 1408:
						FlxG.camera.flash(FlxColor.WHITE, 0.3, false);
						changeInterdimensionBg('hexagon-void');

						tweenList.push(FlxTween.color(dad, 1, dad.color, FlxColor.WHITE));
						bfTween = FlxTween.color(boyfriend, 1, boyfriend.color, FlxColor.WHITE);
						tweenList.push(FlxTween.color(gf, 1, gf.color, FlxColor.WHITE));
						flyingBgChars.forEach(function(char:FlyingBGChar)
						{
							tweenList.push(FlxTween.color(char, 1, char.color, FlxColor.WHITE));
						});
					case 1792:
						FlxG.camera.flash(FlxColor.WHITE, 0.3, false);
						changeInterdimensionBg('nimbi-void');
					case 2176:
						FlxG.camera.flash(FlxColor.WHITE, 0.3, false);
						changeInterdimensionBg('interdimension-void');
					case 2688:
						defaultCamZoom = 0.7;
						for (bgSprite in backgroundSprites)
						{
							FlxTween.tween(bgSprite, {alpha: 0}, 1);
						}
						for (bgSprite in revertedBG)
						{
							FlxTween.tween(bgSprite, {alpha: 1}, 1);
						}

						canFloat = false;
						FlxG.camera.flash(FlxColor.WHITE, 0.25);
						switchDad('dave-festival', dad.getPosition(), false);

						regenerateStaticArrows(0);
						
						var color = getBackgroundColor(curStage);

						FlxTween.color(dad, 0.6, dad.color, color);
						if (formoverride != 'tristan-golden-glowing')
						{
							FlxTween.color(boyfriend, 0.6, boyfriend.color, color);
						}
						FlxTween.color(gf, 0.6, gf.color, color);

						FlxTween.linearMotion(dad, dad.x, dad.y, 100 + dad.globalOffset[0], 450 + dad.globalOffset[1], 0.6, true);
						if (isShaggy) {
							FlxTween.linearMotion(boyfriend, boyfriend.x, boyfriend.y, 770 + boyfriend.globalOffset[0], 450 + boyfriend.globalOffset[1], 0.6, true);
							shx = 770 + boyfriend.globalOffset[0];
							shy = 450 + boyfriend.globalOffset[1];
						}
						
						if (!isShaggy) {
							for (char in [boyfriend, gf])
							{
								if (char.animation.curAnim != null && char.animation.curAnim.name.startsWith('sing') && !char.animation.curAnim.finished)
								{
									char.animation.finishCallback = function(animation:String)
									{
										char.canDance = false;
										char == boyfriend ? char.playAnim('hey', true) : char.playAnim('cheer', true);
									}
								}
								else
								{
									char.canDance = false;
									char == boyfriend ? char.playAnim('hey', true) : char.playAnim('cheer', true);
								}
							}
						}
				}

			case 'unfairness':
				switch(curStep)
				{
					case 256:
						defaultCamZoom += 0.2;
						black = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
						black.screenCenter();
						black.alpha = 0;
						add(black);
						FlxTween.tween(black, {alpha: 0.6}, 1);
						makeInvisibleNotes(true);
					case 261:
						subtitleManager.addSubtitle(LanguageManager.getTextString('unfairness_sub1'), 0.02, 0.6);
					case 284:
					    subtitleManager.addSubtitle(LanguageManager.getTextString('unfairness_sub2'), 0.02, 0.6);
					case 321:
						subtitleManager.addSubtitle(LanguageManager.getTextString('unfairness_sub3'), 0.02, 0.6);
					case 353:
						subtitleManager.addSubtitle(LanguageManager.getTextString('unfairness_sub4'), 0.02, 1.5);
					case 414:
						subtitleManager.addSubtitle(LanguageManager.getTextString('unfairness_sub5'), 0.02, 0.6);
					case 439:
						subtitleManager.addSubtitle(LanguageManager.getTextString('unfairness_sub6'), 0.02, 1);
					case 468:
						subtitleManager.addSubtitle(LanguageManager.getTextString('unfairness_sub7'), 0.02, 1);
					case 512:
						defaultCamZoom -= 0.2;
						FlxTween.tween(black, {alpha: 0}, 1);
						makeInvisibleNotes(false);
					case 2560:
						if (modchartoption) {
							dadStrums.forEach(function(spr:StrumNote)
							{
								FlxTween.tween(spr, {alpha: 0}, 6);
							});
						}
					case 2688:
						if (modchartoption) {
							playerStrums.forEach(function(spr:StrumNote)
							{
								FlxTween.tween(spr, {alpha: 0}, 6);
							});
						}
					case 3072:
						FlxG.camera.flash(FlxColor.WHITE, 1);
						dad.visible = false;
						iconP2.visible = false;
				}
				case 'cheating':
					switch(curStep)
					{
						case 512:
							defaultCamZoom += 0.2;
							black = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
							black.screenCenter();
							black.alpha = 0;
							add(black);
							FlxTween.tween(black, {alpha: 0.6}, 1);
							makeInvisibleNotes(true);
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub1'), 0.02, 0.6);
						case 537:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub2'), 0.02, 0.6);
						case 552:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub3'), 0.02, 0.6);
						case 570:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub4'), 0.02, 1);
						case 595:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub5'), 0.02, 0.6);
						case 607:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub6'), 0.02, 0.6);
						case 619:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub7'), 0.02, 1);
						case 640:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub8'), 0.02, 0.6);
						case 649:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub9'), 0.02, 0.6);
						case 654:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub10'), 0.02, 0.6);
						case 666:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub11'), 0.02, 0.6);
						case 675:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub12'), 0.02, 0.6);
						case 685:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub13'), 0.02, 0.6);
						case 695:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub14'), 0.02, 0.6);
						case 712:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub15'), 0.02, 0.6);
						case 715:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub16'), 0.02, 0.6);
						case 722:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub17'), 0.02, 0.6);
						case 745:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub18'), 0.02, 0.3);
						case 749:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub19'), 0.02, 0.3);
						case 756:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub20'), 0.02, 0.6);
						case 768:
							defaultCamZoom -= 0.2;
							FlxTween.tween(black, {alpha: 0}, 1);
							makeInvisibleNotes(false);
						case 1280:
							defaultCamZoom += 0.2;
							black = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
							black.screenCenter();
							black.alpha = 0;
							add(black);
							FlxTween.tween(black, {alpha: 0.6}, 1);
						case 1301:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub21'), 0.02, 0.6);
						case 1316:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub22'), 0.02, 0.6);
						case 1344:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub23'), 0.02, 0.6);
						case 1374:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub24'), 0.02, 1);
						case 1394:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub25'), 0.02, 0.5);
						case 1403:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub26'), 0.02, 1);
						case 1429:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub27'), 0.02, 0.6);
						case 1475:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub28'), 0.02, 1.5);
						case 1504:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub29'), 0.02, 1);
						case 1528:
							subtitleManager.addSubtitle(LanguageManager.getTextString('cheating_sub30'), 0.02, 0.6);
						case 1536:
							defaultCamZoom -= 0.2;
							FlxTween.tween(black, {alpha: 0}, 1);

					}
			case 'polygonized':
				switch(curStep)
				{
					case 128 | 640 | 704 | 1535:
						defaultCamZoom = 0.9;
					case 256 | 768 | 1468 | 1596 | 2048 | 2144 | 2428:
						defaultCamZoom = 0.7;
					case 688 | 752 | 1279 | 1663 | 2176:
						defaultCamZoom = 1;
					case 1019 | 1471 | 1599 | 2064:
						defaultCamZoom = 0.8;
					case 1920:
						defaultCamZoom = 1.1;

					case 1024 | 1312:
						defaultCamZoom = 1.1;
						crazyZooming = true;

						if (localFunny != CharacterFunnyEffect.Recurser)
						{
							shakeCam = true;
							pre3dSkin = boyfriend.curCharacter;
							for (char in [boyfriend, gf])
							{
								if (char.skins.exists('3d'))
								{
									if (char == boyfriend)
									{
										switchBF(char.skins.get('3d'), char.getPosition());
									}
									else if (char == gf)
									{
										switchGF(char.skins.get('3d'), char.getPosition());
									}
								}
							}
						}
					case 1152 | 1408:
						defaultCamZoom = 0.9;
						shakeCam = false;
						crazyZooming = false;
						if (localFunny != CharacterFunnyEffect.Recurser)
						{
							if (boyfriend.curCharacter != pre3dSkin)
							{
								switchBF(pre3dSkin, boyfriend.getPosition());
								switchGF(boyfriend.skins.get('gfSkin'), gf.getPosition());
							}
						}
				}
			case 'adventure':
				switch (curStep)
				{
					case 1151:
						defaultCamZoom = 1;
					case 1407:
						defaultCamZoom = 0.8;	
				}
			case 'glitch':
				switch (curStep)
				{
					case 15:
						dad.playAnim('hey', true);
					case 16 | 719 | 1167:
						defaultCamZoom = 1;
					case 80 | 335 | 588 | 1103:
						defaultCamZoom = 0.8;
					case 584 | 1039:
						defaultCamZoom = 1.2;
					case 272 | 975:
						defaultCamZoom = 1.1;
					case 464:
						defaultCamZoom = 1;
						FlxTween.linearMotion(dad, dad.x, dad.y, 25, 50, 20, true);
					case 848:
						shakeCam = false;
						crazyZooming = false;
						defaultCamZoom = 1;
					case 132 | 612 | 740 | 771 | 836:
						shakeCam = true;
						crazyZooming = true;
						defaultCamZoom = 1.2;
					case 144 | 624 | 752 | 784:
						shakeCam = false;
						crazyZooming = false;
						defaultCamZoom = 0.8;
					case 1231:
						defaultCamZoom = 0.8;
						FlxTween.linearMotion(dad, dad.x, dad.y, 50, 280, 1, true);
				}
			case 'mealie':
				switch (curStep)
				{
					case 659:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub1'), 0.02, 0.6);
					case 1183:
						defaultCamZoom += 0.2;
						black = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
						black.screenCenter();
						black.alpha = 0;
						add(black);
						FlxTween.tween(black, {alpha: 0.6}, 1);
						makeInvisibleNotes(true);
					case 1193:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub2'), 0.02, 0.6);
					case 1208:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub3'), 0.02, 1.5);
					case 1228:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub4'), 0.02, 1);
					case 1242:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub5'), 0.02, 1);
					case 1257:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub6'), 0.02, 0.5);
					case 1266:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub7'), 0.02, 1.5);
					case 1289:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub8'), 0.02, 2);
					case 1344:
						defaultCamZoom -= 0.2;
						FlxTween.tween(black, {alpha: 0}, 1);
						makeInvisibleNotes(false);
					case 1584:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub15'), 0.02, 1);
					case 1746:
					case 1751:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub9'), 0.02, 0.6);
					case 1770:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub10'), 0.02, 0.6);
					case 1776:
						FlxG.camera.flash(FlxColor.WHITE, 0.25);
						switchDad(FlxG.random.int(0, 999) == 0 ? 'bambi-angey-old' : 'bambi-angey', dad.getPosition());
						dad.color = nightColor;
					case 1800:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub11'), 0.02, 0.6);
					case 1810:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub12'), 0.02, 0.6);
					case 1843:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub13'), 0.02, 1, {subtitleSize: 60});
					case 2418:
						subtitleManager.addSubtitle(LanguageManager.getTextString('mealie_sub14'), 0.02, 0.6);				
				}
			case 'indignancy':
				switch (curStep)
				{
					case 128:
						FlxTween.tween(vignette, {alpha: 0}, 1);
					case 124 | 304 | 496 | 502 | 576 | 848:
						defaultCamZoom += 0.2;
					case 176:
						defaultCamZoom -= 0.2;
						crazyZooming = true;
					case 320 | 832 | 864:
						defaultCamZoom -= 0.2;
					case 508:
						defaultCamZoom -= 0.4;		
					case 320 | 864:
						crazyZooming = true;	
					case 304 | 832 | 1088 | 2144:
						crazyZooming = false;
					case 1216:
						defaultCamZoom += 0.2;
						black = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
						black.screenCenter();
						black.alpha = 0;
						add(black);
						FlxTween.tween(black, {alpha: 0.6}, 1);
						makeInvisibleNotes(true);
					case 1217:
						subtitleManager.addSubtitle(LanguageManager.getTextString('indignancy_sub1'), 0.02, 2);
					case 1262:
						subtitleManager.addSubtitle(LanguageManager.getTextString('indignancy_sub2'), 0.02, 1.5);
					case 1292:
						subtitleManager.addSubtitle(LanguageManager.getTextString('indignancy_sub3'), 0.02, 1);
					case 1330:
						subtitleManager.addSubtitle(LanguageManager.getTextString('indignancy_sub4'), 0.02, 0.5);
				    case 1344:
						defaultCamZoom -= 0.2;
						FlxTween.tween(black, {alpha: 0}, 1);
						makeInvisibleNotes(false);
					case 1622:
						subtitleManager.addSubtitle(LanguageManager.getTextString('indignancy_sub5'), 0.02, 0.3);
						
						defaultCamZoom += 0.4;
						FlxG.camera.shake(0.015, 0.6);
						dad.canDance = false;
						dad.playAnim('scream', true);
						dad.animation.finishCallback = function(animation:String)
						{
							dad.canDance = true;
						}
					case 1632:
						defaultCamZoom -= 0.4;
						crazyZooming = true;
						FlxG.camera.flash(FlxColor.WHITE, 0.5);
				}
				switch (curBeat)
				{
					case 335:
						if (!spotLightPart)
						{
							spotLightPart = true;
							FlxG.camera.flash(FlxColor.WHITE, 0.5);
	
							spotLight = new FlxSprite().loadGraphic(Paths.image('spotLight'));
							spotLight.blend = BlendMode.ADD;
							spotLight.setGraphicSize(Std.int(spotLight.width * (dad.frameWidth / spotLight.width) * spotLightScaler));
							spotLight.updateHitbox();
							spotLight.alpha = 0;
							spotLight.origin.set(spotLight.origin.x,spotLight.origin.y - (spotLight.frameHeight / 2));
							add(spotLight);
	
							spotLight.setPosition(dad.getGraphicMidpoint().x - spotLight.width / 2, dad.getGraphicMidpoint().y + dad.frameHeight / 2 - (spotLight.height));
	
							updateSpotlight(false);
							
							FlxTween.tween(black, {alpha: 0.6}, 1);
							FlxTween.tween(spotLight, {alpha: 1}, 1);
						}
					case 408:
						spotLightPart = false;
						FlxTween.tween(spotLight, {alpha: 0}, 1, {onComplete: function(tween:FlxTween)
						{
							remove(spotLight);
						}});
						FlxTween.tween(black, {alpha: 0}, 1);
				}
			case 'exploitation':
				switch(curStep)
				{
					case 12, 18, 23:
						blackScreen.alpha = 1;
						FlxTween.tween(blackScreen, {alpha: 0}, Conductor.crochet / 1000);
						FlxG.sound.play(Paths.sound('static'), 0.5);

						creditsPopup.switchHeading({path: 'songHeadings/glitchHeading', antiAliasing: false, animation: 
						new Animation('glitch', 'glitchHeading', 24, true, [false, false]), iconOffset: 0});
						
						creditsPopup.changeText('', 'none', false);
					case 20:
						creditsPopup.switchHeading({path: 'songHeadings/expungedHeading', antiAliasing: true,
						animation: new Animation('expunged', 'Expunged', 24, true, [false, false]), iconOffset: 0});

						creditsPopup.changeText('Song by Oxygen', 'Oxygen');
					case 14, 24:
						creditsPopup.switchHeading({path: 'songHeadings/expungedHeading', antiAliasing: true,
						animation: new Animation('expunged', 'Expunged', 24, true, [false, false]), iconOffset: 0});

						creditsPopup.changeText('Song by EXPUNGED', 'whoAreYou');
					case 32 | 512:
						FlxTween.tween(boyfriend, {alpha: 0}, 3);
						FlxTween.tween(gf, {alpha: 0}, 3);
						defaultCamZoom = FlxG.camera.zoom + 0.3;
						FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 4);
					case 128 | 576:
						defaultCamZoom = FlxG.camera.zoom - 0.3;
						FlxTween.tween(boyfriend, {alpha: 1}, 0.2);
						FlxTween.tween(gf, {alpha: 1}, 0.2);
						FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom - 0.3}, 0.05);
						mcStarted = true;

					case 184 | 824:
						FlxTween.tween(FlxG.camera, {angle: 10}, 0.1);
					case 188 | 828:
						FlxTween.tween(FlxG.camera, {angle: -10}, 0.1);
					case 192 | 832:
						FlxTween.tween(FlxG.camera, {angle: 0}, 0.2);
					case 1276:
						FlxG.camera.fade(FlxColor.WHITE, (Conductor.stepCrochet / 1000) * 4, false, function()
						{
							FlxG.camera.stopFX();
						});
						FlxG.camera.shake(0.015, (Conductor.stepCrochet / 1000) * 4);
					case 1280:
						shakeCam = true;
						FlxG.camera.zoom -= 0.2;

						windowProperties = [
							Application.current.window.x,
							Application.current.window.y,
							Application.current.window.width,
							Application.current.window.height
						];

						#if windows
						if (modchartoption) popupWindow();
						#end
						
						modchart = ExploitationModchartType.Figure8;
						if (modchartoption) {
							dadStrums.forEach(function(strum:StrumNote)
							{
								strum.resetX();
							});
							playerStrums.forEach(function(strum:StrumNote)
							{
								strum.resetX();
							});
						}

					case 1282:
						expungedBG.loadGraphic(Paths.image('backgrounds/void/exploit/broken_expunged_chain', 'shared'));
						expungedBG.setGraphicSize(Std.int(expungedBG.width * 2));
					case 1311:
						shakeCam = false;
						FlxG.camera.zoom += 0.2;	
					case 1343:
						shakeCam = true;
						FlxG.camera.zoom -= 0.2;	
					case 1375:
						shakeCam = false;
						FlxG.camera.zoom += 0.2;
					case 1487:
						shakeCam = true;
						FlxG.camera.zoom -= 0.2;
					case 1503:
						shakeCam = false;
						FlxG.camera.zoom += 0.2;
					case 1536:						
						expungedBG.loadGraphic(Paths.image('backgrounds/void/exploit/creepyRoom', 'shared'));
						expungedBG.setGraphicSize(Std.int(expungedBG.width * 2));
						expungedBG.setPosition(0, 200);
						
						modchart = ExploitationModchartType.Sex;
						if (modchartoption) {
							dadStrums.forEach(function(strum:StrumNote)
							{
								strum.resetX();
							});
							playerStrums.forEach(function(strum:StrumNote)
							{
								strum.resetX();
							});
						}
					case 2080:
						#if windows
						if (window != null)
						{
							window.close();
							expungedWindowMode = false;
							window = null;
							FlxTween.tween(Application.current.window, {x: windowProperties[0], y: windowProperties[1], width: windowProperties[2], height: windowProperties[3]}, 1, {ease: FlxEase.circInOut});
							FlxTween.tween(iconP2, {alpha: 0}, 1, {ease: FlxEase.bounceOut});
						}
						#end
					case 2083:
						PlatformUtil.sendWindowsNotification("Anticheat.dll", "Threat expunged.dat successfully contained.");
				}
			case 'shredder':
				switch (curStep)
				{
					case 261:
						defaultCamZoom += 0.2;
						FlxG.camera.flash(FlxColor.WHITE, 0.5);
						black = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
						black.screenCenter();
						black.scrollFactor.set();
						black.alpha = 0;
						add(black);
						FlxTween.tween(black, {alpha: 0.6}, 1);
						makeInvisibleNotes(true);
						subtitleManager.addSubtitle(LanguageManager.getTextString('shred_sub1'), 0.02, 0.3);
					case 273:
						subtitleManager.addSubtitle(LanguageManager.getTextString('shred_sub2'), 0.02, 0.6);
					case 296:
						subtitleManager.addSubtitle(LanguageManager.getTextString('shred_sub3'), 0.02, 0.6);
					case 325:
						subtitleManager.addSubtitle(LanguageManager.getTextString('shred_sub4'), 0.02, 0.6);
					case 342:
						subtitleManager.addSubtitle(LanguageManager.getTextString('shred_sub5'), 0.02, 0.6);
					case 356:
						subtitleManager.addSubtitle(LanguageManager.getTextString('shred_sub6'), 0.02, 0.6);
					case 361:
						subtitleManager.addSubtitle(LanguageManager.getTextString('shred_sub7'), 0.02, 0.6);
					case 384:
						subtitleManager.addSubtitle(LanguageManager.getTextString('shred_sub8'), 0.02, 0.6, {subtitleSize: 60});
					case 393:
						subtitleManager.addSubtitle(LanguageManager.getTextString('shred_sub9'), 0.02, 0.6, {subtitleSize: 60});
					case 408:
						subtitleManager.addSubtitle(LanguageManager.getTextString('shred_sub10'), 0.02, 0.6, {subtitleSize: 60});
					case 425:
						subtitleManager.addSubtitle(LanguageManager.getTextString('shred_sub11'), 0.02, 0.6, {subtitleSize: 60});
					case 484:
						subtitleManager.addSubtitle(LanguageManager.getTextString('shred_sub12'), 0.02, 0.6, {subtitleSize: 60});
					case 512:
						defaultCamZoom -= 0.2;
						FlxG.camera.flash();
						FlxTween.tween(black, {alpha: 0}, 1);
						makeInvisibleNotes(false);
					case 784 | 816 | 912 | 944:
						#if SHADERS_ENABLED
						camHUD.setFilters([new ShaderFilter(blockedShader.shader)]);
						#end
						defaultCamZoom += 0.2;
						FlxTween.tween(black, {alpha: 0.6}, 1);
					case 800 | 832 | 928:
						camHUD.setFilters([]);
						defaultCamZoom -= 0.2;
						FlxTween.tween(black, {alpha: 0}, 1);
					case 960:
						camHUD.setFilters([]);
						defaultCamZoom = 0.7;
						FlxTween.tween(black, {alpha: 0}, 1);
					case 992:
						dadStrums.forEach(function(spr:StrumNote)
						{
							FlxTween.tween(spr, {alpha: 0}, 1);
						});
					case 1008:
						switchDad('bambi-shredder', dad.getPosition());
						dad.playAnim('takeOut', true);

					case 1024:
						FlxG.camera.flash(FlxColor.WHITE, 0.5);

						playerStrums.forEach(function(spr:StrumNote)
						{
							FlxTween.cancelTweensOf(spr);
						});

						dadStrums.forEach(function(spr:StrumNote)
						{
							spr.alpha = 1;
						});
						
						lockCam = true;
						
						originalBFScale = boyfriend.scale.copyTo(originalBFScale);
						originBFPos = boyfriend.getPosition();
						originBambiPos = dad.getPosition();

						dad.cameras = [camHUD];
						dad.scale.set(dad.scale.x * 0.55, dad.scale.y * 0.55);
						dad.updateHitbox();
						dad.offsetScale = 0.55;
						dad.scrollFactor.set();
						dad.setPosition(-21, -10);

						bambiSpot = new FlxSprite(34, 151).loadGraphic(Paths.image('festival/shredder/bambi_spot'));
						bambiSpot.scrollFactor.set();
						bambiSpot.blend = BlendMode.ADD;
						bambiSpot.cameras = [camHUD];
						insert(members.indexOf(dadGroup), bambiSpot);

						bfSpot = new FlxSprite(995, 381).loadGraphic(Paths.image('festival/shredder/boyfriend_spot'));
						bfSpot.scrollFactor.set();
						bfSpot.blend = BlendMode.ADD;
						bfSpot.cameras = [camHUD];
						bfSpot.alpha = 0;

						boyfriend.cameras = [camHUD];
						boyfriend.scale.set(boyfriend.scale.x * 0.45, boyfriend.scale.y * 0.45);
						boyfriend.updateHitbox();
						boyfriend.offsetScale = 0.45;
						boyfriend.scrollFactor.set();
						boyfriend.setPosition((bfSpot.x - (boyfriend.width / 3.25)) + boyfriend.globalOffset[0] * boyfriend.offsetScale, (bfSpot.y - (boyfriend.height * 1.1)) + boyfriend.globalOffset[1] * boyfriend.offsetScale);
						if (isShaggy) boyfriend.y += 100;
						shx = (bfSpot.x - (boyfriend.width / 3.25)) + boyfriend.globalOffset[0] * boyfriend.offsetScale;
						shy = (bfSpot.y - (boyfriend.height * 1.1)) + boyfriend.globalOffset[1] * boyfriend.offsetScale;
						boyfriend.alpha = 0;

						insert(members.indexOf(bfGroup), bfSpot);

						highway = new FlxSprite().loadGraphic(Paths.image('festival/shredder/ch_highway'));
						highway.setGraphicSize(Std.int(highway.width * (670 / highway.width)), Std.int(highway.height * (1340 / highway.height)));
						highway.updateHitbox();
						highway.cameras = [camHUD];
						highway.screenCenter();
						highway.scrollFactor.set();
						insert(members.indexOf(strumLineNotes), highway);

						black = new FlxSprite().makeGraphic(2560, 1440, FlxColor.BLACK);
						black.screenCenter();
						black.scrollFactor.set();
						black.alpha = 0.9;
						insert(members.indexOf(highway), black);

						dadStrums.forEach(function(spr:StrumNote)
						{
							dadStrums.remove(spr);
							strumLineNotes.remove(spr);
							remove(spr);
						});
						generateGhNotes(0);
						
						dadStrums.forEach(function(spr:StrumNote)
						{
							spr.centerStrum();
							spr.x -= (spr.width / 4);
						});
						playerStrums.forEach(function(spr:StrumNote)
						{
							spr.centerStrum();
							spr.alpha = 0;
							spr.x -= (noteWidth / 4);
						});
					case 1276:
						dadStrums.forEach(function(spr:StrumNote)
						{
							FlxTween.tween(spr, {alpha: 0}, (Conductor.stepCrochet / 1000) * 2);
						});
						playerStrums.forEach(function(spr:StrumNote)
						{
							FlxTween.tween(spr, {alpha: 1}, (Conductor.stepCrochet / 1000) * 2);
						});
					case 1280:
						FlxTween.tween(boyfriend, {alpha: 1}, 1);
						FlxTween.tween(bfSpot, {alpha: 1}, 1);
					case 1536:
						var blackFront = new FlxSprite(0, 0).makeGraphic(2560, 1440, FlxColor.BLACK);
						blackFront.screenCenter();
						blackFront.alpha = 0;
						blackFront.cameras = [camHUD];
						add(blackFront);
						FlxTween.tween(blackFront, {alpha: 1}, 0.5, {onComplete: function(tween:FlxTween)
						{
							lockCam = false;
							strumLineNotes.forEach(function(spr:StrumNote)
							{
								spr.x = spr.baseX;
							});
							switchDad('bambi-new', originBambiPos, false);

							boyfriend.cameras = dad.cameras;
							boyfriend.scale.set(originalBFScale.x, originalBFScale.y);
							boyfriend.updateHitbox();
							boyfriend.offsetScale = 1;
							boyfriend.scrollFactor.set(1, 1);
							boyfriend.setPosition(originBFPos.x, originBFPos.y);
							shx = originBFPos.x;
							shy = originBFPos.y;
								
							for (hudElement in [black, blackFront, bambiSpot, bfSpot, highway])
							{
								remove(hudElement);
							}
							FlxTween.tween(blackFront, {alpha: 0}, 0.5);
						}});
						regenerateStaticArrows(0);

						defaultCamZoom += 0.2;
						#if SHADERS_ENABLED
						if(CompatTool.save.data.compatMode != null && CompatTool.save.data.compatMode == false)
						{
							camHUD.setFilters([new ShaderFilter(blockedShader.shader)]);
						}
						#end
						FlxTween.tween(black, {alpha: 0.6}, 1);
						makeInvisibleNotes(true);
					case 1552:
						camHUD.setFilters([]);
						defaultCamZoom += 0.1;
					case 1568:
						#if SHADERS_ENABLED
						if(CompatTool.save.data.compatMode != null && CompatTool.save.data.compatMode == false)
							{
								camHUD.setFilters([new ShaderFilter(blockedShader.shader)]);
							}
						#end
						defaultCamZoom += 0.1;
					case 1584:
						camHUD.setFilters([]);
						defaultCamZoom += 0.1;
					case 1600:
						#if SHADERS_ENABLED
						if(CompatTool.save.data.compatMode != null && CompatTool.save.data.compatMode == false)
							{
								camHUD.setFilters([new ShaderFilter(blockedShader.shader)]);
							}
						#end
						defaultCamZoom += 0.1;
					case 1616:
						camHUD.setFilters([]);
						defaultCamZoom += 0.1;
					case 1632:
						#if SHADERS_ENABLED
						if(CompatTool.save.data.compatMode != null && CompatTool.save.data.compatMode == false)
							{
								camHUD.setFilters([new ShaderFilter(blockedShader.shader)]);
							}
						#end
						defaultCamZoom += 0.1;
					case 1648:
						FlxTween.tween(black, {alpha: 1}, 1);
						camHUD.setFilters([]);
						defaultCamZoom += 0.1;
					case 1664:
						defaultCamZoom -= 0.9;
						FlxG.camera.flash();
						FlxTween.tween(black, {alpha: 0}, 1);
						makeInvisibleNotes(false);
					case 1937:
						subtitleManager.addSubtitle(LanguageManager.getTextString('shred_sub13'), 0.02, 0.6, {subtitleSize: 60});
					case 1946:
						subtitleManager.addSubtitle(LanguageManager.getTextString('shred_sub14'), 0.02, 0.6, {subtitleSize: 60});
				}
			case 'rano':
				switch (curStep)
				{
					case 512:
						defaultCamZoom = 0.9;
					case 640:
						defaultCamZoom = 0.7;
					case 1792:
						dad.canDance = false;
						dad.canSing = false;
						dad.playAnim('sleepIdle', true);
						dad.animation.finishCallback = function(anim:String)
						{
							dad.playAnim('sleeping', true);
						}
				}
			case 'five-nights':
				if (!powerRanOut)
				{
					switch (curStep)
					{
						case 60:
							switchNoteSide();
						case 64 | 320 | 480 | 576 | 704 | 832 | 1024:
							nofriendAttack();
						case 992:
							defaultCamZoom = 1.2;
							FlxTween.tween(camHUD, {alpha: 0}, 1);
						case 1088:
							sixAM();
					}
				}
			case 'bot-trot':
				switch (curStep)
				{
					case 896:
						FlxG.camera.flash();
						FlxG.sound.play(Paths.sound('lightswitch'), 1);
						defaultCamZoom = 1.1;
						switchToNight();
					case 1151:
						defaultCamZoom = 0.8;
				}
			case 'supernovae':
				switch (curStep)
				{
					case 60:
						dad.playAnim('hey', true);
					case 64:
						defaultCamZoom = 1;
					case 192:
						defaultCamZoom = 0.9;
					case 320 | 768:
						defaultCamZoom = 1.1;
					case 444:
						defaultCamZoom = 0.6;
					case 448 | 960 | 1344:
						defaultCamZoom = 0.8;
					case 896 | 1152:
						defaultCamZoom = 1.2;
					case 1024:
						defaultCamZoom = 1;
						shakeCam = true;
						FlxTween.linearMotion(dad, dad.x, dad.y, 25, 50, 15, true);

					case 1280:
						FlxTween.linearMotion(dad, dad.x, dad.y, 50, 280, 0.6, true);
						shakeCam = false;
						defaultCamZoom = 1;
				}
			case 'master':
				switch (curStep)
				{
					case 128:
						defaultCamZoom = 0.7;
					case 252 | 512:
						defaultCamZoom = 0.4;
						shakeCam = false;
					case 256:
						defaultCamZoom = 0.8;
					case 380:
						defaultCamZoom = 0.5;
					case 384:
						defaultCamZoom = 1;
						shakeCam = true;
					case 508:
						defaultCamZoom = 1.2;
					case 560:
						dad.playAnim('die', true);			
						FlxG.sound.play(Paths.sound('dead'), 1);
					}
			case 'vs-dave-rap':
				switch(curStep)
				{
						case 64:
							FlxG.camera.flash();
						case 68:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub1'), 0.02, 1);
						case 92:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub2'), 0.02, 0.8);
						case 112:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub3'), 0.02, 0.8);
						case 124:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub4'), 0.02, 0.5);
						case 140:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub5'), 0.02, 0.5);
						case 150:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub6'), 0.02, 1);
						case 176:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub7'), 0.02, 0.5);
						case 184:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub8'), 0.02, 0.8);
						case 201:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub9'), 0.02, 0.5);
						case 211:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub10'), 0.02, 0.8);
						case 229:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub11'), 0.02, 0.5);
						case 241:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub12'), 0.02, 0.8);
						case 260:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub13'), 0.02, 0.8);
						case 281:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub14'), 0.02, 0.5);
						case 288:
							subtitleManager.addSubtitle(LanguageManager.getTextString('daverap_sub15'), 0.02, 1.5);
						case 322:
							FlxG.camera.flash();
					}
		    case 'vs-dave-rap-two':
				switch(curStep)
			    {
					case 62:
						FlxG.camera.flash();
						subtitleManager.addSubtitle(LanguageManager.getTextString('daveraptwo_sub1'), 0.02, 0.5);
					case 79:
						subtitleManager.addSubtitle(LanguageManager.getTextString('daveraptwo_sub2'), 0.02, 0.3);
					case 88:
						subtitleManager.addSubtitle(LanguageManager.getTextString('daveraptwo_sub3'), 0.02, 1.5);
					case 112:
						subtitleManager.addSubtitle(LanguageManager.getTextString('daveraptwo_sub4'), 0.02, 1.5);
					case 140:
						subtitleManager.addSubtitle(LanguageManager.getTextString('daveraptwo_sub5'), 0.02, 1);
					case 168:
						subtitleManager.addSubtitle(LanguageManager.getTextString('daveraptwo_sub6'), 0.02, 0.7);
					case 179:
						subtitleManager.addSubtitle(LanguageManager.getTextString('daveraptwo_sub7'), 0.02, 0.7);
					case 194:
						subtitleManager.addSubtitle(LanguageManager.getTextString('daveraptwo_sub8'), 0.02, 1.5);
					case 222:
						subtitleManager.addSubtitle(LanguageManager.getTextString('daveraptwo_sub9'), 0.02, 2);
					case 256:
						subtitleManager.addSubtitle(LanguageManager.getTextString('daveraptwo_sub10'), 0.02, 2);	
					case 291:
						subtitleManager.addSubtitle(LanguageManager.getTextString('daveraptwo_sub11'), 0.02, 1);
					case 342:
						subtitleManager.addSubtitle(LanguageManager.getTextString('daveraptwo_sub12'), 0.02, 1);
					case 351:
						FlxG.camera.flash();
				}
			case 'memory':
				switch (curStep)
				{
					case 1408:
						defaultCamZoom += 0.2;
						black = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
						black.screenCenter();
						black.alpha = 0;
						add(black);
						FlxTween.tween(black, {alpha: 0.6}, 1);
						makeInvisibleNotes(true);
					case 1422:
						subtitleManager.addSubtitle(LanguageManager.getTextString('memory_sub1'), 0.02, 0.5);
					case 1436:
						subtitleManager.addSubtitle(LanguageManager.getTextString('memory_sub2'), 0.02, 1);
					case 1458:
						subtitleManager.addSubtitle(LanguageManager.getTextString('memory_sub3'), 0.02, 0.7);
					case 1476:
						subtitleManager.addSubtitle(LanguageManager.getTextString('memory_sub4'), 0.02, 1);
					case 1508:
						subtitleManager.addSubtitle(LanguageManager.getTextString('memory_sub5'), 0.02, 1.5);
					case 1541:
						subtitleManager.addSubtitle(LanguageManager.getTextString('memory_sub6'), 0.02, 1);
					case 1561:
						subtitleManager.addSubtitle(LanguageManager.getTextString('memory_sub7'), 0.02, 1);
					case 1583:
						subtitleManager.addSubtitle(LanguageManager.getTextString('memory_sub8'), 0.02, 0.8);
					case 1608:
						defaultCamZoom -= 0.2;
						FlxTween.tween(black, {alpha: 0}, 1);
						makeInvisibleNotes(false);
						subtitleManager.addSubtitle(LanguageManager.getTextString('memory_sub9'), 0.02, 1);
					case 1632:
						subtitleManager.addSubtitle(LanguageManager.getTextString('memory_sub10'), 0.02, 0.5);
					case 1646:
						defaultCamZoom += 0.2;
						black = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
						black.screenCenter();
						black.alpha = 0;
						add(black);
						FlxTween.tween(black, {alpha: 0.6}, 1);
						makeInvisibleNotes(true);
						subtitleManager.addSubtitle(LanguageManager.getTextString('memory_sub11'), 0.02, 1);
					case 1664:
						defaultCamZoom -= 0.2;
						FlxTween.tween(black, {alpha: 0}, 1);
						makeInvisibleNotes(false);
				}
		}
		if (SONG.song.toLowerCase() == 'exploitation' && curStep % 8 == 0)
		{
			var fonts = ['arial', 'chalktastic', 'openSans', 'pkmndp', 'barcode', 'vcr'];
			var chosenFont = fonts[FlxG.random.int(0, fonts.length)];
			kadeEngineWatermark.font = Paths.font('exploit/${chosenFont}.ttf');
			creditsWatermark.font = Paths.font('exploit/${chosenFont}.ttf');
			scoreTxt.font = Paths.font('exploit/${chosenFont}.ttf');
			botplayTxt.font = Paths.font('exploit/${chosenFont}.ttf');
			if (songName != null)
			{
				songName.font = Paths.font('exploit/${chosenFont}.ttf');
			}
		}

		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			if (vocals.volume != 0)
				resyncVocals();
		}
		for (v in extraVocals)
		{
			if (SONG.needsVoices && Math.abs(v.time - (Conductor.songPosition - Conductor.offset)) > 20)
			{
				resyncVocals();
			}
		}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if (spotLightPart && spotLight != null && spotLight.exists && curBeat % 3 == 0)
		{
			FlxTween.cancelTweensOf(spotLight);
			if (spotLight.health != 3)
			{
				FlxTween.tween(spotLight, {angle: 2}, (Conductor.crochet / 1000) * 3, {ease: FlxEase.expoInOut});
				spotLight.health = 3;
			}
			else
			{
				FlxTween.tween(spotLight, {angle: -2}, (Conductor.crochet / 1000) * 3, {ease: FlxEase.expoInOut});
				spotLight.health = 1;
			}
		}

		var currentSection = SONG.notes[Std.int(curStep / 16)];
		if (!UsingNewCam)
		{
			if (generatedMusic && currentSection != null)
			{
				if (curBeat % 4 == 0)
				{
					// trace(currentSection.mustHitSection);
				}

				focusOnDadGlobal = !currentSection.mustHitSection;
				ZoomCam(!currentSection.mustHitSection);
			}
		}

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (currentSection != null)
		{
			if (currentSection.changeBPM)
			{
				Conductor.changeBPM(currentSection.bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		if (dad.animation.finished)
		{
			switch (SONG.song.toLowerCase())
			{
				case 'warmup':
					dad.dance();
					if (dadmirror != null)
					{
						dadmirror.dance();
					}
				default:
					if (dad.holdTimer <= 0 && curBeat % 2 == 0)
					{
						dad.dance();
						if (dadmirror != null)
						{
							dadmirror.dance();
						}

						dadNoteCamOffset[0] = 0;
						dadNoteCamOffset[1] = 0;
					}
			}
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);
		#if SHADERS_ENABLED
		wiggleShit.update(Conductor.crochet);
		#end
		
		if (curBeat % gfSpeed == 0)
		{
			if (!shakeCam && gf.canDance)
			{
				gf.dance();
			}
		}

		if (camZooming && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}
		if (crazyZooming)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}	
		if (curBeat % 4 == 0 && SONG.song.toLowerCase() == 'recursed')
		{
			freeplayBG.alpha = 0.8;
			charBackdrop.alpha = 0.8;

			for (char in alphaCharacters)
			{
				for (letter in char)
				{
					letter.alpha = 0.4;
				}
			}
		}
		if (curBeat % 2 == 0)
		{
			crowdPeople.forEach(function(crowdPerson:BGSprite)
			{
				crowdPerson.animation.play('idle', true);
			});
		}
		if (curBeat % 2 == 0 && tristan != null)
		{
			tristan.animation.play(curTristanAnim);
		}
		if (curBeat % 4 == 0 && spotLightPart && spotLight != null)
		{
			updateSpotlight(currentSection.mustHitSection);
		}
		if (SONG.song.toLowerCase() == 'shredder' && curBeat % 4 == 0)
		{
			var curSection = SONG.notes.indexOf(currentSection);
			guitarSection = curSection >= 64 && curSection < 80;
			dadStrumAmount = guitarSection ? 5 : Main.keyAmmo[mania];
			if (guitarSection)
			{
				notes.forEachAlive(function(daNote:Note)
				{
					daNote.MyStrum = null;
				});
			}
		}
		switch (curSong.toLowerCase())
		{
			//exploitation stuff
			case 'exploitation':
				switch(curStep)
			    {
					case 32:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub1'), 0.02, 1);
					case 56:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub2'), 0.02, 0.8);
					case 64:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub3'), 0.02, 1);
					case 85:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub4'), 0.02, 1);
					case 99:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub5'), 0.02, 0.5);
					case 105:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub6'), 0.02, 0.5);
					case 117:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub7'), 0.02, 1);
					case 512:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub8'), 0.02, 1);
					case 524:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub9'), 0.02, 1);
					case 533:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub10'), 0.02, 0.7);
					case 545:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub11'), 0.02, 1);
					case 566:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub12'), 0.02, 1);
					case 1263:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub13'), 0.02, 0.3);
					case 1270:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub14'), 0.02, 0.3);
					case 1276:
						subtitleManager.addSubtitle(LanguageManager.getTextString('exploit_sub15'), 0.02, 0.3);
					case 1100:
						PlatformUtil.sendWindowsNotification("Anticheat.dll", "Potential threat detected: expunged.dat");
				}
				if (modchartoption) {
					switch (curBeat)
					{
						case 40:
							if (mania == 5)
								switchNotePositions([17, 18, 15, 21, 23, 20, 13, 19, 22, 16, 12, 14, 1, 4, 10, 8, 2, 0, 11, 7, 6, 5, 3, 9]);
							else
								switchNotePositions([6,7,5,4,3,2,0,1]);
							switchNoteScroll(false);
						case 44:
							if (mania == 5)
								switchNotePositions([1, 2, 8, 10, 4, 5, 3, 11, 0, 6, 9, 7, 18, 12, 16, 22, 23, 14, 21, 19, 15, 13, 17, 20]);
							else
								switchNotePositions([0,1,3,2,4,5,7,6]);
						case 46:
							if (mania == 5)
								switchNotePositions([17, 18, 15, 21, 23, 20, 13, 19, 22, 16, 12, 14, 1, 4, 10, 8, 2, 0, 11, 7, 6, 5, 3, 9]);
							else
								switchNotePositions([6,7,5,4,3,2,0,1]);
							switchNoteScroll(false);
						case 56:
							if (mania == 5)
								switchNotePositions([6, 10, 2, 5, 9, 0, 3, 1, 8, 7, 4, 11, 23, 17, 20, 21, 19, 15, 13, 12, 18, 14, 16, 22]);
							else
								switchNotePositions([1,3,2,0,5,7,6,4]);
						case 60:
							if (mania == 5)
								switchNotePositions([17, 23, 18, 20, 21, 22, 14, 12, 19, 16, 13, 15, 1, 5, 2, 4, 10, 0, 9, 11, 7, 6, 3, 8]);
							else
								switchNotePositions([4,6,7,5,0,2,3,1]);
							switchNoteScroll(false);
						case 62:
							if (mania == 5)
								switchNotePositions([21, 3, 15, 17, 22, 9, 7, 2, 18, 4, 8, 5, 0, 23, 19, 14, 20, 12, 6, 10, 11, 16, 1, 13]);
							else
								switchNotePositions([7,1,0,2,3,5,4,6]);
							switchNoteScroll(false);
						case 120:
							switchNoteScroll();
						case 124:
							switchNoteScroll();
						case 72:
							if (mania == 5)
								switchNotePositions([9, 18, 16, 23, 3, 20, 7, 1, 5, 8, 14, 17, 11, 12, 22, 4, 10, 6, 13, 19, 2, 15, 0, 21]);
							else
								switchNotePositions([6,7,2,3,4,5,0,1]);
						case 76:
							if (mania == 5)
								switchNotePositions([23, 0, 17, 21, 16, 15, 6, 12, 10, 1, 19, 20, 3, 22, 14, 9, 13, 11, 2, 4, 5, 7, 18, 8]);
							else
								switchNotePositions([6,7,4,5,2,3,0,1]);
						case 80:
							if (mania == 5)
								switchNotePositions([6, 2, 5, 18, 12, 1, 20, 23, 13, 15, 0, 11, 22, 19, 4, 14, 9, 7, 16, 10, 8, 21, 17, 3]);
							else
								switchNotePositions([1,0,2,4,3,5,7,6]);
						case 88:
							if (mania == 5)
								switchNotePositions([10, 5, 6, 17, 13, 21, 8, 22, 11, 9, 4, 7, 0, 23, 16, 12, 1, 14, 18, 3, 19, 2, 20, 15]);
							else
								switchNotePositions([4,2,0,1,6,7,5,3]);
						case 90:
							switchNoteSide();
						case 92:
							switchNoteSide();
						case 112:
							dadStrums.forEach(function(strum:StrumNote)
							{
								var targetPosition = (mania == 5 ? 13 : FlxG.width / 8) + Note.swagWidth * Math.abs(2 * strum.ID) + 78 - (78 / 2);
								FlxTween.completeTweensOf(strum);
								strum.angle = 0;
				
								FlxTween.angle(strum, strum.angle, strum.angle + 360, 0.2, {ease: FlxEase.circOut});
								FlxTween.tween(strum, {x: targetPosition}, 0.6, {ease: FlxEase.backOut});
								
							});
							playerStrums.forEach(function(strum:StrumNote)
							{
								var targetPosition = (mania == 5 ? 13 : FlxG.width / 8) + Note.swagWidth * Math.abs((2 * strum.ID) + 1) + 78 - (78 / 2);
								
								FlxTween.completeTweensOf(strum);
								strum.angle = 0;
				
								FlxTween.angle(strum, strum.angle, strum.angle + 360, 0.2, {ease: FlxEase.circOut});
								FlxTween.tween(strum, {x: targetPosition}, 0.6, {ease: FlxEase.backOut});
							});
						case 143:
							swapGlitch(Conductor.crochet / 1500, 'cheating');
						case 144:
							modchart = ExploitationModchartType.Cheating; //While we're here, lets bring back a familiar modchart
						case 191:
							swapGlitch(Conductor.crochet / 1500, 'expunged');
						case 192:
							dadStrums.forEach(function(strum:StrumNote)
							{
								strum.resetX();
							});
							playerStrums.forEach(function(strum:StrumNote)
							{
								strum.resetX();
							});
							modchart = ExploitationModchartType.Cyclone;
						case 224:
							modchart = ExploitationModchartType.Jitterwave;
						case 255:
							swapGlitch(Conductor.crochet / 4000, 'unfair');
						case 256:
							modchart = ExploitationModchartType.Unfairness;
						case 287:
							swapGlitch(Conductor.crochet / 1500, 'chains');
						case 288:
							dadStrums.forEach(function(strum:StrumNote)
							{
								strum.resetX();
							});
							playerStrums.forEach(function(strum:StrumNote)
							{
								strum.resetX();
							});
							modchart = ExploitationModchartType.PingPong;
						case 455:
							swapGlitch(Conductor.crochet / 1500, 'cheating-2');
							modchart = ExploitationModchartType.None;
							dadStrums.forEach(function(strum:StrumNote)
							{
								strum.resetX();
								strum.resetY();
							});
							playerStrums.forEach(function(strum:StrumNote)
							{
								strum.resetX();
								strum.resetY();
							});
						case 456:
							if (mania == 5)
								switchNotePositions([7, 10, 1, 2, 11, 8, 6, 3, 0, 4, 9, 5, 13, 14, 15, 18, 17, 22, 16, 23, 20, 12, 19, 21]);
							else
								switchNotePositions([1,0,2,3,4,5,7,6]);
						case 460:
							if (mania == 5)
								switchNotePositions([2, 10, 8, 9, 5, 6, 4, 3, 11, 1, 0, 7, 22, 17, 18, 21, 19, 23, 12, 20, 13, 15, 16, 14]);
							else
								switchNotePositions([1,2,0,3,4,7,5,6]);
						case 465:
							if (mania == 5)
								switchNotePositions([3, 0, 9, 6, 10, 1, 5, 2, 7, 8, 11, 4, 17, 13, 18, 12, 15, 20, 19, 21, 22, 14, 16, 23]);
							else
								switchNotePositions([1,2,3,0,7,4,5,6]);
						case 470:
							if (mania == 5)
								switchNotePositions([2, 6, 0, 7, 21, 4, 20, 13, 11, 1, 12, 22, 5, 17, 16, 10, 9, 14, 3, 8, 23, 15, 18, 19]);
							else
								switchNotePositions([6,2,3,0,7,4,5,1]);
						case 475:
							if (mania == 5)
								switchNotePositions([17, 6, 10, 7, 2, 12, 21, 20, 4, 19, 9, 15, 0, 1, 3, 22, 23, 14, 16, 11, 8, 5, 18, 13]);
							else
								switchNotePositions([2,6,3,0,7,5,4,1]);
						case 480:
							if (mania == 5)
								switchNotePositions([17, 9, 16, 13, 15, 19, 14, 18, 3, 11, 2, 20, 4, 0, 8, 23, 6, 5, 10, 1, 7, 22, 21, 12]);
							else
								switchNotePositions([2,3,6,0,5,7,4,1]);
						case 486:
							swapGlitch((Conductor.crochet / 4000) * 2, 'expunged');
						case 487:
							modchart = ExploitationModchartType.ScrambledNotes;
					}
				}
			case 'polygonized':
				switch (curBeat)
				{
					case 608:
						defaultCamZoom = 0.8;
						if (PlayState.instance.localFunny != PlayState.CharacterFunnyEffect.Recurser)
						{
							for (bgSprite in backgroundSprites)
							{
								FlxTween.tween(bgSprite, {alpha: 0}, 1);
							}
							for (bgSprite in revertedBG)
							{
								FlxTween.tween(bgSprite, {alpha: 1}, 1);
							}
							for (char in [boyfriend, gf])
							{
								if (char.animation.curAnim != null && char.animation.curAnim.name.startsWith('sing') && !char.animation.curAnim.finished)
								{
									char.animation.finishCallback = function(animation:String)
									{
										char.canDance = false;
										char == boyfriend ? char.playAnim('hey', true) : char.playAnim('cheer', true);
									}
								}
								else
								{
									char.canDance = false;
									char == boyfriend ? char.playAnim('hey', true) : char.playAnim('cheer', true);
								}
							}

							canFloat = false;
							FlxG.camera.flash(FlxColor.WHITE, 0.25);

							switchDad('dave', dad.getPosition(), false);

							FlxTween.color(dad, 0.6, dad.color, nightColor);
							if (form7889 != 'tristan-golden-glowing')
							{
								FlxTween.color(boyfriend, 0.6, boyfriend.color, nightColor);
							}
							FlxTween.color(gf, 0.6, gf.color, nightColor);

							dad.setPosition(50, 270);
							boyfriend.setPosition(843, 270);
							shx = 843;
							shy = 270;
							gf.setPosition(230, -60);
							for (char in [dad, boyfriend, gf])
							{
								repositionChar(char);
							}
							regenerateStaticArrows(0);
						}
						else
						{
							FlxG.sound.play(Paths.sound('static'), 0.1);
							curbg.loadGraphic(Paths.image('backgrounds/void/redsky', 'shared'));
							curbg.alpha = 1;
							curbg.visible = true;
							dad.animation.play('scared', true);
							dad.canDance = false;
						}
				}
			case 'memory':
				switch (curBeat)
				{
					case 416:
						switchDad('dave-annoyed', dad.getPosition());
						crazyZooming = true;
					case 672:
						crazyZooming = false;
				}
			case 'escape-from-california':
				switch (curBeat)
				{
					case 2:
						makeInvisibleNotes(true);
						defaultCamZoom += 0.2;
						subtitleManager.addSubtitle(LanguageManager.getTextString('california_sub1'), 0.02, 1.5);
					case 14:
					    subtitleManager.addSubtitle(LanguageManager.getTextString('california_sub2'), 0.04, 0.3, {subtitleSize: 60});
						FlxG.camera.fade(FlxColor.WHITE, 0.6, false, function()
						{
							FlxG.camera.fade(FlxColor.WHITE, 0, true);
						});
						FlxG.camera.shake(0.015, 0.6);
					case 16:
					    FlxG.camera.flash();
					    defaultCamZoom -= 0.2;
						makeInvisibleNotes(false);
					case 270:
						subtitleManager.addSubtitle(LanguageManager.getTextString('california_sub2'), 0.04, 0.3, {subtitleSize: 60});
						FlxG.camera.shake(0.005, 0.6);
						dad.canSing = false;
						dad.canDance = false;
						dad.playAnim('waa', true);
						dad.animation.finishCallback = function(anim:String)
						{
							dad.canSing = true;
							dad.canDance = true;
						}
					case 208:
						changeSign('1500miles');
					case 400:
						changeSign('1000miles');
					case 528:
						changeSign('500miles');
					case 712:
						FlxG.camera.fade(FlxColor.WHITE, (Conductor.crochet * 8) / 1000, false, function()
						{
							FlxG.camera.stopFX();
							FlxG.camera.flash();
						});
					case 720:
						FlxTween.num(trainSpeed, 0, 3, {ease: FlxEase.expoOut}, function(newValue:Float)
						{
							trainSpeed = newValue;
							train.animation.curAnim.frameRate = Std.int(FlxMath.lerp(0, 24, (trainSpeed / 30)));
						});
						changeSign('welcomeToGeorgia', new FlxPoint(1000, 450));

						remove(desertBG);
						remove(desertBG2);
						
					
						georgia = new BGSprite('georgia', 400, -50, Paths.image('california/geor gea', 'shared'), null, 1, 1, true);
						georgia.setGraphicSize(Std.int(georgia.width * 2.5));
						georgia.updateHitbox();
						georgia.color = nightColor;
						backgroundSprites.add(georgia);
						add(georgia);
				}
			case 'mealie':
				switch(curBeat) {
                    case 464:
						crazyZooming = true;
					case 592:
						crazyZooming = false;
				}
		}
		if (shakeCam)
		{
			gf.playAnim('scared', true);
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}

		switch (curStage)
		{
			case 'tank':
				if(!ClientPrefs.lowQuality) tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});

			case 'school':
				if(!ClientPrefs.lowQuality) {
					bgGirls.dance();
				}

			case 'mall':
				if(!ClientPrefs.lowQuality) {
					upperBoppers.dance(true);
				}

				if(heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);

			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			{
				moveCameraSection();
			}

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
		}
		
		setOnLuas('curSection', curSection);
		callOnLuas('onSectionHit', []);
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var ret:Dynamic = script.call(event, args);
			if(ret == FunkinLua.Function_StopLua && !ignoreStops)
				break;
			
			if(ret != FunkinLua.Function_Continue)
				returnVal = ret;
		}
		#end
		//trace(event, returnVal);
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);
		
		if (badHit)
			updateScore(true); // miss notes shouldn't make the scoretxt bounce -Ghost
		else
			updateScore(false);

		var ret:Dynamic = callOnLuas('onRecalculateRating', [], false);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				switch(achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss' | 'week7_nomiss':
						if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							switch(weekName) //I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'week1':
									if(achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if(achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if(achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if(achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if(achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if(achievementName == 'week6_nomiss') unlock = true;
								case 'week7':
									if(achievementName == 'week7_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing && !ClientPrefs.imagesPersist) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
					case 'beat_godspeed': 
						if(Paths.formatToSongPath(SONG.song) == 'godspeed' && !usedPractice) {
							unlock = true;
						}
					case 'beat_uc': 
						if(Paths.formatToSongPath(SONG.song) == 'universal-catastrophy' && !usedPractice) {
							unlock = true;
						}
					case 'beat_mar': 
						if(Paths.formatToSongPath(SONG.song) == 'monsters-arent-real' && !usedPractice) {
							unlock = true;
						}
					case 'beat_funny': 
						if(Paths.formatToSongPath(SONG.song) == "what-i-wanna-know-is-where's-the-caveman" && !usedPractice) {
							unlock = true;
						}
					case 'fc_godspeed':
						if(Paths.formatToSongPath(SONG.song) == 'godspeed' && !usedPractice && songMisses < 1) {
							unlock = true;
						}
					case 'beat_god_godspeed': 
						if(Paths.formatToSongPath(SONG.song) == 'godspeed' && !usedPractice && god) {
							unlock = true;
						}
					case 'opponent_mode': 
						if(!usedPractice && ClientPrefs.getGameplaySetting('opponentplay', false)) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	var curLight:Int = -1;
	var curLightEvent:Int = -1;
}
enum ExploitationModchartType
{
	None; Cheating; Figure8; ScrambledNotes; Cyclone; Unfairness; Jitterwave; PingPong; Sex;
}

enum CharacterFunnyEffect
{
	None; Dave; Bambi; Tristan; Exbungo; Recurser; Shaggy;
}

class Underlay extends FlxSprite
{
	var strumGroup:FlxTypedGroup<StrumNote>;
	public var isPlayer:Bool = false;
	override public function new(strumGroup:FlxTypedGroup<StrumNote>)
	{
		super(0,-1000);
		this.strumGroup = strumGroup;
		makeGraphic(1,3000, FlxColor.BLACK);
		this.scrollFactor.set();
		this.cameras = [PlayState.instance.camHUD];
	}
	override function update(elapsed:Float)
	{
		
		this.x = strumGroup.members[0].x;
		this.alpha = ClientPrefs.underlayAlpha;
		this.visible = true;

		if (strumGroup.members[0].alpha == 0 || !strumGroup.members[0].visible)
			this.visible = false;



		if (this.visible)
		{
			for (i in 0...strumGroup.members.length)
			{
				if (strumGroup.members[i].curID == Note.keyAmmo[strumGroup.members[i].curMania]-1)
				{
					
					this.width = (strumGroup.members[i].get_inWorldX() + (strumGroup.members[i].get_inWorldScaleX()*160)) - strumGroup.members[0].get_inWorldX();
					setGraphicSize(Std.int(width), 3000);
					updateHitbox();
					//break;
				}
			}
		}
		if (width < 50)
			this.visible = false;


		
		super.update(elapsed);
	}
}
