import { Audio, AudioLoader, Mesh, TextureLoader } from 'three';
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { TextGeometry } from 'three/addons/geometries/TextGeometry.js';
import { LOG_DEBUG, LOG_ERROR, LOG_INFO, LOG_WARNING } from "./game_logger";

export async function sleep(ms) {
	return new Promise(r => setTimeout(r, ms));
}

export class ModelManager {
	constructor(loader) {
		this._loader = loader;
		this._modelsToLoad = [];
		this._models = {};
	}

	static INSTANCE = new ModelManager(new GLTFLoader());

	get models() { return this._models; }
	set models(_) { }

	get loader() { return this._loader; }

	pushModelInfo(modelName, modelPath) {
		this._modelsToLoad.push({ name: modelName, path: modelPath });
	}

	addModel(modelName, modelGLTF) {
		this.models[modelName] = modelGLTF;
	}

	async loadModels() {
		let modelsLoaded = 0;
		let loadingError = false;
		let errorMsg = "";
		let modelsAmount = this._modelsToLoad.length;
		LOG_INFO("Models loading started!");
		if (modelsAmount > 0) {
			for (let modelInfo of this._modelsToLoad) {
				this.loader.load(modelInfo.path,
					model => { this.addModel(modelInfo.name, model), modelsLoaded++; },
					xhr => LOG_DEBUG(modelInfo.name + " model is loading : " + xhr.loaded / xhr.total * 100 + " / 100%"),
					err => { loadingError = true; errorMsg = err; }
				);
			}
		}
		await new Promise(res => {
			const interID = setInterval(() => {
				if (modelsLoaded === modelsAmount || loadingError === true) {
					clearInterval(interID);
					res();
				}
			}, 50);
		});
		this._modelsToLoad.length = 0;
		if (loadingError === true)
			LOG_WARNING("Error while loading some models! " + errorMsg);
		else
			LOG_INFO("All the models loaded successfully!");
	}

	getModel(name) {
		if (name in this.models) {
			return { scene: this.models[name].scene.clone(), animations: this.models[name].animations };
		}
		return undefined;
	}

	get loader() { return this._loader; }
};

export class TextureManager {
	constructor(loader) {
		this._loader = loader;
		this._texturesToLoad = [];
		this._textures = {};
	}

	static INSTANCE = new TextureManager(new TextureLoader());

	get textures() { return this._textures; }
	set textures(_) { }

	get loader() { return this._loader; }

	pushTextureInfo(textureName, texturePath) {
		this._texturesToLoad.push({ name: textureName, path: texturePath });
	}

	addTexture(modelName, texture) {
		this.textures[modelName] = texture;
	}

	async loadTextures() {
		let texturesLoaded = 0;
		let loadingError = false;
		let errorMsg = "";
		let texturesAmount = this._texturesToLoad.length;
		LOG_INFO("Textures loading started!");
		if (texturesAmount > 0) {
			for (let textureInfo of this._texturesToLoad) {
				this.loader.load(textureInfo.path,
					texture => {
						this.addTexture(textureInfo.name, texture);
						texturesLoaded++;
						LOG_DEBUG("Texture " + textureInfo.name + " is loaded!");
					},
					xhr => LOG_DEBUG(textureInfo.name + " texture is loading : " + xhr.loaded / xhr.total * 100 + " / 100%"),
					err => { loadingError = true; errorMsg = err; }
				);
			}
		}
		await new Promise(res => {
			const interID = setInterval(() => {
				if (texturesLoaded === texturesAmount || loadingError === true) {
					clearInterval(interID);
					res();
				}
			}, 50);
		});
		this._texturesToLoad.length = 0;
		if (loadingError === true)
			LOG_WARNING("Error while loading some textures! " + errorMsg);
		else
			LOG_INFO("All the textures loaded successfully!");
	}

	getTexture(name) {
		if (name in this.textures) {
			return this.textures[name].clone();
		}
		return undefined;
	}

	get loader() { return this._loader; }
};

export class AudioManager {
	constructor(loader) {
		this._loader = loader;
		this._soundsToLoad = [];
		this._sounds = {};
	}

	static INSTANCE = new AudioManager(new AudioLoader());

	get sounds() { return this._sounds; }
	set sounds(_) { }

	get loader() { return this._loader; }

	pushSoundInfo(soundName, soundPath) {
		this._soundsToLoad.push({ name: soundName, path: soundPath });
	}

	addSound(soundName, sound) {
		this.sounds[soundName] = sound;
	}

	async loadSounds() {
		let soundsLoaded = 0;
		let loadingError = false;
		let errorMsg = "";
		let soundsAmount = this._soundsToLoad.length;
		LOG_INFO("Sounds loading started!");
		if (soundsAmount > 0) {
			for (let soundInfo of this._soundsToLoad) {
				this.loader.load(soundInfo.path,
					buffer => {
						this.addSound(soundInfo.name, buffer);
						soundsLoaded++;
						LOG_DEBUG("Sound " + soundInfo.name + " is loaded!");
					},
					xhr => LOG_DEBUG(soundInfo.name + " sound is loading : " + xhr.loaded / xhr.total * 100 + " / 100%"),
					err => { loadingError = true; errorMsg = err; }
				);
			}
		}
		await new Promise(res => {
			const interID = setInterval(() => {
				if (soundsLoaded === soundsAmount || loadingError === true) {
					clearInterval(interID);
					res();
				}
			}, 50);
		});
		this._soundsToLoad.length = 0;
		if (loadingError === true)
			LOG_WARNING("Error while loading some sounds! " + errorMsg);
		else
			LOG_INFO("All the sounds loaded successfully!");
	}

	playSound(name, listener, loop = false, volume = 0.01) {
		if (name in this._sounds) {
			const audio = new Audio(listener);
			audio.setBuffer(this.getBuffer(name));
			audio.setLoop(loop);
			audio.setVolume(volume);
			audio.play();
		}
	}

	getBuffer(name) {
		return this.sounds[name];
	}

	get loader() { return this._loader; }
};

export async function drawText(text, parameters, player) {
	let geometry = new TextGeometry(text, parameters);
	let mesh = new Mesh(geometry);
	mesh.position.x = player.position.x - player.getForward().x * 0.5;
	mesh.position.z = player.position.z - player.getForward().z * 0.5;
	player.getLevel().scene.add(mesh);
	await sleep(2000);
	player.getLevel().scene.remove(mesh);
};
