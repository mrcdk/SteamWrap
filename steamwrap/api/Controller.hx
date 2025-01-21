package steamwrap.api;

import cpp.Lib;
import haxe.Int32;
import steamwrap.helpers.Loader;
import steamwrap.helpers.MacroHelper;

/**
 * The Steam Controller API. Used by API.hx, should never be created manually by the user.
 * API.hx creates and initializes this by default.
 * Access it via API.controller static variable
 */
@:allow(steamwrap.api.Steam)
class Controller {
	/**
	 * The maximum number of controllers steam can recognize. Use this for array upper bounds.
	 */
	public var MAX_CONTROLLERS(get, null):Int;

	/**
	 * The maximum number of analog actions steam can recognize. Use this for array upper bounds.
	 */
	public var MAX_ANALOG_ACTIONS(get, null):Int;

	/**
	 * The maximum number of digital actions steam can recognize. Use this for array upper bounds.
	 */
	public var MAX_DIGITAL_ACTIONS(get, null):Int;

	/**
	 * The maximum number of origins steam can assign to one action. Use this for array upper bounds.
	 */
	public var MAX_ORIGINS(get, null):Int;

	/**
	 * The maximum value steam will report for an analog action.
	 */
	public var MAX_ANALOG_VALUE(get, null):Float;

	/**
	 * The minimum value steam will report for an analog action.
	 */
	public var MIN_ANALOG_VALUE(get, null):Float;

	public static inline var MAX_SINGLE_PULSE_TIME:Int = 65535;

	/*************PUBLIC***************/
	/**
	 * Whether the controller API is initialized or not. If false, all calls will fail.
	 */
	public var active(default, null):Bool = false;

	/**
	 * Reconfigure the controller to use the specified action set (ie 'Menu', 'Walk' or 'Drive')
	 * This is cheap, and can be safely called repeatedly. It's often easier to repeatedly call it in
	 * your state loops, instead of trying to place it in all of your state transitions.
	 * 
	 * @param	controller	handle received from getConnectedControllers()
	 * @param	actionSet	handle received from getActionSetHandle()
	 * @return	1 = success, 0 = failure
	 */
	public function activateActionSet(controller:Int, actionSet:Int):Int {
		if (!active)
			return 0;
		return SteamWrap_ActivateActionSet.call(controller, actionSet);
	}

	/**
	 * Get the handle of the current action set
	 * 
	 * @param	controller	handle received from getConnectedControllers()
	 * @return	handle of the current action set
	 */
	public function getCurrentActionSet(controller:Int):Int {
		if (!active)
			return -1;
		return SteamWrap_GetCurrentActionSet.call(controller);
	}

	/**
	 * Lookup the handle for an Action Set. Best to do this once on startup, and store the handles for all future API calls.
	 * 
	 * @param	name identifier for the action set specified in your vdf file (ie, 'Menu', 'Walk' or 'Drive')
	 * @return	action set handle
	 */
	public function getActionSetHandle(name:String):Int {
		if (!active)
			return -1;
		return SteamWrap_GetActionSetHandle.call(name);
	}

	/**
	 * Returns the current state of the supplied analog game action
	 * 
	 * @param	controller	handle received from getConnectedControllers()
	 * @param	action	handle received from getActionSetHandle()
	 * @param	data	existing ControllerAnalogActionData structure you want to fill (optional) 
	 * @return	data structure containing analog x,y values & other data
	 */
	public function getAnalogActionData(controller:Int, action:Int, ?data:ControllerAnalogActionData):ControllerAnalogActionData {
		if (data == null) {
			data = new ControllerAnalogActionData();
		}

		if (!active)
			return data;

		data.bActive = SteamWrap_GetAnalogActionData.call(controller, action);
		data.eMode = cast SteamWrap_GetAnalogActionData_eMode.call(0);
		data.x = SteamWrap_GetAnalogActionData_x.call(0);
		data.y = SteamWrap_GetAnalogActionData_y.call(0);

		return data;
	}

	/**
	 * Lookup the handle for an analog (continuos range) action. Best to do this once on startup, and store the handles for all future API calls.
	 * 
	 * @param	name	identifier for the action specified in your vdf file (ie, 'Jump', 'Fire', or 'Move')
	 * @return	action analog action handle
	 */
	public function getAnalogActionHandle(name:String):Int {
		if (!active)
			return -1;
		return SteamWrap_GetAnalogActionHandle.call(name);
	}

	/**
	 * Get the origin(s) for an analog action with an action set. Use this to display the appropriate on-screen prompt for the action.
	 * NOTE: Users can change their action origins at any time, and Valve says this is a cheap call and recommends you poll it continuosly
	 * to update your on-screen glyph visuals, rather than calling it rarely and caching the values.
	 * 
	 * @param	controller	handle received from getConnectedControllers()
	 * @param	actionSet	handle received from getActionSetHandle()
	 * @param	action	handle received from getAnalogActionHandle()
	 * @param	originsOut	existing array of EInputActionOrigins you want to fill (optional)
	 * @return the number of origins supplied in originsOut.
	 */
	public function getAnalogActionOrigins(controller:Int, actionSet:Int, action:Int, ?originsOut:Array<EInputActionOrigin>):Int {
		if (!active)
			return -1;
		var str:String = SteamWrap_GetAnalogActionOrigins(controller, actionSet, action);
		var strArr:Array<String> = str.split(",");

		var result = 0;

		// result is the first value in the array
		if (strArr != null && strArr.length > 0) {
			result = Std.parseInt(strArr[0]);
		}

		if (strArr.length > 1 && originsOut != null) {
			for (i in 1...strArr.length) {
				originsOut[i] = strArr[i];
			}
		}

		return result;
	}

	/**
	 * Enumerate currently connected controllers
	 * 
	 * NOTE: the native steam controller handles are uint64's and too large to easily pass to Haxe,
	 * so the "true" values are left on the C++ side and haxe only deals with 0-based integer indeces
	 * that map back to the "true" values on the C++ side
	 * 
	 * @return controller handles
	 */
	public function getConnectedControllers():Array<Int> {
		if (!active)
			return [];
		var str:String = SteamWrap_GetConnectedControllers();
		var arrStr:Array<String> = str.split(",");
		var intArr = [];
		for (astr in arrStr) {
			if (astr != "") {
				intArr.push(Std.parseInt(astr));
			}
		}
		return intArr;
	}

	/**
	 * Returns the current state of the supplied digital game action
	 * 
	 * @param	controller	handle received from getConnectedControllers()
	 * @param	action	handle received from getDigitalActionHandle()
	 * @return
	 */
	public function getDigitalActionData(controller:Int, action:Int):ControllerDigitalActionData {
		if (!active)
			return new ControllerDigitalActionData(0);
		return new ControllerDigitalActionData(SteamWrap_GetDigitalActionData.call(controller, action));
	}

