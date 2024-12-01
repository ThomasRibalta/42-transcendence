import * as THREE from 'three'
import { LOG_DEBUG, LOG_ERROR, LOG_WARNING } from './game_logger.js';
import { generateUUID } from 'three/src/math/MathUtils.js';
import { makeZombie } from './maker.js';
import { AudioManager, drawText, ModelManager, sleep, TextureManager } from './utils.js';
import { mx_bilerp_1 } from 'three/src/nodes/materialx/lib/mx_noise.js';

export class Component {
	constructor(parent, scene) {
		this._parent = parent;
		this._position = new THREE.Vector3(0, 0, 0);
		this._rotation = new THREE.Vector3(0, 0, 0);
		this._scale = new THREE.Vector3(1, 1, 1);
		this._uuid = generateUUID();
		this.scene = scene;
	}

	get uuid() { return this._uuid; }

	get parent() { return this._parent; }
	set parent(pParent) {
		this._parent = pParent;
		this._scene = pParent._scene;
	}

	get position() { return this._position; }
	set position(pPos) { this._position = pPos; }

	get rotation() { return this._rotation; }
	set rotation(pRot) { this._rotation = pRot; }

	get scale() { return this._scale; }
	set scale(pScale) { this._scale = pScale; }

	get scene() { return this._scene; }
	set scene(pScene) { this._scene = pScene; }

	create() { }
	remove() { }
	/**
	 * @returns {Level | null}
	 */
	getLevel() {
		let tmp = this.parent;
		if (!tmp)
			return null;
		while (tmp != null && !(tmp instanceof Level))
			tmp = tmp.parent;
		return tmp;
	}
	/**
	 *
	 * @param {number} _ Time elapsed since last frame
	 */
	update(_) { }
	clone() { return this; }
};

export class BasicShape extends Component {
	/**
	 * @param {Component} parent Parent of the component
	 * @param {THREE.BufferGeometry} pShape Geometry of the mesh
	 * @param {THREE.MeshBasicMaterial} mat Material of the mesh
	 */
	constructor(pShape, pMat) {
		super(null, null);
		this.geometry = pShape;
		this.mat = pMat;
		this.mesh = new THREE.Mesh(this.geometry, this.mat);
	}
	create() {
		this.parent.scene.add(this.mesh);
	}
	remove() {
		this.parent.scene.remove(this.mesh);
	}
	update(_) {
		if (!this.parent)
			return;
		let newPos = this.position.clone();
		let newRot = this.rotation.clone();

		newPos.add(this.parent.position);
		newRot.add(this.parent.rotation);

		this.mesh.position.copy(newPos);
		this.mesh.rotation.setFromVector3(newRot);
	}
	clone() {
		return new BasicShape(this.geometry, this.mat);
	}
};

export class GameObject extends Component {
	/**
	 * @param {Level} level
	 * @param {string} pName
	 */
	constructor(pName) {
		super(null, null);
		this._name = pName;
		/**
		 * @type {Array<Component>}
		 */
		this.components = [];
	}
	get name() { return this._name; }
	set name(pName) { this._name = pName; }
	add(component) {
		if (component instanceof Component) {
			if (this.components.includes(component))
				return;
			component.parent = this;
			console.log(component);
			this.components.push(component);
		}
		else
			LOG_ERROR("Can't add non-component to %s gameobject!", this.name);
	}
	removeComponent(component) {
		if (component instanceof Component) {
			for (let i = 0; i < this.components.length; i++) {
				if (this.components[i]._uuid === component._uuid) {
					this.components.splice(i, 1);
					component.remove();
				}
			}
		}
		else
			LOG_ERROR("Can't add non-component to %s gameobject!", this.name);
	}
	/**
	 *
	 * @param {Component} type
	 * @returns
	 */
	getComponent(type) {
		for (let comp of this.components) {
			if (comp instanceof type)
				return comp;
		}
		return undefined;
	}
	create() {
		if (this.parent === undefined) {
			LOG_ERROR("%s gameobject is not affected to a level!", this.name);
			return;
		}
		for (let comp of this.components) {
			if (comp instanceof Component)
				comp.create();
		}
	}
	remove() {
		if (this.parent === null) {
			LOG_ERROR("%s gameobject is not affected to a level!", this.name);
			return;
		}
		for (let comp of this.components)
			if (comp instanceof Component)
				comp.remove();
	}
	objUpdate(_) { }
	update(dt) {
		if (this.parent === null)
			return;
		this.objUpdate(dt);
		for (let comp of this.components)
			comp.update(dt);
	}
	clone() {
		let cloneObj = new GameObject(this.name);
		cloneObj.position = this.position.clone();
		cloneObj.rotation = this.rotation.clone();
		cloneObj.scale = this.scale.clone();
		for (let comp of this.components)
			cloneObj.add(comp.clone());
		cloneObj.objUpdate = this.objUpdate;
		return cloneObj;
	}
};

