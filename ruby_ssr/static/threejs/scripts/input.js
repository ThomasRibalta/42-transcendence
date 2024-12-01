const audioCtx = window.CUSTOM_AUDIO_CONTEXT;

class InputManager {
	constructor() {
		this.keymap = {};
		this._pressed = {};
		this._justPressed = {};
		this._clicked = [false, false, false];
		this._justClicked = [false, false, false];
		this._keyListeners = { "keydown": [], "keyup": [] };
		this.mouseX = 0;
		this.mouseY = 0;
		this.#init();
	}
	#init() {
		this.#add_key("w", "up");
		this.#add_key("s", "down");
		this.#add_key("a", "left");
		this.#add_key("d", "right");
		this.#add_key("ArrowLeft", "look_left", true);
		this.#add_key("ArrowRight", "look_right", true);
		this.#add_key("e", "use");
		this.#add_key(" ", "shoot");
		this.#add_key("r", "reload");

		window.addEventListener("mousedown", (ev) => {
			audioCtx.resume();
			this._clicked[ev.button] = true;
		});
		window.addEventListener("mouseup", (ev) => {
			this._clicked[ev.button] = false;
			this._justClicked[ev.button] = false;
		});
	}
	clicked(mouseButton){
		if (mouseButton >= 0 && mouseButton <= 2)
			return this._clicked[mouseButton];
		return false;
	}
	justClicked(mouseButton){
		if (mouseButton < 0 || mouseButton > 2)
			return false;
		if (!this._justClicked[mouseButton] && this._clicked[mouseButton] === true) {
			this._justClicked[mouseButton] = true;
			return true;
		}
		return false;
	}
	pressed(keyname) {
		return this._pressed[keyname] == true;
	}
	justPressed(keyname) {
		if (!this._justPressed[keyname] && this._pressed[keyname]) {
			this._justPressed[keyname] = true;
			return true;
		}
		return false;
	}
	#add_key(keycode, keyname, cancelDefault = false) {
		if (!(this.keymap[keycode] instanceof Array))
			this.keymap[keycode] = [];
		this.keymap[keycode].push(keyname);
		this._pressed[keyname] = false;

		let downCallback = ev => {
			if (ev.key == keycode && !ev.repeat) {
				if (cancelDefault)
					ev.preventDefault();
				this._pressed[keyname] = true;
			}
		};

		let upCallback = ev => {
			if (ev.key == keycode) {
				this._pressed[keyname] = false;
				this._justPressed[keyname] = false;
			}
		};

		this._keyListeners["keydown"].push(downCallback);
		this._keyListeners["keyup"].push(upCallback);

		window.addEventListener("keydown", downCallback);
		window.addEventListener("keyup", upCallback);
	}
	clearKeyListeners() {
		for (key in this._keyListeners)
			for (kd of this._keyListeners[key])
				window.removeEventListener(key, kd);
	}
};

export { InputManager };
