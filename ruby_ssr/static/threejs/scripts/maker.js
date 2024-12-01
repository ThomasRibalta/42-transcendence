import { Vector3 } from "three";
import { GameObject, ZombieAI, ZombieModel } from "./components";

/**
 * @param {Vector3} pos
 * @returns {GameObject} Zombie game object
 */
export function makeZombie(pos, round, spawner) {
	let zomb = new GameObject("Zombie");
	let ai = new ZombieAI(spawner);
	zomb.position.copy(pos);
	zomb.position.y = 0.85;

	ai._health = 2 + round / 4;
	zomb.add(ai);
	zomb.add(new ZombieModel());
	zomb.getComponent(ZombieModel).gltf.scene.children[0].zombie = zomb;
	zomb.objUpdate = (_) => {
		zomb.getComponent(ZombieModel)._rotation = zomb.rotation;
	};
	return zomb;
};