	/**
	 * Lookup the handle for a digital (true/false) action. Best to do this once on startup, and store the handles for all future API calls.
	 * 
	 * @param	name	identifier for the action specified in your vdf file (ie, 'Jump', 'Fire', or 'Move')
	 * @return	digital action handle
	 */
	public function getDigitalActionHandle(name:String):Int {
		if (!active)
			return -1;
		return SteamWrap_GetDigitalActionHandle.call(name);
	}

	/**
	 * Get the origin(s) for a digital action with an action set. Use this to display the appropriate on-screen prompt for the action.
	 * 
	 * @param	controller	handle received from getConnectedControllers()
	 * @param	actionSet	handle received from getActionSetHandle()
	 * @param	action	handle received from getDigitalActionHandle()
	 * @param	originsOut	existing array of EInputActionOrigin you want to fill (optional)
	 * @return the number of origins supplied in originsOut.
	 */
	public function getDigitalActionOrigins(controller:Int, actionSet:Int, action:Int, ?originsOut:Array<EInputActionOrigin>):Int {
		if (!active)
			return 0;
		var str:String = SteamWrap_GetDigitalActionOrigins(controller, actionSet, action);
		var strArr:Array<String> = str.split(",");

		var result = 0;

		// result is the first value in the array
		if (strArr != null && strArr.length > 0) {
			result = Std.parseInt(strArr[0]);
		}

		// rest of the values are the actual origins
		if (strArr.length > 1 && originsOut != null) {
			for (i in 1...strArr.length) {
				originsOut[i] = strArr[i];
			}
		}

		return result;
	}

	/**
	 * Get a local path to art for on-screen glyph for a particular origin
	 * @param	origin
	 * @param	size
	 * @param	flags
	 * @return
	 */
	public function getGlyphPNGForActionOrigin(origin:EInputActionOrigin, size:ESteamInputGlyphSize, flags:Int):String {
		return SteamWrap_GetGlyphPNGForActionOrigin(origin, size, flags);
	}

	/**
	 * Get a local path to art for on-screen glyph for a particular origin
	 * @param	origin
	 * @param	flags
	 * @return
	 */
	public function getGlyphSVGForActionOrigin(origin:EInputActionOrigin, flags:Int):String {
		return SteamWrap_GetGlyphSVGForActionOrigin(origin, flags);
	}

	/**
	 * Get a local path to art for on-screen glyph for a particular origin
	 * @param	origin
	 * @return
	 */
	public function getGlyphForActionOrigin_Legacy(origin:EInputActionOrigin):String {
		return SteamWrap_GetGlyphForActionOrigin_Legacy(origin);
	}

	/**
	 * Returns a localized string (from Steam's language setting) for the specified origin
	 * @param	origin
	 * @return
	 */
	public function getStringForActionOrigin(origin:EInputActionOrigin):String {
		return SteamWrap_GetStringForActionOrigin(origin);
	}

	/**
	 * Returns a localized string (from Steam's language setting) for the user-facing action name corresponding to the specified handle
	 * @param	actionHandle
	 * @return
	 */
	public function getStringForAnalogActionName(actionHandle:Int):String {
		return SteamWrap_GetStringForAnalogActionName(actionHandle);
	}
	

	/**
	 * Activates the Steam overlay and shows the input configuration (binding) screen
	 * @return false if overlay is disabled / unavailable, or if the Steam client is not in Big Picture mode
	 */
	public function showBindingPanel(controller:Int):Bool {
		var result:Bool = SteamWrap_ShowBindingPanel(controller);
		return result;
	}

	/**
	 * Activates the Big Picture text input dialog which only supports gamepad input
	 * @param	inputMode	NORMAL or PASSWORD
	 * @param	lineMode	SINGLE_LINE or MULTIPLE_LINES
	 * @param	description	User-facing description of what's being entered, e.g. "Please enter your name"
	 * @param	charMax	Maximum number of characters
	 * @param	existingText	Text to pre-fill the dialog with, if any
	 * @return
	 */
	public function showGamepadTextInput(inputMode:EGamepadTextInputMode, lineMode:EGamepadTextInputLineMode, description:String, charMax:Int = 0xFFFFFF,
			existingText:String = ""):Bool {
		return (1 == SteamWrap_ShowGamepadTextInput.call(cast inputMode, cast lineMode, description, charMax, existingText));
	}

	/**
	 * Returns the text that the player has entered using showGamepadTextInput()
	 * @return
	 */
	public function getEnteredGamepadTextInput():String {
		return SteamWrap_GetEnteredGamepadTextInput();
	}

	/**
	 * Must be called when ending use of this API
	 */
	public function shutdown() {
		SteamWrap_ShutdownControllers();
		active = false;
	}

	/**
	 * Trigger a haptic pulse in a slightly friendlier way
	 * @param	controller	handle received from getConnectedControllers()
	 * @param	targetPad	which pad you want to pulse
	 * @param	durationMilliSec	duration of the pulse, in milliseconds (1/1000 sec)
	 * @param	strength	value between 0 and 1, general intensity of the pulsing
	 */
	public function hapticPulseRumble(controller:Int, targetPad:ESteamControllerPad, durationMilliSec:Int, strength:Float) {
		if (strength <= 0)
			return;
		if (strength > 1)
			strength = 1;

		var durationMicroSec = durationMilliSec * 1000;
		var repeat = 1;

		if (durationMicroSec > MAX_SINGLE_PULSE_TIME) {
			repeat = Math.ceil(durationMicroSec / MAX_SINGLE_PULSE_TIME);
			durationMicroSec = MAX_SINGLE_PULSE_TIME;
		}

		var onTime = Std.int(durationMicroSec * strength);
		var offTime = Std.int(durationMicroSec * (1 - strength));

		if (offTime <= 0)
			offTime = 1;

		if (repeat > 1) {
			triggerRepeatedHapticPulse(controller, targetPad, onTime, offTime, repeat, 0);
		} else {
			triggerHapticPulse(controller, targetPad, onTime);
		}
	}

	/**
	 * Trigger a single haptic pulse (low-level)
	 * @param	controller	handle received from getConnectedControllers()
	 * @param	targetPad	which pad you want to pulse
	 * @param	durationMicroSec	duration of the pulse, in microseconds (1/1000 ms)
	 */
	public function triggerHapticPulse(controller:Int, targetPad:ESteamControllerPad, durationMicroSec:Int) {
		if (durationMicroSec < 0)
			durationMicroSec = 0;
		else if (durationMicroSec > MAX_SINGLE_PULSE_TIME)
			durationMicroSec = MAX_SINGLE_PULSE_TIME;

		switch (targetPad) {
			case LEFT, RIGHT:
				SteamWrap_TriggerHapticPulse.call(controller, cast targetPad, durationMicroSec);
			case BOTH:
				triggerHapticPulse(controller, LEFT, durationMicroSec);
				triggerHapticPulse(controller, RIGHT, durationMicroSec);
		}
	}

