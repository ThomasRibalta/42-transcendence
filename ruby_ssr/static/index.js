const WINDOW_EVENTS = {};

window.WINDOW_ANIMATIONS_FRAMES = [];
window.CUSTOM_AUDIO_CONTEXT = new AudioContext();
window.CUSTOM_RENDERER = null;
window.CUSTOM_SCENE = null;
window.CUSTOM_LEVEL = null;
window.GAME_STATES = {
  default: 0,
  pong: 1,
  aipong: 2,
  threejs: 3,
};

window.GAMESTATE = -1;

window.addListener = (event, handler) => {
  if (!(event in WINDOW_EVENTS)) WINDOW_EVENTS[event] = [];
  WINDOW_EVENTS[event] = handler;
  window.addEventListener(event, handler);
};

window.removeAllListeners = (event) => {
  if (!(event in WINDOW_EVENTS)) return;
  for (let handler of WINDOW_EVENTS[event])
    window.removeEventListener(event, handler);
  history.pushState();
  delete WINDOW_EVENTS[event];
};

window.cancelAnimations = () => {
  for (let v in WINDOW_ANIMATIONS_FRAMES) window.cancelAnimationFrame(v);
  WINDOW_ANIMATIONS_FRAMES.length = 0;
  if (window.threeJSStop) {
    window.threeJSStop();
  }
};

window.resetHomePage = function () {
  const popUp = document.getElementById("pop-up");
  popUp.innerHTML = "";
  window.GAMESTATE = window.GAME_STATES.default;
  window.cancelAnimations();
  const game = document.getElementById("game");
  game.innerHTML = "";
};

window.popUpFonc = function showPopup(message) {
  const popupContainer = document.getElementById("pop-up");

  const popup = document.createElement("div");
  popup.className = "alert alert-info fade show";
  popup.style.animation = "slideIn 0.5s ease-out";
  popup.innerHTML = message;

  popupContainer.appendChild(popup);

  setTimeout(() => {
    popup.classList.add("fade");
    popup.remove();
  }, 6000);
};

async function refreshAccessToken() {
  const response = await fetch("/api/auth/refresh", {
    method: "POST",
  });

  if (response.ok) {
    const newExpirationTime = Math.floor(Date.now() / 1000) + 3600;
    localStorage.setItem("accessTokenExpiry", newExpirationTime);

    startTokenTimer(3600, refreshAccessToken);
  } else {
    console.error("Échec du rafraîchissement du jeton.");
  }
}

window.startTokenTimer = function startTokenTimer(
  expirationTimeInSeconds,
  refreshTokenCallback
) {
  const remainingTime = expirationTimeInSeconds * 1000;

  window.timerToken = setTimeout(() => {
    refreshTokenCallback();
  }, remainingTime - 5000);
};

function loadPageScript(game) {
  const script = game.querySelector("script");
  if (!script) return;
  const existingScripts = game.querySelectorAll('script[type="module"]');
  existingScripts.forEach((s) => s.remove());

  const newScript = document.createElement("script");
  newScript.type = "module";
  newScript.src = script.src;
  game.appendChild(newScript);

  newScript.onload = () => {
    if (document.getElementById("form_login")) {
      window.loadLoginFormAction();
    }
    if (document.getElementById("form_register")) {
      window.loadRegisterFormAction();
    }
    if (document.getElementById("form_validate_code")) {
      window.loadValidateForm();
    }
    if (document.getElementById("form_edit_profile")) {
      window.loadEditProfileFormAction();
    }
    if (document.getElementById("form_tournament")) {
      window.loadTournamentFormAction();
    }
    if (window.location == "https://localhost/pong") {
      window.pongMain();
      window.GAMESTATE = window.GAME_STATES.pong;
    }
    if (window.location == "https://localhost/3dgame") {
      if (window.threeJSStop) {
        window.threeJSStop();
      }
      window.threeJSMain();
      window.GAMESTATE = window.GAME_STATES.threejs;
    } else {
      if (window.threeJSStop) {
        window.threeJSStop();
      }
    }
    if (window.location.href === "https://localhost/pongserv") {
      window.startNormalGame();
    }
    if (window.location.href === "https://localhost/pongserv-ranked") {
      window.startRankedGame();
    }
    if (/^https:\/\/localhost\/tournament\/\d+$/.test(window.location.href)) {
      window.startTournamentGame();
    }
  };
}

