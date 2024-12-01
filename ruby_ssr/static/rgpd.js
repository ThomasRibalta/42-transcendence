window.handleRGPDRequest = function (action) {
  let endpoint;
  const userId = document.getElementById("user_id").value;
  switch (action) {
    case 'access':
      // Supposons que l'ID utilisateur soit disponible dans une variable `userId`
      endpoint = `/api/user/${userId}`;
      fetch(endpoint, {method: 'GET'})
        .then(res => res.json())
        .then(res => {
            console.log(res);
            if (res.code == 200)
              alert(`Username : ${res.user[0].username}\nEmail : ${res.user[0].email}\nProfile Pic : ${res.user[0].img_url}`);
            else
              alert("Can't access user informations!");
        });
      // Redirige vers la page de consultation des données personnelles
      //window.location.href = endpoint;
      break;
    case 'rectify':
      window.location.href = '/edit-profile';
      break;
    case 'delete':
      if (confirm('Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.')) {
        endpoint = `/api/user/${userId}`;
        fetch(endpoint, { method: 'DELETE' })
          .then(response => {
            if (response.ok) {
              alert('Votre compte a été supprimé avec succès.');
              window.location.href = '/';
            } else {
              alert('Une erreur est survenue lors de la suppression de votre compte.');
            }
          });
      }
      break;
    case 'restrict':
      endpoint = `/api/rgpd/restrict/${userId}`;
      fetch(endpoint, { method: 'POST' })
        .then(response => {
          if (response.ok) {
            alert('Le traitement de vos données a été restreint.');
          } else {
            alert('Une erreur est survenue lors de la demande de restriction.');
          }
        });
      break;
    case 'portability':
      endpoint = `/api/user/${userId}`;
      fetch(endpoint, {method: 'GET'})
        .then(res => res.json())
        .then(res => {
            if (res.code == 200) {
              const rows = [
                ["Username", "Email", "Profile Picture"],
                [res.user[0].username, res.user[0].email, res.user[0].img_url]
              ];
              let csvContent = rows.map(e => e.join(",")).join("\n");
              // Create a blob
              var blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
              var url = URL.createObjectURL(blob);

              // Create a link to download it
              var pom = document.createElement('a');
              pom.href = url;
              pom.setAttribute('download', `${res.user[0].username}_rgpd_informations.csv`);
              pom.click();
            }
            else
              alert("Can't access user informations!");
        });
      break;
    default:
      console.error('Action invalide');
  }
}
