const makeBar = (x, y, width, height) => {
  return {
    x: x,
    y: y,
    width: width,
    height: height,
    color: "#0000F0",

    render: function (ctx) {
      ctx.fillStyle = this.color;
      ctx.fillRect(this.x, this.y, this.width, this.height);
    },
  };
};

const makeBall = (x, y, radius) => {
  return {
    x: x,
    y: y,
    radius: radius,
    color: "#00F000",

    render: function (ctx) {
      ctx.beginPath();
      ctx.arc(
        this.x - this.radius / 2,
        this.y - this.radius / 2,
        this.radius,
        0,
        2 * Math.PI,
        false
      );
      ctx.fillStyle = this.color;
      ctx.fill();
    },
  };
};

function updateTimer(endTime, timerInterval) {
  const now = new Date();
  const timeRemaining = endTime - now;

  if (timeRemaining <= 0) {
    document.getElementById("timer").innerText =
      "Le tournoi commence maintenant!";
    clearInterval(timerInterval);
  } else {
    const minutes = Math.floor(timeRemaining / 1000 / 60);
    const seconds = Math.floor((timeRemaining / 1000) % 60);
    document.getElementById(
      "timer"
    ).innerText = `Temps restant: ${minutes}m ${seconds}s`;
  }
}

function parseDate(dateString) {
  const parsedDate = new Date(dateString);
  if (isNaN(parsedDate.getTime())) {
    return new Date(dateString.replace(" ", "T").replace(" +0000", "Z"));
  }
  return parsedDate;
}

/* rueifrwhfreuywghwuighvrnicjmowobuuhjvimrfkruqotnhijmrvobqnivmrcqbjnmkv
yvquicjodknjqouhvijmrocki brinqvmokclewvognrqbmviopc,w[r  evnbivom  pw  rbniu
bvvwhrnjcmekdl,ckfvimwbguijmvoqc,vmreiqbtnuimvqoc,pem rnbiutmvo] */

function startRankedGame() {
  const url = "wss://localhost/pongsocket/ranked";
  const connection = new WebSocket(url);
  window.connection = connection;
  const canvas = document.getElementById("drawCanvas");
  const ball = makeBall(400, 300, 10);
  const leftBar = makeBar(10, 250, 10, 100);
  leftBar.color = "#F00000";
  const rightBar = makeBar(780, 250, 10, 100);
  let timerInterval = null;
  let persistenceInterval = setInterval(() => {
    connection.send(JSON.stringify({ type: "keep_alive" }));
  }, 5000);

  connection.onopen = () => {
    connection.send("Hello from the client!");
    document.getElementById("loading_text").innerHTML =
      '<div class="spinner-border" role="status"> <span class="sr-only">Loading...</span></div>';
  };

  function init_game_info(json) {
    document.getElementById("player1_name").innerHTML = json.client1_username;
    document.getElementById("player2_name").innerHTML = json.client2_username;
    document.getElementById("player1_img").src = json.img_url1;
    document.getElementById("player2_img").src = json.img_url2;
  }

  function play_game(json, canvas) {
    if (!canvas) return;
    if (canvas.getContext) {
      const ctx = canvas.getContext("2d");
      ctx.clearRect(0, 0, 800, 600);
      ctx.fillStyle = "#000000";
      ctx.fillRect(0, 0, 800, 600);
      ctx.clearRect(10 / 2, 10 / 2, 800 - 10, 600 - 10);
      document.getElementById("loading_text").innerHTML = "";
      document.getElementById(
        "score_text"
      ).innerHTML = `${json.client1_pts} - ${json.client2_pts}`;

      if (json.paddle1_x && leftBar.x === 0) leftBar.x = json.paddle1_x;
      if (json.paddle2_x && rightBar.x === 0) rightBar.x = json.paddle2_x;

      if (json.paddle2_y) rightBar.y = json.paddle2_y;
      if (json.paddle1_y) leftBar.y = json.paddle1_y;

      if (json.bar_width) {
        if (leftBar.width === 0) leftBar.width = json.bar_width;
        if (rightBar.width === 0) rightBar.width = json.bar_width;
      }

      if (json.ball_x && json.ball_y) {
        ball.x = json.ball_x;
        ball.y = json.ball_y;
      }

      leftBar.render(ctx);
      rightBar.render(ctx);
      ball.render(ctx);
    }
  }

  connection.onmessage = (event) => {
    let json = JSON.parse(event.data);
    if (json.start) {
      init_game_info(json);
      clearInterval(persistenceInterval);
      timerInterval = setInterval(() => {
        updateTimer(new Date(parseDate(json.time_end)), timerInterval);
      }, 1000);
    } else if (json.ingame) {
      play_game(json, canvas);
    }
  };

  connection.onclose = () => {
    clearInterval(timerInterval);
    clearInterval(persistenceInterval);
    window.loadPage(document.getElementById("game"), "https://localhost/");
  };

  connection.onerror = (error) => {
    console.error("Erreur WebSocket :", error);
  };

  window.addEventListener("keydown", (event) => {
    if (event.key === "ArrowUp") {
      connection.send('{ "direction": "up" }');
    } else if (event.key === "ArrowDown") {
      connection.send('{ "direction": "down" }');
    }
  });

  window.addEventListener("keyup", (event) => {
    if (event.key === "ArrowUp" || event.key === "ArrowDown") {
      connection.send('{ "direction": null }');
    }
  });
}

window.addEventListener("DOMContentLoaded", (_) => {
  startRankedGame();
});

window.startRankedGame = startRankedGame;
