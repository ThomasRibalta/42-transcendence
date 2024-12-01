function loadTournamentFormAction() {
  const form = document.getElementById("form_tournament");

  if (form) {
    form.addEventListener("submit", function (event) {
      event.preventDefault();

      const popUp = document.getElementById("pop-up");
      popUp.innerHTML = "";

      const formData = new FormData(this);
      const formObject = {};
      formData.forEach((value, key) => {
        formObject[key] = value;
      });

      fetch("https://localhost/api/tournament/create", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(formObject),
      })
        .then((response) => response.json())
        .then((data) => {
          if (data.success) {
            window.loadPage(
              document.getElementById("game"),
              "https://localhost/tournaments"
            );
          } else {
            popUp.innerHTML = `<div class="alert alert-danger" role="alert">
              ${data.error}
              </div>`;
          }
        })
        .catch((error) => console.error("Error:", error));
    });
  } else {
    console.error("Form with id 'form_tournaments' not found.");
  }
}

document.addEventListener("DOMContentLoaded", (_) => {
  loadTournamentFormAction();
});

window.loadTournamentFormAction = loadTournamentFormAction;