function rebindEvents() {
  removeAllListeners("click");
  document
    .getElementById("home_link")
    .addEventListener("click", handleHomeClick);
  document
    .getElementById("pong_link")
    .addEventListener("click", handlePongClick);
  document
    .getElementById("threejs_link")
    .addEventListener("click", handleThreeJSClick);
  if (document.getElementById("button_login")) {
    document
      .getElementById("button_login")
      .addEventListener("click", handleLoginClick);
    document
      .getElementById("button_register")
      .addEventListener("click", handleRegisterClick);
  } else if (document.getElementById("button_logout")) {
    document
      .getElementById("ranking_link")
      .addEventListener("click", handleRankingClick);
    document
      .getElementById("rgpd_link")
      .addEventListener("click", handleRGPDClick);
    document
      .getElementById("button_logout")
      .addEventListener("click", handleLogoutClick);
    document
      .getElementById("button_profile")
      .addEventListener("click", handleProfileClick);
    document
      .getElementById("add_friend_button")
      .addEventListener("click", handleAddFriendClick);
    document
      .getElementById("submit_friend_request")
      .addEventListener("click", handleSubmitFriendRequest);
    if (document.getElementById("edit_profile_button")) {
      document
        .getElementById("edit_profile_button")
        .addEventListener("click", handleEditProfileClick);
    }
    if (document.getElementById("delete_profile_button")) {
      document
        .getElementById("delete_profile_button")
        .addEventListener("click", handleDeleteProfileClick);
    }
    if (document.getElementById("create_tournaments")) {
      document
        .getElementById("create_tournaments")
        .addEventListener("click", handleCreateTournamentClick);
    }
    document.querySelectorAll(".join_tournament_btn").forEach((button) => {
      button.addEventListener("click", handleJoinTournamentClick);
    });
    document.querySelectorAll(".accept-request").forEach((button) => {
      button.addEventListener("click", () => {
        const friendshipId = button.getAttribute("data-friendship-id");
        handleFriendRequestAction(friendshipId, "accepted", button);
      });
    });
    document.querySelectorAll(".reject-request").forEach((button) => {
      button.addEventListener("click", () => {
        const friendshipId = button.getAttribute("data-friendship-id");
        handleFriendRequestAction(friendshipId, "rejected", button);
      });
    });
  }
  if (document.getElementById("play_button")) {
    document
      .getElementById("play_button")
      .addEventListener("click", handlePlayEventClick);
  }
  if (document.getElementById("ranked_button")) {
    document
      .getElementById("ranked_button")
      .addEventListener("click", handleRankedEventClick);
  }
  if (document.getElementById("tournament_button")) {
    document
      .getElementById("tournament_button")
      .addEventListener("click", handleTournamentClick);
  }
}

function loadPage(game, url, gamestate, shouldPushState = true) {
  if (window.connection && window.connection.readyState === 1) {
    window.connection.close();
  }
  if (shouldPushState) history.pushState(gamestate, null, url);
  if (window.threeJSStop) {
    window.threeJSStop();
  }
  window.GAMESTATE = gamestate;
  let popUp = document.getElementById("pop-up");
  popUp.innerHTML = "";
  fetch(url, {
    headers: {
      "X-Requested-With": "XMLHttpRequest",
      IsLogged: document.getElementById("button_logout") ? true : false,
    },
  })
    .then((res) => {
      return res.json();
    })
    .then((json) => {
      game.innerHTML = json.body;
      if (json.nav) {
        document.getElementById("nav").innerHTML = json.nav;
      }
      rebindEvents();
      loadPageScript(game);
    })
    .catch((err) => {
      loadPage(
        document.getElementById("game"),
        "https://localhost/",
        window.GAME_STATES.default
      );
      console.error("Error: ", err);
    });
}