export class Level extends Component {
	/**
	 *
	 * @param {THREE.Scene} scene
	 */
	constructor(scene) {
		super(null, scene);
		this.prevTime = Date.now() / 1000.0;
		this._player = null;
		this._objects = [];
		this._zombiesObjs = [];
		this._mapObjs = [];
	}

	get player() { return this._player; }
	set player(_) { }

	add(gameobject) {
		if (gameobject instanceof GameObject) {
			if (this._objects.includes(gameobject))
				return;
			gameobject.parent = this;
			gameobject.scene = this.scene;
			this._objects.push(gameobject);
		}
		else
			LOG_WARNING("Attempting to create add a non-Gameobject to the level!");
	}
	remove(gameobject) {
		if (gameobject instanceof GameObject) {
			if (this._objects.includes(gameobject)) {
				let idx = this._objects.indexOf(gameobject);
				if (idx !== -1) {
					gameobject.remove();
					this._objects.splice(idx, 1);
				}
			}
		}
	}
	create() {
		for (let obj of this._objects) {
			obj.create();
		}
		let player = this.find("Player");
		if (player === undefined)
			LOG_ERROR("Level doesn't contain a Player game object!");
		else
			this._player = player;
	}
	clear() {
		for (let obj of this._objects) {
			obj.remove();
		}
		this._objects.length = 0;
	}
	update(_) {
		let deltaTime = (Date.now() / 1000.0) - this.prevTime;

		for (let obj of this._objects) {
			if (obj instanceof GameObject) {
				obj.update(deltaTime);
			}
		}
		this.prevTime = Date.now() / 1000.0;
	}
	findAll(objName) {
		return this._objects.filter((obj) => obj.name.startsWith(objName));
	}
	find(objName) {
		let found = this.findAll(objName);
		if (found.length == 0)
			return undefined;
		return found[0];
	}
};

export class PlayerController extends Component {
	constructor(input_manager, camera) {
		super(null, null);
		this._input = input_manager;
		this._camera = camera;
		this._moveSpeed = 4.0;
		this._walkTimeBuffer = 0;
		this._score = 0;
		this._mouseX = 0;
		this._health = 3;
		this._immuneDelay = 1000;
		this._regenDelay = 3000;
		this._regenCountdown = -1;
		this._immune = false;
		this._targetSprite = new THREE.Sprite(new THREE.SpriteMaterial({ map: TextureManager.INSTANCE.getTexture("target") }));
		this._targetSprite.scale.multiplyScalar(0.02);
		this._targetSprite.position.y = 1;
		this._hitmarkerSprite = new THREE.Sprite(new THREE.SpriteMaterial({ map: TextureManager.INSTANCE.getTexture("hitmarker") }));
		this._hitmarkerSprite.scale.multiplyScalar(0.05);
		this._hitmarkerSprite.position.y = 1;
		this._hitmarkerSprite.visible = false;
		this._audioListener = new THREE.AudioListener();
		this._flashlight = new THREE.PointLight(0xffffff, 0.35, 8, 0.2);
		this._healthBarSprite = new THREE.Sprite(new THREE.SpriteMaterial({map: TextureManager.INSTANCE.getTexture("health_bar_good")}));
		this._healthBarSprite.position.y = 0.63;
		this._healthBarSprite.scale.multiplyScalar(0.25);

		window.addEventListener("mousemove", (ev) => {
			if (this.input.clicked(0)) {
				ev.preventDefault();

				let dX = ev.clientX - this._mouseX;
				this._mouseX = ev.clientX;
				if (this._health > 0)
					this.camera.rotation.y += -dX / 100;
			}
		});

		window.addEventListener("mousedown", (ev) => {
			if (ev.button == 0)
				this._mouseX = ev.clientX;
		});
	}