	/**
	 * Trigger a repeated haptic pulse (low-level)
	 * @param	controller	handle received from getConnectedControllers()
	 * @param	targetPad	which pad you want to pulse
	 * @param	durationMicroSec	duration of the pulse, in microseconds (1/1,000 ms)
	 * @param	offMicroSec	offset between pulses, in microseconds (1/1,000 ms)
	 * @param	repeat	number of pulses
	 * @param	flags	special behavior flags
	 */
	public function triggerRepeatedHapticPulse(controller:Int, targetPad:ESteamControllerPad, durationMicroSec:Int, offMicroSec:Int, repeat:Int, flags:Int) {
		if (durationMicroSec < 0)
			durationMicroSec = 0;
		else if (durationMicroSec > MAX_SINGLE_PULSE_TIME)
			durationMicroSec = MAX_SINGLE_PULSE_TIME;

		switch (targetPad) {
			case LEFT, RIGHT:
				SteamWrap_TriggerRepeatedHapticPulse.call(controller, cast targetPad, durationMicroSec, offMicroSec, repeat, flags);
			case BOTH:
				triggerRepeatedHapticPulse(controller, LEFT, durationMicroSec, offMicroSec, repeat, flags);
				triggerRepeatedHapticPulse(controller, RIGHT, durationMicroSec, offMicroSec, repeat, flags);
		}
	}

	/**
	 * Trigger a vibration event on supported controllers
	 * @param	controller	handle received from getConnectedControllers()
	 * @param	leftSpeed	how fast the left motor should vibrate (0-65,535)
	 * @param	rightSpeed	how fast the right motor should vibrate (0-65,535)
	 */
	public function triggerVibration(controller:Int, leftSpeed:Int, rightSpeed:Int) {
		if (leftSpeed < 0)
			leftSpeed = 0;
		if (leftSpeed > 65535)
			leftSpeed = 65535;
		if (rightSpeed < 0)
			rightSpeed = 0;
		if (rightSpeed > 65535)
			rightSpeed = 65535;
		SteamWrap_TriggerVibration.call(controller, leftSpeed, rightSpeed);
	}

	/**
	 * Set the controller LED color on supported controllers. 
	 * @param	controller	handle received from getConnectedControllers()
	 * @param	rgb	an RGB color in 0xRRGGBB format
	 * @param	flags	bit-masked flags combined from values defined in ESteamInputLEDFlags
	 */
	public function setLEDColor(controller:Int, rgb:Int, flags:Int = ESteamInputLEDFlags.SET_COLOR) {
		var r = (rgb >> 16) & 0xFF;
		var g = (rgb >> 8) & 0xFF;
		var b = rgb & 0xFF;
		SteamWrap_SetLEDColor.call(controller, r, g, b, flags);
	}

	public function resetLEDColor(controller:Int) {
		SteamWrap_SetLEDColor.call(controller, 0, 0, 0, ESteamInputLEDFlags.RESTORE_USER_DEFAULT);
	}

	public function getGamepadIndexForController(controller:Int):Int {
		return SteamWrap_GetGamepadIndexForController.call(controller);
	}

	public function getControllerForGamepadIndex(index:Int):Int {
		return SteamWrap_GetControllerForGamepadIndex.call(index);
	}

	public function getInputTypeForHandle(controller:Int):ESteamInputType {
		return cast SteamWrap_GetInputTypeForHandle.call(controller);
	}

	/**
	 * Returns the current state of the supplied analog game action
	 * 
	 * @param	controller	handle received from getConnectedControllers()
	 * @param	data	existing ControllerMotionData structure you want to fill (optional) 
	 * @return	data structure containing motion data values
	 */
	public function getMotionData(controller:Int, ?data:ControllerMotionData):ControllerMotionData {
		if (data == null) {
			data = new ControllerMotionData();
		}

		if (!active)
			return data;

		SteamWrap_GetMotionData.call(controller);

		data.posAccelX = SteamWrap_GetMotionData_posAccelX.call(0);
		data.posAccelY = SteamWrap_GetMotionData_posAccelY.call(0);
		data.posAccelZ = SteamWrap_GetMotionData_posAccelZ.call(0);
		data.rotQuatX = SteamWrap_GetMotionData_rotQuatX.call(0);
		data.rotQuatY = SteamWrap_GetMotionData_rotQuatY.call(0);
		data.rotQuatZ = SteamWrap_GetMotionData_rotQuatZ.call(0);
		data.rotQuatW = SteamWrap_GetMotionData_rotQuatW.call(0);
		data.rotVelX = SteamWrap_GetMotionData_rotVelX.call(0);
		data.rotVelY = SteamWrap_GetMotionData_rotVelY.call(0);
		data.rotVelZ = SteamWrap_GetMotionData_rotVelZ.call(0);

		return data;
	}

	/**
	 * Attempt to display origins of given action in the controller HUD, for the currently active action set
	 * Returns false is overlay is disabled / unavailable, or the user is not in Big Picture mode
	 * @param	controller	handle received from getConnectedControllers()
	 * @param	digitalActionHandle	handle received from getDigitalActionHandle()
	 * @param	scale	scale multiplier to apply to the on-screen display (1.0 is 1:1 size)
	 * @param	xPosition	position of the on-screen display (0.5 is the center)
	 * @param	yPosition	position of the on-screen display (0.5 is the center)
	 */
	public function showDigitalActionOrigins(controller:Int, digitalActionHandle:Int, scale:Float, xPosition:Float, yPosition:Float) {
		SteamWrap_ShowDigitalActionOrigins.call(controller, digitalActionHandle, scale, xPosition, yPosition);
	}

	/**
	 * Attempt to display origins of given action in the controller HUD, for the currently active action set
	 * Returns false is overlay is disabled / unavailable, or the user is not in Big Picture mode
	 * @param	controller	handle received from getConnectedControllers()
	 * @param	analogActionHandle	handle received from getDigitalActionHandle()
	 * @param	scale	scale multiplier to apply to the on-screen display (1.0 is 1:1 size)
	 * @param	xPosition	position of the on-screen display (0.5 is the center)
	 * @param	yPosition	position of the on-screen display (0.5 is the center)
	 */
	public function showAnalogActionOrigins(controller:Int, analogActionHandle:Int, scale:Float, xPosition:Float, yPosition:Float) {
		SteamWrap_ShowAnalogActionOrigins.call(controller, analogActionHandle, scale, xPosition, yPosition);
	}

	/*************PRIVATE***************/
	private var appId:Int;
	private var customTrace:String->Void;

