import * as THREE from 'three';

/**
 * @param {number} pColor 
 * @param {number} pSize 
 * @returns {THREE.Mesh}
 */
function makeCube(pColor, pSize)
{
	return new THREE.Mesh(new THREE.BoxGeometry(pSize, pSize, pSize),
		new THREE.MeshBasicMaterial({color: pColor}));
}

export {makeCube};