	get input() { return this._input; }
	set input(newInputManager) { this._input = newInputManager; }

	/**
	 * @returns {THREE.Camera}
	 */
	get camera() { return this._camera; }
	set camera(newCamera) { this._camera = newCamera; }

	getForward() {
		return new THREE.Vector3(
			Math.sin(this.camera.rotation.y),
			0,
			Math.cos(this.camera.rotation.y)
		);
	}

	getRight() {
		return new THREE.Vector3(
			Math.cos(this.camera.rotation.y),
			0,
			-Math.sin(this.camera.rotation.y)
		);
	}

	update(dt) {
		if (!parent)
			return;
		let newX = 0;
		let newZ = 0;
		if (this.input.pressed("up")) {
			const rayStartPos = this.parent.position.clone();
			const ray = new THREE.Raycaster(rayStartPos, this.getForward().multiplyScalar(-1).normalize(), 0.1, 0.4);
			if (ray.intersectObjects(this.getLevel()._mapObjs).length === 0 && ray.intersectObjects(this.getLevel()._zombiesObjs).length === 0) {
				newX = -this.getForward().x * this._moveSpeed * dt;
				newZ = -this.getForward().z * this._moveSpeed * dt;
				this._walkTimeBuffer += dt / 2;
			}
		}
		else if (this.input.pressed("down")) {
			const rayStartPos = this.parent.position.clone();
			const ray = new THREE.Raycaster(rayStartPos, this.getForward().normalize(), 0.1, 0.2);
			if (ray.intersectObjects(this.getLevel()._mapObjs).length === 0 && ray.intersectObjects(this.getLevel()._zombiesObjs).length === 0) {
				newX = this.getForward().x * this._moveSpeed * dt;
				newZ = this.getForward().z * this._moveSpeed * dt;
				this._walkTimeBuffer += dt;
			}
		}
		else if (this.input.pressed("right")) {
			const rayStartPos = this.parent.position.clone();
			const ray = new THREE.Raycaster(rayStartPos, this.getRight().normalize(), 0.1, 0.25);
			if (ray.intersectObjects(this.getLevel()._mapObjs).length === 0 && ray.intersectObjects(this.getLevel()._zombiesObjs).length === 0) {
				newX = this.getRight().x * this._moveSpeed * dt;
				newZ = this.getRight().z * this._moveSpeed * dt;
				this._walkTimeBuffer += dt;
			}
		}
		else if (this.input.pressed("left")) {
			const rayStartPos = this.parent.position.clone();
			const ray = new THREE.Raycaster(rayStartPos, this.getRight().multiplyScalar(-1).normalize(), 0.1, 0.25);
			if (ray.intersectObjects(this.getLevel()._mapObjs).length === 0 && ray.intersectObjects(this.getLevel()._zombiesObjs).length === 0) {
				newX = -this.getRight().x * this._moveSpeed * dt;
				newZ = -this.getRight().z * this._moveSpeed * dt;
				this._walkTimeBuffer += dt;
			}
		}
		else {
			if (this._walkTimeBuffer <= 0)
				this._walkTimeBuffer = 0;
			else
				this._walkTimeBuffer -= dt * 2;
		}

		if (this.parent.position.x + newX < 75 && this.parent.position.x + newX > -75)
			this.parent.position.x += newX;
		if (this.parent.position.z + newZ < 75 && this.parent.position.z + newZ > -75)
			this.parent.position.z += newZ;

		let mysteryBox = this.getLevel().find("MysteryBox").getComponent(MysteryBoxComp);
		if (this.parent.position.distanceTo(mysteryBox.parent.position) <= 1.3) {
			if (this._score >= 500)
				document.getElementById("info_text").textContent = "Press E to open the box";
			else
				document.getElementById("info_text").textContent = "You need at least 500 points";
			if (this.input.justPressed("use")
				&& mysteryBox._opened === false && this._score >= 500) {
				this._score -= 500;
				this.updateScoreText();
				mysteryBox.open();
			}
		} else {
			if (document.getElementById("info_text").textContent === "Press E to open the box"
				|| document.getElementById("info_text").textContent === "You need at least 500 points")
				document.getElementById("info_text").textContent = "";
		}

		if (this._walkTimeBuffer >= Math.PI / 2)
			this._walkTimeBuffer = 0;

		this.camera.rotation.x = Math.sin(this._walkTimeBuffer * 4) * Math.PI / 320;
		this.camera.position.copy(this.parent.position);
		this.parent.rotation.copy(this.camera.rotation);
		this._targetSprite.position.x = this.parent.position.x - 0.5 * this.getForward().x;
		this._targetSprite.position.z = this.parent.position.z - 0.5 * this.getForward().z;
		this._hitmarkerSprite.position.x = this.parent.position.x - 0.5 * this.getForward().x;
		this._hitmarkerSprite.position.z = this.parent.position.z - 0.5 * this.getForward().z;
		this._audioListener.position.copy(this.parent.position);
		this._flashlight.position.copy(this.parent.position);
		this._healthBarSprite.position.x = this.parent.position.x - 0.5 * this.getForward().x;
		this._healthBarSprite.position.z = this.parent.position.z - 0.5 * this.getForward().z;

	}

