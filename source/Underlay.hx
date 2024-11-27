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

class Underlay extends FlxSprite
{
	var strumGroup:FlxTypedGroup<StrumNote>;
        var isPlayer:Bool = false;
	function new(strumGroup:FlxTypedGroup<StrumNote>)
	{
		super(0,-1000);
		this.strumGroup = strumGroup;
		makeGraphic(1,3000, FlxColor.BLACK);
		this.scrollFactor.set();
		this.cameras = [PlayState.instance.camHUD];
	}
	 function update(elapsed:Float)
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
