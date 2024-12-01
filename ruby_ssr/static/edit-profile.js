function loadEditProfileFormAction() {
  const form = document.getElementById("form_edit_profile");

  if (form) {
    form.addEventListener("submit", function (event) {
      event.preventDefault();

      const formData = new FormData(this);

      const userId = document.getElementById("user_id").value;

      fetch(`https://localhost/api/user/${userId}`, {
        method: "PUT",
        headers: {
          Accept: "*/*",
        },
        body: formData,
      })
        .then((response) => response.json())
        .then((data) => {
          const popUp = document.getElementById("pop-up");
          popUp.innerHTML = "";

          if (data.success) {
            window.loadPage(
              document.getElementById("game"),
              "https://localhost/profile"
            );
          } else {
            window.popUpFonc(data.error);
          }
        })
        .catch((error) => console.error("Error:", error));
    });
  } else {
    console.error("Form with id 'form_edit_profile' not found.");
  }
}

document.addEventListener("DOMContentLoaded", (_) => {
  loadEditProfileFormAction();
});

window.loadEditProfileFormAction = loadEditProfileFormAction;