	create() {
		this.parent.scene.add(this._targetSprite);
		this.parent.scene.add(this._hitmarkerSprite);
		this.parent.scene.add(this._audioListener);
		this.parent.scene.add(this._flashlight);
		this.parent.scene.add(this._healthBarSprite);
	}
	remove() {
		this.parent.scene.remove(this._targetSprite);
		this.parent.scene.remove(this._hitmarkerSprite);
		this.parent.scene.remove(this._audioListener);
		this.parent.scene.remove(this._flashlight);
		this.parent.scene.remove(this._healthBarSprite);
	}
	async takeDamage() {
		if (this._immune === false) {
			this._health--;
			if (this._health >= 1)
				this._healthBarSprite.material.map = TextureManager.INSTANCE.getTexture("health_bar_bad");
			else
				this._healthBarSprite.material.map = TextureManager.INSTANCE.getTexture("health_bar_dead");
			LOG_DEBUG("Player took damage!");
			AudioManager.INSTANCE.playSound("playerHit", this._audioListener, false, 0.1);
			if (this._regenCountdown !== -1) {
				window.clearTimeout(this._regenCountdown);
				this._regenCountdown = -1;
			}
			this._regenCountdown = setTimeout(() => {
				this._health = 3;
				this._healthBarSprite.material.map = TextureManager.INSTANCE.getTexture("health_bar_good");
			}, this._regenDelay);
			if (this._health <= 0)
				this.playerDie();
			else {
				this._immune = true;
				await sleep(this._immuneDelay);
				this._immune = false;
			}
		}
	}
	playerDie() {
		this._immune = true;
		if (this._regenCountdown !== -1) {
			window.clearTimeout(this._regenCountdown);
			this._regenCountdown = -1;
		}
		this._moveSpeed = 0;
		this.camera.rotation.x = Math.PI / 3;
		this.camera.rotation.z = Math.PI / 6;
		document.getElementById("info_text").textContent = "Vous etes mort!";
		LOG_DEBUG("Player died!");
	}
	updateScoreText() {
		document.getElementById("score_text").textContent = this._score;
	}
};

export class ZombieAI extends Component {
	constructor(spawner) {
		super(null, null);
		this._velX = 0;
		this._velY = 0;
		this._moveSpeed = 1.0;
		this._refreshPeriod = 1000 / 60;
		this._health = 2;
		this._spawner = spawner;
		this._isRefreshing = false;
	}
	getForward() {
		return new THREE.Vector3(
			Math.sin(this.parent.rotation.y),
			0,
			Math.cos(this.parent.rotation.y)
		);
	}
	create() {
	}
	remove() {
	}
	update(dt) {
		if (!parent)
			return;
		if (this.parent.position.distanceTo(this.getLevel().player.position) <= 0.41) {
			this.getLevel().player.getComponent(PlayerController).takeDamage();
		}
		else {
			const rayPos = this.parent.position.clone();
			rayPos.y += 0.2;
			const ray = new THREE.Raycaster(rayPos, this.getForward().multiplyScalar(-1).normalize(), 0.1, 0.4);
			if (ray.intersectObjects(this.getLevel()._mapObjs).length === 0) {
				this.parent.position.x += this.getForward().x * this._moveSpeed * dt;
				this.parent.position.z += this.getForward().z * this._moveSpeed * dt;
			}
		}
		if (this._isRefreshing === false)
			this.lookForPlayer();
	}
	async lookForPlayer() {
		this._isRefreshing = true;
		await sleep(this._refreshPeriod);
		if (this.getLevel() !== undefined || this.getLevel().player === undefined) {
			let player = this.getLevel().player;
			let dirX = player.position.x - this.parent.position.x;
			let dirZ = player.position.z - this.parent.position.z;
			this.parent.rotation.y = Math.atan2(dirX, dirZ);
			this._isRefreshing = false;
		}
	}
	takeDamage(dmg) {
		if (this._health - dmg <= 0) {
			// Death animation
			this.getLevel().remove(this.parent);
			return true;
		}
		else {
			this._health -= dmg;
			return false;
		}
	}
};