	// Old-school CFFI calls:
	private var SteamWrap_InitControllers:Dynamic;
	private var SteamWrap_ShutdownControllers:Dynamic;
	private var SteamWrap_GetConnectedControllers:Dynamic;
	private var SteamWrap_GetDigitalActionOrigins:Dynamic;
	private var SteamWrap_GetEnteredGamepadTextInput:Dynamic;
	private var SteamWrap_GetAnalogActionOrigins:Dynamic;
	private var SteamWrap_ShowBindingPanel:Dynamic;
	private var SteamWrap_GetStringForActionOrigin:Dynamic;
	private var SteamWrap_GetGlyphPNGForActionOrigin:Dynamic;
	private var SteamWrap_GetGlyphSVGForActionOrigin:Dynamic;
	private var SteamWrap_GetGlyphForActionOrigin_Legacy:Dynamic;
	private var SteamWrap_GetStringForAnalogActionName:Dynamic;

	private static var SteamWrap_GetControllerMaxCount:Dynamic;
	private static var SteamWrap_GetControllerMaxAnalogActions:Dynamic;
	private static var SteamWrap_GetControllerMaxDigitalActions:Dynamic;
	private static var SteamWrap_GetControllerMaxOrigins:Dynamic;
	private static var SteamWrap_GetControllerMaxAnalogActionData:Dynamic;
	private static var SteamWrap_GetControllerMinAnalogActionData:Dynamic;

	// CFFI PRIME calls
	private var SteamWrap_ActivateActionSet = Loader.load("SteamWrap_ActivateActionSet", "iii");
	private var SteamWrap_GetCurrentActionSet = Loader.load("SteamWrap_GetCurrentActionSet", "ii");
	private var SteamWrap_GetActionSetHandle = Loader.load("SteamWrap_GetActionSetHandle", "ci");
	private var SteamWrap_GetAnalogActionData = Loader.load("SteamWrap_GetAnalogActionData", "iii");
	private var SteamWrap_GetAnalogActionHandle = Loader.load("SteamWrap_GetAnalogActionHandle", "ci");
	private var SteamWrap_GetDigitalActionData = Loader.load("SteamWrap_GetDigitalActionData", "iii");
	private var SteamWrap_GetAnalogActionData_eMode = Loader.load("SteamWrap_GetAnalogActionData_eMode", "ii");
	private var SteamWrap_GetAnalogActionData_x = Loader.load("SteamWrap_GetAnalogActionData_x", "if");
	private var SteamWrap_GetAnalogActionData_y = Loader.load("SteamWrap_GetAnalogActionData_y", "if");
	private var SteamWrap_GetDigitalActionHandle = Loader.load("SteamWrap_GetDigitalActionHandle", "ci");
	private var SteamWrap_ShowGamepadTextInput = Loader.load("SteamWrap_ShowGamepadTextInput", "iicici");
	private var SteamWrap_TriggerHapticPulse = Loader.load("SteamWrap_TriggerHapticPulse", "iiiv");
	private var SteamWrap_TriggerRepeatedHapticPulse = Loader.load("SteamWrap_TriggerRepeatedHapticPulse", "iiiiiiv");
	private var SteamWrap_TriggerVibration = Loader.load("SteamWrap_TriggerVibration", "iiiv");
	private var SteamWrap_SetLEDColor = Loader.load("SteamWrap_SetLEDColor", "iiiiiv");
	private var SteamWrap_GetMotionData = Loader.load("SteamWrap_GetMotionData", "iv");
	private var SteamWrap_GetMotionData_rotQuatX = Loader.load("SteamWrap_GetMotionData_rotQuatX", "ii");
	private var SteamWrap_GetMotionData_rotQuatY = Loader.load("SteamWrap_GetMotionData_rotQuatY", "ii");
	private var SteamWrap_GetMotionData_rotQuatZ = Loader.load("SteamWrap_GetMotionData_rotQuatZ", "ii");
	private var SteamWrap_GetMotionData_rotQuatW = Loader.load("SteamWrap_GetMotionData_rotQuatW", "ii");
	private var SteamWrap_GetMotionData_posAccelX = Loader.load("SteamWrap_GetMotionData_posAccelX", "ii");
	private var SteamWrap_GetMotionData_posAccelY = Loader.load("SteamWrap_GetMotionData_posAccelY", "ii");
	private var SteamWrap_GetMotionData_posAccelZ = Loader.load("SteamWrap_GetMotionData_posAccelZ", "ii");
	private var SteamWrap_GetMotionData_rotVelX = Loader.load("SteamWrap_GetMotionData_rotVelX", "ii");
	private var SteamWrap_GetMotionData_rotVelY = Loader.load("SteamWrap_GetMotionData_rotVelY", "ii");
	private var SteamWrap_GetMotionData_rotVelZ = Loader.load("SteamWrap_GetMotionData_rotVelZ", "ii");
	private var SteamWrap_ShowDigitalActionOrigins = Loader.load("SteamWrap_ShowDigitalActionOrigins", "iifffi");
	private var SteamWrap_ShowAnalogActionOrigins = Loader.load("SteamWrap_ShowAnalogActionOrigins", "iifffi");
	private var SteamWrap_GetGamepadIndexForController = Loader.load("SteamWrap_GetGamepadIndexForController", "ii");
	private var SteamWrap_GetControllerForGamepadIndex = Loader.load("SteamWrap_GetControllerForGamepadIndex", "ii");
	private var SteamWrap_GetInputTypeForHandle = Loader.load("SteamWrap_GetInputTypeForHandle", "ii");

	private function new(appId_:Int, CustomTrace:String->Void, enableCallbacks:Bool) {
		appId = appId_;
		customTrace = CustomTrace;
		init(enableCallbacks);
	}

