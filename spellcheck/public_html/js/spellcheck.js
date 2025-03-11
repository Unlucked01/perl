// Функция для замены слова
function replaceWord(position, replacement) {
    document.getElementById('replace_' + position).value = replacement;
    
    // Визуальное подтверждение выбора
    const buttons = document.querySelectorAll(`button[onclick^="replaceWord(${position},"]`);
    buttons.forEach(button => {
        button.classList.remove('selected');
        if (button.textContent.startsWith(replacement + ' ')) {
            button.classList.add('selected');
            button.style.backgroundColor = '#4caf50';
            button.style.color = 'white';
        }
    });
}

// Функция для добавления слова в словарь
// Функция для добавления слова в словарь
function addToDictionary(word) {
    fetch('/cgi-bin/spellcheck.pl?action=add_word&word=' + encodeURIComponent(word))
        .then(response => response.text())
        .then(text => {
            alert(text);
            // Обновляем страницу после добавления слова
            location.reload();
        })
        .catch(error => {
            console.error('Ошибка:', error);
            alert('Произошла ошибка при добавлении слова в словарь.');
        });
}

// Добавляем стили для выбранных кнопок
document.addEventListener('DOMContentLoaded', function() {
    const style = document.createElement('style');
    style.textContent = `
        .btn.selected {
            background-color: #4caf50 !important;
            color: white !important;
        }
    `;
    document.head.appendChild(style);
}); 