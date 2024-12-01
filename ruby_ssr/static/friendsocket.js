function openFriendModal(friendId, friendName, friendship_id) {
  document.getElementById("friendModalId").textContent = friendId;
  document.getElementById("friendModalUsername").textContent = friendName;
  document.getElementById("friendShipModalId").textContent = friendship_id;

  const friendModal = new bootstrap.Modal(
    document.getElementById("friendModal")
  );
  friendModal.show();
}

window.addFriendRequest = function (name, friendshipId, sender) {
  const dropdownMenu = document.querySelector(".dropdown-menu");

  const friendRequestItem = document.createElement("li");
  friendRequestItem.className =
    "dropdown-item d-flex justify-content-between align-items-center";

  if (sender) {
    friendRequestItem.innerHTML = `
          <div class="text-muted" data-friendship-id=${friendshipId}>${name}</div>
          <div class="badge badge-secondary">En attente</div>
      `;
  } else {
    friendRequestItem.innerHTML = `
          <div class="username">${name}</div>
          <div class="action-icons">
              <i class="fas fa-check-circle text-success accept-request" role="button" title="Accepter" data-friendship-id=${friendshipId}></i>
              <i class="fas fa-times-circle text-danger ms-2 reject-request" role="button" title="Refuser" data-friendship-id=${friendshipId}></i>
          </div>
      `;

    friendRequestItem
      .querySelector(".accept-request")
      .addEventListener("click", () => {
        handleFriendRequestAction(
          friendshipId,
          "accepted",
          friendRequestItem.querySelector(".accept-request")
        );
      });

    friendRequestItem
      .querySelector(".reject-request")
      .addEventListener("click", () => {
        handleFriendRequestAction(
          friendshipId,
          "rejected",
          friendRequestItem.querySelector(".reject-request")
        );
      });
  }
  dropdownMenu.appendChild(friendRequestItem);
};

window.addFriendAccepted = function (friend_name, friend_id, friendship_id) {
  const dropdownMenu = document.querySelector(".dropdown-menu");

  const friendRequestItem = document.createElement("li");

  friendRequestItem.innerHTML = `
      <a class="dropdown-item" data-friend-id=${friend_id} data-friend-name=${friend_name} data-friendship-id="${friendship_id}" onclick="openFriendModal('${friend_id}', '${friend_name}', '${friendship_id}')">
        <span id=${friend_id} class="status-indicator offline"></span> ${friend_name}
      </a>
    `;

  dropdownMenu.appendChild(friendRequestItem);
};

function connexionFriendSocket() {
  const url = "wss://localhost/friendsocket/";
  const connection = new WebSocket(url);
  let pingInterval;

  connection.onopen = () => {
    console.log("Connected to the friend socket.");
    connection.send("Hello from the client!");

    pingInterval = setInterval(() => {
      connection.send(
        JSON.stringify({
          type: "ping",
        })
      );
    }, 15000);
  };

  connection.onmessage = (event) => {
    let json = JSON.parse(event.data);
    if (json.type === "friend_connected") {
      let friend = document.getElementById(json.friend);
      if (friend) {
        friend.classList.add("online");
        friend.classList.remove("offline");
      }
    }
    if (json.type === "friend_disconnected") {
      let friend = document.getElementById(json.friend);
      if (friend) {
        friend.classList.add("offline");
        friend.classList.remove("online");
      }
    }
    if (json.type === "friend_request") {
      window.addFriendRequest(json.username, json.friendship_id, false);
      let pop_up = document.getElementById("pop-up");
      if (pop_up) {
        window.popUpFonc("You have received a new friend request.");
      }
    }
    if (json.type === "new_friend") {
      const friendshipDivs = document.querySelectorAll(
        'div[data-friendship-id="' + json.friendship_id + '"]'
      );
      let name = friendshipDivs[0].textContent;
      friendshipDivs.forEach((div) => {
        div.closest("li").remove();
      });
      if (json.status === "accepted")
        window.addFriendAccepted(name, json.friend_id, json.friendship_id);
    }
    if (json.type === "message") {
      popUpFonc(json.sender + " : " + json.message);
    }
    if (json.type === "error") {
      window.popUpFonc(json.message);
    }
  };

  connection.onclose = () => {
    clearInterval(pingInterval);
    console.log("Disconnected from the friend socket.");
  };

  connection.onerror = (error) => {
    console.error("Erreur WebSocket :", error);
  };

  window.friendSocketConnection = connection;
}

window.addEventListener("DOMContentLoaded", (_) => {
  connexionFriendSocket();

  document
    .getElementById("deleteFriend")
    .addEventListener("click", function () {
      const friendShipId =
        document.getElementById("friendShipModalId").textContent;
      fetch(`https://localhost/api/friend/${friendShipId}`, {
        method: "DELETE",
      })
        .then((response) => response.json())
        .then((data) => {
          if (data.success) {
            const friendModal = bootstrap.Modal.getInstance(
              document.getElementById("friendModal")
            );
            friendModal.hide();
          }
        });
    });

  document.getElementById("sendMessage").addEventListener("click", function () {
    const friendId = document.getElementById("friendModalId").textContent;
    const friendshipId =
      document.getElementById("friendShipModalId").textContent;
    const message = document.getElementById("messageInput").value;
    if (message.length > 0) {
      window.friendSocketConnection.send(
        JSON.stringify({
          type: "message",
          friendship_id: friendshipId,
          friend_id: friendId,
          message: message,
        })
      );
    }
    document.getElementById("messageInput").value = "";
  });
});

window.connexionFriendSocket = connexionFriendSocket;