	private function init(enableCallbacks:Bool = false) {
		#if sys // TODO: figure out what targets this will & won't work with and upate this guard

		if (active)
			return;

		try {
			// Old-school CFFI calls:
			SteamWrap_GetConnectedControllers = cpp.Lib.load("steamwrap", "SteamWrap_GetConnectedControllers", 0);
			SteamWrap_GetDigitalActionOrigins = cpp.Lib.load("steamwrap", "SteamWrap_GetDigitalActionOrigins", 3);
			SteamWrap_GetEnteredGamepadTextInput = cpp.Lib.load("steamwrap", "SteamWrap_GetEnteredGamepadTextInput", 0);
			SteamWrap_GetAnalogActionOrigins = cpp.Lib.load("steamwrap", "SteamWrap_GetAnalogActionOrigins", 3);
			SteamWrap_InitControllers = cpp.Lib.load("steamwrap", "SteamWrap_InitControllers", 2);
			SteamWrap_ShowBindingPanel = cpp.Lib.load("steamwrap", "SteamWrap_ShowBindingPanel", 1);
			SteamWrap_GetGlyphPNGForActionOrigin = cpp.Lib.load("steamwrap", "SteamWrap_GetGlyphPNGForActionOrigin", 3);
			SteamWrap_GetGlyphSVGForActionOrigin = cpp.Lib.load("steamwrap", "SteamWrap_GetGlyphSVGForActionOrigin", 2);
			SteamWrap_GetGlyphForActionOrigin_Legacy = cpp.Lib.load("steamwrap", "SteamWrap_GetGlyphForActionOrigin_Legacy", 1);
			SteamWrap_GetStringForActionOrigin = cpp.Lib.load("steamwrap", "SteamWrap_GetStringForActionOrigin", 1);
			SteamWrap_GetStringForAnalogActionName = cpp.Lib.load("steamwrap", "SteamWrap_GetStringForAnalogActionName", 1);
			SteamWrap_ShutdownControllers = cpp.Lib.load("steamwrap", "SteamWrap_ShutdownControllers", 0);

			SteamWrap_GetControllerMaxCount = cpp.Lib.load("steamwrap", "SteamWrap_GetControllerMaxCount", 0);
			SteamWrap_GetControllerMaxAnalogActions = cpp.Lib.load("steamwrap", "SteamWrap_GetControllerMaxAnalogActions", 0);
			SteamWrap_GetControllerMaxDigitalActions = cpp.Lib.load("steamwrap", "SteamWrap_GetControllerMaxDigitalActions", 0);
			SteamWrap_GetControllerMaxOrigins = cpp.Lib.load("steamwrap", "SteamWrap_GetControllerMaxOrigins", 0);
			SteamWrap_GetControllerMaxAnalogActionData = cpp.Lib.load("steamwrap", "SteamWrap_GetControllerMaxAnalogActionData", 0);
			SteamWrap_GetControllerMinAnalogActionData = cpp.Lib.load("steamwrap", "SteamWrap_GetControllerMinAnalogActionData", 0);
		} catch (e:Dynamic) {
			customTrace("Running non-Steam version (" + e + ")");
			return;
		}

		// if we get this far, the dlls loaded ok and we need Steam controllers to init.
		// otherwise, we're trying to run the Steam version without the Steam client
		active = SteamWrap_InitControllers(false, enableCallbacks);
		#end
	}

	private var max_controllers:Int = -1;

	private function get_MAX_CONTROLLERS():Int {
		if (max_controllers == -1)
			max_controllers = SteamWrap_GetControllerMaxCount();
		return max_controllers;
	}

	private var max_analog_actions = -1;

	private function get_MAX_ANALOG_ACTIONS():Int {
		if (max_analog_actions == -1)
			max_analog_actions = SteamWrap_GetControllerMaxAnalogActions();
		return max_analog_actions;
	}

	private var max_digital_actions = -1;

	private function get_MAX_DIGITAL_ACTIONS():Int {
		if (max_digital_actions == -1)
			max_digital_actions = SteamWrap_GetControllerMaxDigitalActions();
		return max_digital_actions;
	}

	private var max_origins = -1;

	private function get_MAX_ORIGINS():Int {
		if (max_origins == -1)
			max_origins = SteamWrap_GetControllerMaxOrigins();
		return max_origins;
	}

	private var max_analog_value = -1;

	private function get_MAX_ANALOG_VALUE():Float {
		if (max_analog_value == -1)
			max_analog_value = SteamWrap_GetControllerMaxAnalogActionData();
		return max_analog_value;
	}

	private var min_analog_value = -1;

	private function get_MIN_ANALOG_VALUE():Float {
		if (min_analog_value == -1)
			min_analog_value = SteamWrap_GetControllerMinAnalogActionData();
		return min_analog_value;
	}
}

abstract ControllerDigitalActionData(Int) from Int to Int {
	public function new(i:Int) {
		this = i;
	}

	public var bState(get, never):Bool;

	private function get_bState():Bool {
		return this & 0x1 == 0x1;
	}

	public var bActive(get, never):Bool;

	private function get_bActive():Bool {
		return this & 0x10 == 0x10;
	}
}

class ControllerAnalogActionData {
	public var eMode:EControllerSourceMode = NONE;
	public var x:Float = 0.0;
	public var y:Float = 0.0;
	public var bActive:Int = 0;

	public function new() {}
}

class ControllerMotionData {
	// Sensor-fused absolute rotation; will drift in heading
	public var rotQuatX:Float = 0.0;
	public var rotQuatY:Float = 0.0;
	public var rotQuatZ:Float = 0.0;
	public var rotQuatW:Float = 0.0;

	// Positional acceleration
	public var posAccelX:Float = 0.0;
	public var posAccelY:Float = 0.0;
	public var posAccelZ:Float = 0.0;

	// Angular velocity
	public var rotVelX:Float = 0.0;
	public var rotVelY:Float = 0.0;
	public var rotVelZ:Float = 0.0;

	public function new() {}

	public function toString():String {
		return "ControllerMotionData{rotQuad:(" + rotQuatX + "," + rotQuatY + "," + rotQuatZ + "," + rotQuatW + "), " + "posAccel:(" + posAccelX + ","
			+ posAccelY + "," + posAccelZ + "), " + "rotVel:(" + rotVelX + "," + rotVelY + "," + rotVelZ + ")}";
	}
}

class ESteamInputLEDFlags {
	public static inline var SET_COLOR = 0x00;
	public static inline var RESTORE_USER_DEFAULT = 0x01;
}

class ESteamInputGlyphSize {
	public static inline var SMALL = 0;
	public static inline var MEDIUM = 1;
	public static inline var LARGE = 2;
	public static inline var COUNT = 3;
}

enum abstract EInputSourceMode(Int) {
	var None = 0;
	var Dpad;
	var Buttons;
	var FourButtons;
	var AbsoluteMouse;
	var RelativeMouse;
	var JoystickMove;
	var JoystickMouse;
	var JoystickCamera;
	var ScrollWheel;
	var Trigger;
	var TouchMenu;
	var MouseJoystick;
	var MouseRegion;
	var RadialMenu;
	var SingleButton;
	var Switches;
}

enum abstract EInputActionOrigin(Int) {
	public static var fromStringMap(default, null):Map<String, EInputActionOrigin> = MacroHelper.buildMap("steamwrap.api.EInputActionOrigin");

	public static var toStringMap(default, null):Map<EInputActionOrigin, String> = MacroHelper.buildMap("steamwrap.api.EInputActionOrigin", true);

	var None = 0;

