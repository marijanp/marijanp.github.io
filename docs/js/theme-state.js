document.addEventListener('DOMContentLoaded', () => {
  var checked = JSON.parse(localStorage.getItem('themeState'));
  document.getElementById("themeController").checked = checked;
});

function saveThemeState(){
  var checkbox = document.getElementById('themeController');
  localStorage.setItem('themeState', checkbox.checked);
}
