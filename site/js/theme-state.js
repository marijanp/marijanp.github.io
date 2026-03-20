document.addEventListener('DOMContentLoaded', () => {
  var checkbox = document.getElementById('themeController');
  checkbox.checked = JSON.parse(localStorage.getItem('themeState'));
  checkbox.addEventListener('change', () => {
    localStorage.setItem('themeState', checkbox.checked);
  });
});
