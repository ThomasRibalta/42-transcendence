function loadRegisterFormAction() {
  const form = document.getElementById("form_register");

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

      fetch("https://localhost/api/auth/register", {
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
              "https://localhost/validate-code"
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
    console.error("Form with id 'form_register' not found.");
  }
}

document.addEventListener("DOMContentLoaded", (_) => {
  loadRegisterFormAction();
});

window.loadRegisterFormAction = loadRegisterFormAction;