	// Steam Controller
	var SteamController_A;
	var SteamController_B;
	var SteamController_X;
	var SteamController_Y;
	var SteamController_LeftBumper;
	var SteamController_RightBumper;
	var SteamController_LeftGrip;
	var SteamController_RightGrip;
	var SteamController_Start;
	var SteamController_Back;
	var SteamController_LeftPad_Touch;
	var SteamController_LeftPad_Swipe;
	var SteamController_LeftPad_Click;
	var SteamController_LeftPad_DPadNorth;
	var SteamController_LeftPad_DPadSouth;
	var SteamController_LeftPad_DPadWest;
	var SteamController_LeftPad_DPadEast;
	var SteamController_RightPad_Touch;
	var SteamController_RightPad_Swipe;
	var SteamController_RightPad_Click;
	var SteamController_RightPad_DPadNorth;
	var SteamController_RightPad_DPadSouth;
	var SteamController_RightPad_DPadWest;
	var SteamController_RightPad_DPadEast;
	var SteamController_LeftTrigger_Pull;
	var SteamController_LeftTrigger_Click;
	var SteamController_RightTrigger_Pull;
	var SteamController_RightTrigger_Click;
	var SteamController_LeftStick_Move;
	var SteamController_LeftStick_Click;
	var SteamController_LeftStick_DPadNorth;
	var SteamController_LeftStick_DPadSouth;
	var SteamController_LeftStick_DPadWest;
	var SteamController_LeftStick_DPadEast;
	var SteamController_Gyro_Move;
	var SteamController_Gyro_Pitch;
	var SteamController_Gyro_Yaw;
	var SteamController_Gyro_Roll;
	var SteamController_Reserved0;
	var SteamController_Reserved1;
	var SteamController_Reserved2;
	var SteamController_Reserved3;
	var SteamController_Reserved4;
	var SteamController_Reserved5;
	var SteamController_Reserved6;
	var SteamController_Reserved7;
	var SteamController_Reserved8;
	var SteamController_Reserved9;
	var SteamController_Reserved10;
	
	// PS4 Dual Shock
	var PS4_X;
	var PS4_Circle;
	var PS4_Triangle;
	var PS4_Square;
	var PS4_LeftBumper;
	var PS4_RightBumper;
	var PS4_Options;	//Start
	var PS4_Share;		//Back
	var PS4_LeftPad_Touch;
	var PS4_LeftPad_Swipe;
	var PS4_LeftPad_Click;
	var PS4_LeftPad_DPadNorth;
	var PS4_LeftPad_DPadSouth;
	var PS4_LeftPad_DPadWest;
	var PS4_LeftPad_DPadEast;
	var PS4_RightPad_Touch;
	var PS4_RightPad_Swipe;
	var PS4_RightPad_Click;
	var PS4_RightPad_DPadNorth;
	var PS4_RightPad_DPadSouth;
	var PS4_RightPad_DPadWest;
	var PS4_RightPad_DPadEast;
	var PS4_CenterPad_Touch;
	var PS4_CenterPad_Swipe;
	var PS4_CenterPad_Click;
	var PS4_CenterPad_DPadNorth;
	var PS4_CenterPad_DPadSouth;
	var PS4_CenterPad_DPadWest;
	var PS4_CenterPad_DPadEast;
	var PS4_LeftTrigger_Pull;
	var PS4_LeftTrigger_Click;
	var PS4_RightTrigger_Pull;
	var PS4_RightTrigger_Click;
	var PS4_LeftStick_Move;
	var PS4_LeftStick_Click;
	var PS4_LeftStick_DPadNorth;
	var PS4_LeftStick_DPadSouth;
	var PS4_LeftStick_DPadWest;
	var PS4_LeftStick_DPadEast;
	var PS4_RightStick_Move;
	var PS4_RightStick_Click;
	var PS4_RightStick_DPadNorth;
	var PS4_RightStick_DPadSouth;
	var PS4_RightStick_DPadWest;
	var PS4_RightStick_DPadEast;
	var PS4_DPad_North;
	var PS4_DPad_South;
	var PS4_DPad_West;
	var PS4_DPad_East;
	var PS4_Gyro_Move;
	var PS4_Gyro_Pitch;
	var PS4_Gyro_Yaw;
	var PS4_Gyro_Roll;
	var PS4_DPad_Move;
	var PS4_Reserved1;
	var PS4_Reserved2;
	var PS4_Reserved3;
	var PS4_Reserved4;
	var PS4_Reserved5;
	var PS4_Reserved6;
	var PS4_Reserved7;
	var PS4_Reserved8;
	var PS4_Reserved9;
	var PS4_Reserved10;

	// XBox One
	var XBoxOne_A;
	var XBoxOne_B;
	var XBoxOne_X;
	var XBoxOne_Y;
	var XBoxOne_LeftBumper;
	var XBoxOne_RightBumper;
	var XBoxOne_Menu;  //Start
	var XBoxOne_View;  //Back
	var XBoxOne_LeftTrigger_Pull;
	var XBoxOne_LeftTrigger_Click;
	var XBoxOne_RightTrigger_Pull;
	var XBoxOne_RightTrigger_Click;
	var XBoxOne_LeftStick_Move;
	var XBoxOne_LeftStick_Click;
	var XBoxOne_LeftStick_DPadNorth;
	var XBoxOne_LeftStick_DPadSouth;
	var XBoxOne_LeftStick_DPadWest;
	var XBoxOne_LeftStick_DPadEast;
	var XBoxOne_RightStick_Move;
	var XBoxOne_RightStick_Click;
	var XBoxOne_RightStick_DPadNorth;
	var XBoxOne_RightStick_DPadSouth;
	var XBoxOne_RightStick_DPadWest;
	var XBoxOne_RightStick_DPadEast;
	var XBoxOne_DPad_North;
	var XBoxOne_DPad_South;
	var XBoxOne_DPad_West;
	var XBoxOne_DPad_East;
	var XBoxOne_DPad_Move;
	var XBoxOne_LeftGrip_Lower;
	var XBoxOne_LeftGrip_Upper;
	var XBoxOne_RightGrip_Lower;
	var XBoxOne_RightGrip_Upper;
	var XBoxOne_Share; // Xbox Series X controllers only
	var XBoxOne_Reserved6;
	var XBoxOne_Reserved7;
	var XBoxOne_Reserved8;
	var XBoxOne_Reserved9;
	var XBoxOne_Reserved10;