function handleHomeClick(ev) {
  ev.preventDefault();
  const url = "https://localhost";
  loadPage(document.getElementById("game"), url, window.GAME_STATES.default);
}

function handleThreeJSClick(ev) {
  ev.preventDefault();
  const url = "https://localhost/3dgame";
  loadPage(document.getElementById("game"), url, window.GAME_STATES.threejs);
}

function handlePongClick(ev) {
  ev.preventDefault();
  const url = "https://localhost/pong";
  loadPage(document.getElementById("game"), url, window.GAME_STATES.pong);
}

function handleLoginClick(ev) {
  ev.preventDefault();
  const url = "https://localhost/login";
  loadPage(document.getElementById("game"), url, window.GAME_STATES.default);
}

function handleRegisterClick(ev) {
  ev.preventDefault();
  const url = "https://localhost/register";
  loadPage(document.getElementById("game"), url, window.GAME_STATES.default);
}

function handleRGPDClick(ev) {
  ev.preventDefault();
  const url = "https://localhost/rgpd";
  loadPage(document.getElementById("game"), url, window.GAME_STATES.default);
}

function handleRankingClick(ev) {
  ev.preventDefault();
  const url = "https://localhost/ranking";
  loadPage(document.getElementById("game"), url, window.GAME_STATES.default);
}

function handleTournamentClick(ev) {
  ev.preventDefault();
  const url = "https://localhost/tournaments";
  loadPage(document.getElementById("game"), url, window.GAME_STATES.default);
}

function handleCreateTournamentClick(ev) {
  ev.preventDefault();
  const url = "https://localhost/create-tournament";
  loadPage(document.getElementById("game"), url, window.GAME_STATES.default);
}

function handleJoinTournamentClick(ev) {
  ev.preventDefault();
  const tournamentId = ev.target.getAttribute("data-tournament-id");
  const url = `https://localhost/tournament/${tournamentId}`;
  loadPage(document.getElementById("game"), url, window.GAME_STATES.default);
}

function handleLogoutClick(ev) {
  ev.preventDefault();
  fetch("https://localhost/api/auth/logout")
    .then((res) => res.json())
    .then((json) => {
      if (json.success) {
        if (
          window.friendSocketConnection &&
          window.friendSocketConnection.readyState === 1
        ) {
          window.friendSocketConnection.close();
        }
        localStorage.removeItem("accessToken");
        clearInterval(window.timerToken);
        const url = "https://localhost";
        loadPage(
          document.getElementById("game"),
          url,
          window.GAME_STATES.default
        );
      }
    })
    .catch((err) => console.error("Error: ", err));
}

function handleProfileClick(ev) {
  ev.preventDefault();
  const url = "https://localhost/profile";
  loadPage(document.getElementById("game"), url, window.GAME_STATES.default);
}

function handleEditProfileClick(ev) {
  ev.preventDefault();
  const url = "https://localhost/edit-profile";
  loadPage(document.getElementById("game"), url, window.GAME_STATES.default);
}

function handlePlayEventClick(ev) {
  ev.preventDefault();
  const url = "https://localhost/pongserv";
  loadPage(document.getElementById("game"), url, window.GAME_STATES.default);
}

function handleRankedEventClick(ev) {
  ev.preventDefault();
  const url = "https://localhost/pongserv-ranked";
  loadPage(document.getElementById("game"), url, window.GAME_STATES.default);
}

function handleAddFriendClick(ev) {
  ev.preventDefault();
  const modal = new bootstrap.Modal(document.getElementById("addFriendModal"));
  modal.show();
}