export class SpawnerManager extends Component {
	constructor() {
		super(null, null);
		this._round = 0;
		this._roundStarted = false;
		this._isCheckingRoundEnd = false;
		this._spawners = [];
	}
	get timeBeforeRound() { if (this._round == 1) return 2; else return 8; }
	addSpawner(spawner) {
		if (spawner instanceof ZombieSpawner) {
			spawner.parent = this;
			this._spawners.push(spawner);
		}
	}
	async startRound() {
		if (this._roundStarted)
			return;
		this._round++;
		document.getElementById("round_text").textContent = this._round;
		document.getElementById("info_text").textContent = "Round " + this._round + " is starting!";
		LOG_DEBUG("Round " + this._round + " is starting...");
		this._roundStarted = true;
		await sleep(this.timeBeforeRound * 1000);
		document.getElementById("info_text").textContent = "";
		LOG_DEBUG("Round started " + this._round + " started!");
		for (let spawner of this._spawners) {
			if (spawner instanceof ZombieSpawner) {
				await sleep(1000 + Math.random() * 1500);
				spawner._leftToSpawn = 3 + (2 * (this._round - 1));
				spawner._round = this._round;
				spawner.spawn();
			}
		}
	}

	update(_) {
		if (this._isCheckingRoundEnd === false)
			this.checkForRoundEnd();
	}

	async checkForRoundEnd() {
		this._isCheckingRoundEnd = true;
		await new Promise(res => {
			const interID = setInterval(() => {
				let leftToSpawn = 0;
				for (let spawner of this._spawners) {
					leftToSpawn += spawner._leftToSpawn;
				}
				if (leftToSpawn === 0) {
					if (this.getLevel().findAll("Zombie").length === 0) {
						this._roundStarted = false;
						res();
						clearInterval(interID);
					}
				}
			}, 200);
		});
		await this.startRound();
		this._isCheckingRoundEnd = false;
	}
};

class AnimationSystem {
	constructor(gltf) {
		this._gltf = gltf;
		this._poses = [];
		this._anims = {};
		this._mixer = new THREE.AnimationMixer(this._gltf.scene);
	}
	get poses() { return this._poses; }
	set poses(_) { }

	get anims() { return this._anims; }
	set anims(_) { }

	addPose(name) {
		if (!(this.poses.includes(name))) {
			this.poses.push(name);
		}
	}
	playAnim(name) {
		if (name in this.anims) {
			let animation = this.anims[name];
			animation.time = 0;
			animation.enabled = true;
			animation.play();
		}
		else
			LOG_WARNING("Can't find " + name + " animation!");
	}
	compileAnims() {
		for (let i = 0; i < this._gltf.animations.length
			&& i < this.poses.length; i++) {
			this.anims[this.poses[i]] = this._mixer.clipAction(this._gltf.animations[i].clone());
		}
		this.poses.length = 0;
	}
};

export class AnimatedModel extends Component {
	constructor(gltf) {
		super(null, null);
		this._gltf = gltf;
		this._anim = new AnimationSystem(this._gltf);
	}

	get gltf() { return this._gltf; }
	set gltf(_) { }

	get anim() { return this._anim; }
	set anim(_) { }

	create() {
		this.parent.scene.add(this.gltf.scene);
	}
	remove() {
		this.parent.scene.remove(this.gltf.scene);
	}
	update(dt) {
		if (!this.parent)
			return;
		this.gltf.scene.position.copy(this.parent.position.clone().add(this.position));
		this.gltf.scene.scale.copy(this.scale);
		this.gltf.scene.rotation.setFromVector3(this.parent.rotation.clone().add(this.rotation));
		this.anim._mixer.update(dt);
	}
};