	// XBox 360
	var XBox360_A;
	var XBox360_B;
	var XBox360_X;
	var XBox360_Y;
	var XBox360_LeftBumper;
	var XBox360_RightBumper;
	var XBox360_Start;		//Start
	var XBox360_Back;		//Back
	var XBox360_LeftTrigger_Pull;
	var XBox360_LeftTrigger_Click;
	var XBox360_RightTrigger_Pull;
	var XBox360_RightTrigger_Click;
	var XBox360_LeftStick_Move;
	var XBox360_LeftStick_Click;
	var XBox360_LeftStick_DPadNorth;
	var XBox360_LeftStick_DPadSouth;
	var XBox360_LeftStick_DPadWest;
	var XBox360_LeftStick_DPadEast;
	var XBox360_RightStick_Move;
	var XBox360_RightStick_Click;
	var XBox360_RightStick_DPadNorth;
	var XBox360_RightStick_DPadSouth;
	var XBox360_RightStick_DPadWest;
	var XBox360_RightStick_DPadEast;
	var XBox360_DPad_North;
	var XBox360_DPad_South;
	var XBox360_DPad_West;
	var XBox360_DPad_East;	
	var XBox360_DPad_Move;
	var XBox360_Reserved1;
	var XBox360_Reserved2;
	var XBox360_Reserved3;
	var XBox360_Reserved4;
	var XBox360_Reserved5;
	var XBox360_Reserved6;
	var XBox360_Reserved7;
	var XBox360_Reserved8;
	var XBox360_Reserved9;
	var XBox360_Reserved10;


	// Switch - Pro or Joycons used as a single input device.
	// This does not apply to a single joycon
	var Switch_A;
	var Switch_B;
	var Switch_X;
	var Switch_Y;
	var Switch_LeftBumper;
	var Switch_RightBumper;
	var Switch_Plus;	//Start
	var Switch_Minus;	//Back
	var Switch_Capture;
	var Switch_LeftTrigger_Pull;
	var Switch_LeftTrigger_Click;
	var Switch_RightTrigger_Pull;
	var Switch_RightTrigger_Click;
	var Switch_LeftStick_Move;
	var Switch_LeftStick_Click;
	var Switch_LeftStick_DPadNorth;
	var Switch_LeftStick_DPadSouth;
	var Switch_LeftStick_DPadWest;
	var Switch_LeftStick_DPadEast;
	var Switch_RightStick_Move;
	var Switch_RightStick_Click;
	var Switch_RightStick_DPadNorth;
	var Switch_RightStick_DPadSouth;
	var Switch_RightStick_DPadWest;
	var Switch_RightStick_DPadEast;
	var Switch_DPad_North;
	var Switch_DPad_South;
	var Switch_DPad_West;
	var Switch_DPad_East;
	var Switch_ProGyro_Move;  // Primary Gyro in Pro Controller, or Right JoyCon
	var Switch_ProGyro_Pitch;  // Primary Gyro in Pro Controller, or Right JoyCon
	var Switch_ProGyro_Yaw;  // Primary Gyro in Pro Controller, or Right JoyCon
	var Switch_ProGyro_Roll;  // Primary Gyro in Pro Controller, or Right JoyCon
	var Switch_DPad_Move;
	var Switch_Reserved1;
	var Switch_Reserved2;
	var Switch_Reserved3;
	var Switch_Reserved4;
	var Switch_Reserved5;
	var Switch_Reserved6;
	var Switch_Reserved7;
	var Switch_Reserved8;
	var Switch_Reserved9;
	var Switch_Reserved10;

	// Switch JoyCon Specific
	var Switch_RightGyro_Move;  // Right JoyCon Gyro generally should correspond to Pro's single gyro
	var Switch_RightGyro_Pitch;  // Right JoyCon Gyro generally should correspond to Pro's single gyro
	var Switch_RightGyro_Yaw;  // Right JoyCon Gyro generally should correspond to Pro's single gyro
	var Switch_RightGyro_Roll;  // Right JoyCon Gyro generally should correspond to Pro's single gyro
	var Switch_LeftGyro_Move;
	var Switch_LeftGyro_Pitch;
	var Switch_LeftGyro_Yaw;
	var Switch_LeftGyro_Roll;
	var Switch_LeftGrip_Lower; // Left JoyCon SR Button
	var Switch_LeftGrip_Upper; // Left JoyCon SL Button
	var Switch_RightGrip_Lower;  // Right JoyCon SL Button
	var Switch_RightGrip_Upper;  // Right JoyCon SR Button
	var Switch_JoyConButton_N; // With a Horizontal JoyCon this will be Y or what would be Dpad Right when vertical
	var Switch_JoyConButton_E; // X
	var Switch_JoyConButton_S; // A
	var Switch_JoyConButton_W; // B
	var Switch_Reserved15;
	var Switch_Reserved16;
	var Switch_Reserved17;
	var Switch_Reserved18;
	var Switch_Reserved19;
	var Switch_Reserved20;
	
	// Added in SDK 1.51
	var PS5_X;
	var PS5_Circle;
	var PS5_Triangle;
	var PS5_Square;
	var PS5_LeftBumper;
	var PS5_RightBumper;
	var PS5_Option;	//Start
	var PS5_Create;		//Back
	var PS5_Mute;
	var PS5_LeftPad_Touch;
	var PS5_LeftPad_Swipe;
	var PS5_LeftPad_Click;
	var PS5_LeftPad_DPadNorth;
	var PS5_LeftPad_DPadSouth;
	var PS5_LeftPad_DPadWest;
	var PS5_LeftPad_DPadEast;
	var PS5_RightPad_Touch;
	var PS5_RightPad_Swipe;
	var PS5_RightPad_Click;
	var PS5_RightPad_DPadNorth;
	var PS5_RightPad_DPadSouth;
	var PS5_RightPad_DPadWest;
	var PS5_RightPad_DPadEast;
	var PS5_CenterPad_Touch;
	var PS5_CenterPad_Swipe;
	var PS5_CenterPad_Click;
	var PS5_CenterPad_DPadNorth;
	var PS5_CenterPad_DPadSouth;
	var PS5_CenterPad_DPadWest;
	var PS5_CenterPad_DPadEast;
	var PS5_LeftTrigger_Pull;
	var PS5_LeftTrigger_Click;
	var PS5_RightTrigger_Pull;
	var PS5_RightTrigger_Click;
	var PS5_LeftStick_Move;
	var PS5_LeftStick_Click;
	var PS5_LeftStick_DPadNorth;
	var PS5_LeftStick_DPadSouth;
	var PS5_LeftStick_DPadWest;
	var PS5_LeftStick_DPadEast;
	var PS5_RightStick_Move;
	var PS5_RightStick_Click;
	var PS5_RightStick_DPadNorth;
	var PS5_RightStick_DPadSouth;
	var PS5_RightStick_DPadWest;
	var PS5_RightStick_DPadEast;
	var PS5_DPad_North;
	var PS5_DPad_South;
	var PS5_DPad_West;
	var PS5_DPad_East;
	var PS5_Gyro_Move;
	var PS5_Gyro_Pitch;
	var PS5_Gyro_Yaw;
	var PS5_Gyro_Roll;
	var PS5_DPad_Move;
	var PS5_LeftGrip;
	var PS5_RightGrip;
	var PS5_LeftFn;
	var PS5_RightFn;
	var PS5_Reserved5;
	var PS5_Reserved6;
	var PS5_Reserved7;
	var PS5_Reserved8;
	var PS5_Reserved9;
	var PS5_Reserved10;
	var PS5_Reserved11;
	var PS5_Reserved12;
	var PS5_Reserved13;
	var PS5_Reserved14;
	var PS5_Reserved15;
	var PS5_Reserved16;
	var PS5_Reserved17;
	var PS5_Reserved18;
	var PS5_Reserved19;
	var PS5_Reserved20;

