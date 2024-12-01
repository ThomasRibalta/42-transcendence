function loadValidateForm() {
  const form = document.getElementById("form_validate_code");

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

      fetch("https://localhost/api/auth/validate-code", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: localStorage.getItem("Authorization"),
        },
        body: JSON.stringify(formObject),
      })
        .then((response) => response.json())
        .then((data) => {
          if (data.success) {
            window.connexionFriendSocket();
            window.loadPage(
              document.getElementById("game"),
              "https://localhost/profil"
            );
            const expirationTime = Math.floor(Date.now() / 1000) + 3600;
            localStorage.setItem("accessTokenExpiry", expirationTime);
            window.startTokenTimer(3600, refreshAccessToken);
          } else {
            popUp.innerHTML = `<div class="alert alert-danger" role="alert">
              ${data.error}
              </div>`;
          }
        })
        .catch((error) => console.error("Error:", error));
    });
  } else {
    console.error("Form with id 'form_validate_code' not found.");
  }
}

document.addEventListener("DOMContentLoaded", (_) => {
  loadValidateForm();
});

window.loadValidateForm = loadValidateForm;