export class ZombieModel extends AnimatedModel {
	constructor() {
		super(ModelManager.INSTANCE.getModel("zombie"));
		this.anim.addPose("idle");
		this.anim.compileAnims();
		this.scale.multiplyScalar(0.3);
		this.anim.playAnim("idle");
	}
	create() {
		super.create();
	}
};

export class PlayerGun extends Component {

	constructor(inputManager, dmg = 1, reloadTime = 1500, shootDelay = 350, magCapacity = 20, weaponName = "gun", weaponSound = "gunFire") {
		super(null, null);
		this._input = inputManager;
		this._shootDelay = shootDelay;
		this._hasShot = false;
		this._reloadTime = reloadTime;
		this._isReloading = false;
		this._magCapacity = magCapacity;
		this._mag = magCapacity;
		this._shootRange = 30;
		this._isRefreshing = false;
		this._playerController = null;
		this._dmg = dmg;
		this._model = new AnimatedModel(ModelManager.INSTANCE.getModel(weaponName));
		this._model.anim.addPose("reload");
		this._model.anim.addPose("shoot");
		this._model.anim.compileAnims();
		this._weaponSound = weaponSound;
		for (let anim in this._model.anim.anims) {
			this._model.anim.anims[anim].repetitions = 1;
		}
	}
	create() {
		this._model.parent = this.parent;
		this._playerController = this.parent.getComponent(PlayerController);
		this._model.create();
		this._model.scale.x = 0.25;
		this._model.scale.y = 0.25;
		this._model.scale.z = 0.25;
		this._model.rotation.y = -Math.PI / 2 - Math.PI / 8;
		this.position.y = -0.2;
	}
	remove() {
		this._model.remove();
	}
	update(dt) {
		if (!this.parent)
			return;
		if (this._isReloading === false && this._mag < this._magCapacity
			&& this._input.justPressed("reload"))
			this.reload();
		if (this._hasShot === false && this._isReloading === false
			&& this._mag > 0
			&& this._input.pressed("shoot") === true)
			this.shoot();
		this.updatePos();
		this._model.update(dt);
	}
	updatePos() {
		this.position.x = -0.3 * this._playerController.getForward().x + 0.5 * this._playerController.getRight().x;
		this.position.z = -0.3 * this._playerController.getForward().z + 0.5 * this._playerController.getRight().z;
		this._model.position.copy(this.position);
	}
	async shoot() {
		this._hasShot = true;
		const startPos = this._playerController.camera.position.clone();
		const ray = new THREE.Raycaster(startPos, this._playerController.getForward().multiplyScalar(-1).normalize(), 0.1, this._shootRange);
		const zombiesObjs = [];
		this._model.anim.playAnim("shoot");
		this._mag--;
		LOG_DEBUG("Current munitions : " + this._mag);
		// Play fire sound
		AudioManager.INSTANCE.playSound(this._weaponSound, this._playerController._audioListener);
		await sleep(50);
		const zombies = this.getLevel().findAll("Zombie");
		for (let zombie of zombies) {
			if (zombie.name === "Zombie") {
				zombiesObjs.push(zombie.getComponent(ZombieModel).gltf.scene);
			}
		}
		LOG_DEBUG("Player shot!");
		if (zombiesObjs.length > 0) {
			const touched = ray.intersectObjects(zombiesObjs);
			LOG_DEBUG("Got all zombies");
			if (touched.length > 0) {
				if (touched[0].object.zombie.getComponent(ZombieAI).takeDamage(this._dmg))
					this._playerController._score += 50;
				this._playerController._score += 10;
				this._playerController.updateScoreText();
				this.showHitmarker();
				AudioManager.INSTANCE.playSound("hit", this._playerController._audioListener, false, 0.1);
				// Play hit marker sound
			}
		}
		await sleep(this._shootDelay);
		this._hasShot = false;
	}
	async showHitmarker() {
		this._playerController._hitmarkerSprite.visible = true;
		await sleep(80);
		this._playerController._hitmarkerSprite.visible = false;
	}
	async reload() {
		this._isReloading = true;
		this._model.anim.playAnim("reload");
		this._mag = this._magCapacity;
		AudioManager.INSTANCE.playSound("gunReload", this._playerController._audioListener);
		await sleep(this._reloadTime);
		this._isReloading = false;
	}
};

export class ZombieSpawner extends Component {

	static spawnerID = 0;

