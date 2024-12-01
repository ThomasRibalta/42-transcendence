import { makeBar, makeBall } from "./game_objects.mjs";
import {
  canvasWidth,
  canvasHeight,
  timeStep,
  topHitbox,
  winningScore,
  barHitboxPadding,
  goalWidth,
  barWidth,
} from "./constants.mjs";

function pong_main() {
  let previousTime = 0;
  let delta = 0.0;

  let upPressed = false;
  let downPressed = false;

  let debugMode = false;
  let wPressed = false;
  let sPressed = false;

  let hasAI = false;

  const ball = makeBall();
  const leftBar = makeBar();
  const rightBar = makeBar();
  rightBar.x = canvasWidth - goalWidth - barWidth;
  rightBar.startX = canvasWidth - goalWidth - barWidth;
  rightBar.color = "#F00000";
  rightBar.ai = {
    think_timer: 1.0,
    velY: 0.0,
    targetY: -1,
  };

  const Game = {
    playerScore: 0,
    aiScore: 0,
    timer: 0,
    isGameStarted: false,
    winner: -1, // -1 -> No winner, 0 -> Player won, 1 -> Ai won
    touchSound: new Audio("/static/sounds/bonk.mp3"),
    scoreSound: new Audio("/static/sounds/winSound.mp3"),

    updateScore: function () {
      let scoreText = document.getElementById("score_text");
      if (scoreText) {
        scoreText.textContent = this.playerScore + " - " + this.aiScore;
        if (this.playerScore >= winningScore) this.winner = 0;
        else if (this.aiScore >= winningScore) this.winner = 1;
        let winnerText = document.getElementById("winner_text");
        if (winnerText) {
          if (this.winner > -1) {
            winnerText.setAttribute("style", "color: black;");
            winnerText.textContent =
              (this.winner == 0 ? "Player1" : "Player2") + " won !";
          } else winnerText.setAttribute("style", "color: white;");
        }
      }
    },

    reset: function () {
      this.aiScore = 0;
      this.playerScore = 0;
      this.timer = 0;
      this.winner = -1;
      this.updateScore();
      if (document.getElementById("game_name"))
        document.getElementById("game_name").textContent =
          (hasAI ? "AI " : "") + "Pongpong";
      if (document.getElementById("game_info_text"))
        document.getElementById("game_info_text").textContent =
          "First to " + winningScore + " points wins !";
    },

    playTouchSound: function () {
      this.touchSound.volume = 0.2;
      this.touchSound.play();
    },

    playScoreSound: function () {
      this.scoreSound.volume = 0.2;
      this.scoreSound.play();
    },
  };

  const loop = (time) => {
    let dt = performance.now() - previousTime;

    delta += dt;
    while (delta > timeStep) {
      gameLoop(dt / 1000000.0);
      delta -= timeStep;
    }
    drawLoop();
    window.WINDOW_ANIMATIONS_FRAMES.push(window.requestAnimationFrame(loop));
    previousTime = performance.now();
  };

  function drawLoop() {
    const canvas = document.getElementById("drawCanvas");
    if (!canvas) return;
    if (canvas.getContext) {
      const ctx = canvas.getContext("2d");
      ctx.clearRect(0, 0, canvasWidth, canvasHeight);
      ctx.fillStyle = "#000000";
      ctx.fillRect(0, 0, canvasWidth, canvasHeight);
      ctx.clearRect(
        topHitbox / 2,
        topHitbox / 2,
        canvasWidth - topHitbox,
        canvasHeight - topHitbox
      );
      leftBar.render(ctx);
      rightBar.render(ctx);
      ball.render(ctx);
    }
  }

  function gameLoop(dt) {
    let checkbox = document.getElementById("checkbox_ai");
    if (window.GAMESTATE != window.GAME_STATES.pong) {
      Game.reset();
      leftBar.reset();
      rightBar.reset();
      ball.reset();
      return;
    }
    if (checkbox && hasAI != checkbox.checked) {
      hasAI = checkbox.checked;
      Game.reset();
      leftBar.reset();
      rightBar.reset();
      ball.reset();
    }
    if (upPressed && Game.isGameStarted && !hasAI) rightBar.moveUp(dt);
    else if (downPressed && Game.isGameStarted && !hasAI) rightBar.moveDown(dt);
    if (wPressed && Game.isGameStarted) leftBar.moveUp(dt);
    else if (sPressed && Game.isGameStarted) leftBar.moveDown(dt);
    if (hasAI) rightBarAI(dt, Game);
    ball.update(dt, Game, leftBar, rightBar);
    if (ball.velX == 0 && Game.isGameStarted) {
      Game.isGameStarted = false;
      leftBar.reset();
      rightBar.reset();
    }
  }

  function rightBarAI(dt, game) {
    rightBar.ai.think_timer -= dt;
    if (rightBar.ai.think_timer <= 0.0) {
      let start = { x: ball.x, y: ball.y };
      let vY = ball.velY;
      if (vY != 0 && ball.velX > 0) {
        while (true) {
          start.x += ball.velX * ball.moveSpeed * dt;
          start.y += vY * ball.moveSpeed * dt;
          if (start.x >= rightBar.x - barHitboxPadding) break;
          if (start.y <= topHitbox || start.y >= canvasHeight - topHitbox)
            vY *= -1;
        }
        rightBar.ai.targetY =
          start.y - (rightBar.height / 8) * (1.0 - Math.random() * 2);
        rightBar.ai.think_timer = 1.0;
      }
    }
    if (rightBar.ai.targetY > 0 && game.isGameStarted) {
      if (rightBar.ai.targetY < rightBar.y && rightBar.y >= topHitbox)
        rightBar.y -= rightBar.moveSpeed * dt;
      if (
        rightBar.ai.targetY > rightBar.y &&
        rightBar.y + rightBar.height <= canvasHeight - topHitbox
      )
        rightBar.y += rightBar.moveSpeed * dt;
    }
  }

  function startGame() {
    let start_text = document.getElementById("start_text");
    if (!start_text) return;
    if (Game.winner > -1) {
      Game.reset();
      start_text.setAttribute("style", "color: black;");
    } else {
      start_text.setAttribute("style", "color: white;");
      Game.isGameStarted = true;
      ball.velX = (1 - 2 * Math.round(Math.random())) * 10;
      ball.velY = (1 - 2 * Math.round(Math.random())) * 10;
    }
  }

  window.refreshPongInputs = () => {
    window.addListener("keydown", (ke) => {
      if (ke.key == "w" && !ke.repeat) wPressed = true;
      else if (ke.key == "s" && !ke.repeat) sPressed = true;
      if (ke.key == "ArrowUp") {
        ke.preventDefault();
        if (!ke.repeat) upPressed = true;
      } else if (ke.key == "ArrowDown") {
        ke.preventDefault();
        if (!ke.repeat) downPressed = true;
      } else if (ke.key == " " && ball.velX == 0) {
        ke.preventDefault();
        if (!ke.repeat) startGame();
      } else if (ke.key == "O") {
        debugMode = !debugMode;
      }
    });

    window.addListener("keyup", (ke) => {
      if (ke.key == "ArrowUp" && !ke.repeat) upPressed = false;
      if (ke.key == "ArrowDown" && !ke.repeat) downPressed = false;
      if (ke.key == "w" && !ke.repeat) wPressed = false;
      if (ke.key == "s" && !ke.repeat) sPressed = false;
    });

    window.WINDOW_ANIMATIONS_FRAMES.push(
      window.requestAnimationFrame((time) => {
        let game_info_text = document.getElementById("game_info_text");
        previousTime = performance.now();

        if (game_info_text)
          game_info_text.textContent =
            "First to " + winningScore + " points wins !";
        window.WINDOW_ANIMATIONS_FRAMES.push(
          window.requestAnimationFrame(loop)
        );
      })
    );
  };
  window.refreshPongInputs();
}

document.addEventListener("DOMContentLoaded", (_) => {
  pong_main();
  window.GAMESTATE = window.GAME_STATES.pong;
});

window.pongMain = pong_main;
