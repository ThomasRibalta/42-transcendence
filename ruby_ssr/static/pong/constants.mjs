const canvasWidth = 800;
const canvasHeight = 600;

const winningScore = 5;

let barWidth = 12;
let barHeight = 120;
const barPadding = 10;
const barMoveSpeed = 350;
const barHitboxPadding = 3;

const topHitbox = 10;

let ballRadius = 8;
let ballMoveSpeed = 20;
let ballMaxSpeed = 90;
let ballAcceleration = 2;

const goalWidth = 50;

const timeStep = 1 / 60.0;

export {
  canvasWidth,
  canvasHeight,
  barWidth,
  barPadding,
  timeStep,
  barMoveSpeed,
  barHeight,
  goalWidth,
  ballRadius,
  barHitboxPadding,
  topHitbox,
  ballMoveSpeed,
  ballMaxSpeed,
  ballAcceleration,
  winningScore,
};