function handleSubmitFriendRequest(ev) {
  ev.preventDefault();
  const username = document.getElementById("friend_username").value;
  fetch("https://localhost/api/add-friend", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ friend_id: username }),
  })
    .then((res) => res.json())
    .then((json) => {
      if (json.success) {
        const modal = bootstrap.Modal.getInstance(
          document.getElementById("addFriendModal")
        );
        modal.hide();
        window.addFriendRequest(json.friend_name, json.friendship_id, true);
        document.getElementById("friend_username").value = "";
        if (
          window.friendSocketConnection &&
          window.friendSocketConnection.readyState === 1
        ) {
          window.friendSocketConnection.send(
            JSON.stringify({
              type: "add_friend",
              friend_id: json.friend_id,
              friendship_id: json.friendship_id,
            })
          );
        }
      } else {
        window.popUpFonc(json.error);
      }
    })
    .catch((err) => console.error("Error: ", err));
}

function handleFriendRequestAction(friendshipId, action, button) {
  fetch(`https://localhost/api/friend/${friendshipId}`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ status: action }),
  })
    .then((response) => response.json())
    .then((data) => {
      if (data.success) {
        const parentLi = button.closest("li");
        let username = parentLi.querySelector(".username").textContent;
        parentLi.remove();
        if (action === "accepted") {
          window.addFriendAccepted(username, data.friend_id, friendshipId);
          if (
            window.friendSocketConnection &&
            window.friendSocketConnection.readyState === 1
          ) {
            window.friendSocketConnection.send(
              JSON.stringify({
                type: "new_friend",
                friend_id: data.friend_id,
                status: "accepted",
                friendship_id: friendshipId,
              })
            );
          }
        } else {
          if (
            window.friendSocketConnection &&
            window.friendSocketConnection.readyState === 1
          ) {
            window.friendSocketConnection.send(
              JSON.stringify({
                type: "new_friend",
                friend_id: data.friend_id,
                status: "rejected",
                friendship_id: friendshipId,
              })
            );
          }
        }
        rebindEvents();
      } else {
        window.popUpFonc(data.error);
      }
    })
    .catch((error) => console.error("Fetch error:", error));
}

function handleDeleteProfileClick(ev) {
  ev.preventDefault();
  const deleteProfileButton = document.getElementById("delete_profile_button");
  const userId = deleteProfileButton.dataset.userId;
  console.log(userId);
  fetch(`https://localhost/api/user/${userId}`, {
    method: "DELETE",
  })
    .then((response) => response.json())
    .then((data) => {
      if (data.success) {
        if (
          window.friendSocketConnection &&
          window.friendSocketConnection.readyState === 1
        ) {
          window.friendSocketConnection.close();
        }
        const url = "https://localhost";
        loadPage(
          document.getElementById("game"),
          url,
          window.GAME_STATES.default
        );
      }
    });
}

window.addEventListener("popstate", function (ev) {
  const currentUrl = window.location.pathname;

  if (currentUrl != ev.state) {
    let state = window.GAME_STATES.default;
    if (currentUrl == "https://localhost/pong") state = window.GAME_STATES.pong;
    else if (currentUrl == "https://localhost/3dgame")
      state = window.GAME_STATES.threejs;
    loadPage(document.getElementById("game"), currentUrl, state, false);
  }
});

function onAppLoad() {
  const accessTokenExpiry = localStorage.getItem("accessTokenExpiry");
  const now = Math.floor(Date.now() / 1000);

  if (accessToken && refreshToken && accessTokenExpiry) {
    if (now < accessTokenExpiry) {
      const remainingTime = accessTokenExpiry - now;
      startTokenTimer(remainingTime, refreshAccessToken);
    } else {
      refreshAccessToken();
    }
  } else {
    window.loadPage(
      document.getElementById("game"),
      "https://localhost",
      window.GAME_STATES.default
    );
  }
}

document.addEventListener("DOMContentLoaded", (ev) => {
  rebindEvents();
});