	/**
	 * @param {THREE.Vector3} pos
	 */
	constructor(pos) {
		super("ZombieSpawner" + ZombieSpawner.spawnerID++);
		this.position.copy(pos);
		this.position.y = 1;
		this._manager = null;
		this._round = 0;
		this._spawnRate = 5;
		this._leftToSpawn = 3;
		this._spawnRange = 8;
		this._shouldSpawn = true;
	}
	async spawn() {
		if (!parent || this._leftToSpawn <= 0)
			return;
		let level = this.getLevel();
		if (level) {
			if (this._shouldSpawn === true) {
				let spawnPos = this.position.clone();

				spawnPos.x += -8 + Math.random() * 16;
				spawnPos.z += -8 + Math.random() * 16;
				spawnPos.y = 1.5;
				let zomb = makeZombie(spawnPos, this._round, this);
				this.getLevel().add(zomb);
				this._leftToSpawn--;
			}
			await sleep(this._spawnRate * 1000);
			this.spawn();
		}
	}
};

export class MysteryBoxComp extends Component {
	constructor() {
		super(null, null);
		this._loot = {
			"gun": 0.55,
			"rifle": 0.30,
			//"rpg": 0.20,
			"laser": 0.10,
			"danceBomb": 0.05
		};
		this._model = new AnimatedModel(ModelManager.INSTANCE.getModel("box"));
		this._opened = false;
	}
	create() {
		this.parent.scene.add(this._model.gltf.scene);
	}
	remove() {
		this.parent.scene.remove(this._model.gltf.scene);
	}
	update(_) {
		this._model.gltf.scene.scale.copy(this.parent.scale);
		this._model.gltf.scene.position.copy(this.parent.position);
	}
	async open() {
		if (this._opened)
			return;
		let weight = 0;
		let rand = Math.random();
		let lootWeapon;
		let weaponName;
		this._opened = true;
		for (let m in this._loot) {
			weight += this._loot[m];
			if (weight >= rand) {
				weaponName = m;
				lootWeapon = new AnimatedModel(ModelManager.INSTANCE.getModel(m));
				lootWeapon.parent = this.parent;
				break;
			}
		}
		lootWeapon.gltf.scene.position.copy(this.parent.position);
		lootWeapon.gltf.scene.position.y = 1.5;
		lootWeapon.gltf.scene.rotation.y = Math.PI / 2;
		lootWeapon.gltf.scene.scale.copy(new THREE.Vector3(0.25, 0.25, 0.25));
		this.parent.scene.add(lootWeapon.gltf.scene);
		if (weaponName === "danceBomb") {
			await this.doTheDance();
			this.parent.scene.remove(lootWeapon.gltf.scene);
		}
		else {
			await sleep(2500);
			const oldGun = this.getLevel().player.getComponent(PlayerGun);
			const input = this.getLevel().player.getComponent(PlayerGun)._input;
			this.parent.scene.remove(lootWeapon.gltf.scene);
			this.getLevel().player.removeComponent(oldGun);
			if (weaponName === "rifle")
				this.getLevel().player.add(new PlayerGun(input, 3, 2500, 80, 45, "rifle"));
			else if (weaponName === "gun")
				this.getLevel().player.add(new PlayerGun(input));
			else if (weaponName === "laser")
				this.getLevel().player.add(new PlayerGun(input, 100, 4000, 400, 45, "laser", "raygun"));
		}
		this._opened = false;
	}
	async doTheDance() {
		await sleep(350);
		AudioManager.INSTANCE.playSound("dancebomb", this.getLevel().player.getComponent(PlayerController)._audioListener, false, 0.1);
		for (let spawner of this.getLevel().find("SpawnerManager").getComponent(SpawnerManager)._spawners) {
			spawner._shouldSpawn = false;
		}
		for (let zombie of this.getLevel().findAll("Zombie")) {
			zombie.getComponent(ZombieAI)._moveSpeed = 0;
			// Start the dance animation
		}
		await sleep(18000);
		for (let zombie of this.getLevel().findAll("Zombie")) {
			this.getLevel().remove(zombie);
		}
		for (let spawner of this.getLevel().find("SpawnerManager").getComponent(SpawnerManager)._spawners) {
			spawner._shouldSpawn = true;
		}
		this.getLevel().player.getComponent(PlayerController)._score += 1000;
		this.getLevel().player.getComponent(PlayerController).updateScoreText();
		this._opened = true;
	}
};