	// Added in SDK 1.53
	var SteamDeck_A;
	var SteamDeck_B;
	var SteamDeck_X;
	var SteamDeck_Y;
	var SteamDeck_L1;
	var SteamDeck_R1;
	var SteamDeck_Menu;
	var SteamDeck_View;
	var SteamDeck_LeftPad_Touch;
	var SteamDeck_LeftPad_Swipe;
	var SteamDeck_LeftPad_Click;
	var SteamDeck_LeftPad_DPadNorth;
	var SteamDeck_LeftPad_DPadSouth;
	var SteamDeck_LeftPad_DPadWest;
	var SteamDeck_LeftPad_DPadEast;
	var SteamDeck_RightPad_Touch;
	var SteamDeck_RightPad_Swipe;
	var SteamDeck_RightPad_Click;
	var SteamDeck_RightPad_DPadNorth;
	var SteamDeck_RightPad_DPadSouth;
	var SteamDeck_RightPad_DPadWest;
	var SteamDeck_RightPad_DPadEast;
	var SteamDeck_L2_SoftPull;
	var SteamDeck_L2;
	var SteamDeck_R2_SoftPull;
	var SteamDeck_R2;
	var SteamDeck_LeftStick_Move;
	var SteamDeck_L3;
	var SteamDeck_LeftStick_DPadNorth;
	var SteamDeck_LeftStick_DPadSouth;
	var SteamDeck_LeftStick_DPadWest;
	var SteamDeck_LeftStick_DPadEast;
	var SteamDeck_LeftStick_Touch;
	var SteamDeck_RightStick_Move;
	var SteamDeck_R3;
	var SteamDeck_RightStick_DPadNorth;
	var SteamDeck_RightStick_DPadSouth;
	var SteamDeck_RightStick_DPadWest;
	var SteamDeck_RightStick_DPadEast;
	var SteamDeck_RightStick_Touch;
	var SteamDeck_L4;
	var SteamDeck_R4;
	var SteamDeck_L5;
	var SteamDeck_R5;
	var SteamDeck_DPad_Move;
	var SteamDeck_DPad_North;
	var SteamDeck_DPad_South;
	var SteamDeck_DPad_West;
	var SteamDeck_DPad_East;
	var SteamDeck_Gyro_Move;
	var SteamDeck_Gyro_Pitch;
	var SteamDeck_Gyro_Yaw;
	var SteamDeck_Gyro_Roll;
	var SteamDeck_Reserved1;
	var SteamDeck_Reserved2;
	var SteamDeck_Reserved3;
	var SteamDeck_Reserved4;
	var SteamDeck_Reserved5;
	var SteamDeck_Reserved6;
	var SteamDeck_Reserved7;
	var SteamDeck_Reserved8;
	var SteamDeck_Reserved9;
	var SteamDeck_Reserved10;
	var SteamDeck_Reserved11;
	var SteamDeck_Reserved12;
	var SteamDeck_Reserved13;
	var SteamDeck_Reserved14;
	var SteamDeck_Reserved15;
	var SteamDeck_Reserved16;
	var SteamDeck_Reserved17;
	var SteamDeck_Reserved18;
	var SteamDeck_Reserved19;
	var SteamDeck_Reserved20;

	var Horipad_M1;
	var Horipad_M2;
	var Horipad_L4;
	var Horipad_R4;

	var Count; // If Steam has added support for new controllers origins will go here.
	var MaximumPossibleValue = 32767; // Origins are currently a maximum of 16 bits.

	var UNKNOWN = -1;

	@:from private static function fromString(s:String):EInputActionOrigin {
		var i = Std.parseInt(s);

		if (i == null) {
			// if it's not a numeric value, try to interpret it from its name
			s = s.toUpperCase();
			return fromStringMap.exists(s) ? fromStringMap.get(s) : UNKNOWN;
		}

		return cast Std.int(i);
	}

	@:to public inline function toString():String {
		if (toStringMap.exists(cast this)) {
			return toStringMap.get(cast this);
		}

		return "unknown";
	}
}

enum abstract ESteamControllerPad(Int) {
	public var LEFT = 0;
	public var RIGHT = 1;
	public var BOTH = 2;
}

enum abstract EControllerSource(Int) {
	public var NONE = 0;
	public var LEFTTRACKPAD = 1;
	public var RIGHTTRACKPAD = 2;
	public var JOYSTICK = 3;
	public var ABXY = 4;
	public var SWITCH = 5;
	public var LEFTTRIGGER = 6;
	public var RIGHTTRIGGER = 7;
	public var GYRO = 8;
	public var COUNT = 9;
}

enum abstract EControllerSourceMode(Int) {
	public var NONE = 0;
	public var DPAD = 1;
	public var BUTTONS = 2;
	public var FOURBUTTONS = 3;
	public var ABSOLUTEMOUSE = 4;
	public var RELATIVEMOUSE = 5;
	public var JOYSTICKMOVE = 6;
	public var JOYSTICKCAMERA = 7;
	public var SCROLLWHEEL = 8;
	public var TRIGGER = 9;
	public var TOUCHMENU = 10;
	public var MOUSEJOYSTICK = 11;
	public var MOUSEREGION = 12;
}

enum abstract EGamepadTextInputLineMode(Int) {
	public var SINGLE_LINE = 0;
	public var MULTIPLE_LINES = 1;
}

enum abstract EGamepadTextInputMode(Int) {
	public var NORMAL = 0;
	public var PASSWORD = 1;
}

enum abstract ESteamInputActionEventType(Int) {
	var DigitalAction;
	var AnalogAction;
}

enum abstract ESteamInputType(Int) {
	var Unknown;
	var SteamController;
	var XBox360Controller;
	var XBoxOneController;
	var GenericGamepad;		// DirectInput controllers
	var PS4Controller;
	var AppleMFiController;	// Unused
	var AndroidController;	// Unused
	var SwitchJoyConPair;		// Unused
	var SwitchJoyConSingle;	// Unused
	var SwitchProController;
	var MobileTouch;			// Steam Link App On-screen Virtual Controller
	var PS3Controller;		// Currently uses PS4 Origins
	var PS5Controller;		// Added in SDK 151
	var SteamDeckController;	// Added in SDK 153
}
