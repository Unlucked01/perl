let typingTimer;
let isEnglishToRussian = true;

function switchLanguages() {
    isEnglishToRussian = !isEnglishToRussian;
    const sourceLabel = document.getElementById('source_label');
    const targetLabel = document.getElementById('target_label');
    const sourcePlaceholder = document.getElementById('source_text');
    const targetPlaceholder = document.getElementById('translated_text');
    const title = document.querySelector('h2');

    if (isEnglishToRussian) {
        sourceLabel.textContent = 'English Text:';
        targetLabel.textContent = 'Russian Translation:';
        sourcePlaceholder.placeholder = 'Type English text here...';
        targetPlaceholder.placeholder = 'Translation will appear here...';
        title.textContent = 'English to Russian Translator';
    } else {
        sourceLabel.textContent = 'Текст на русском:';
        targetLabel.textContent = 'Текст на английском:';
        sourcePlaceholder.placeholder = 'Введите русский текст...';
        targetPlaceholder.placeholder = 'Текст будет появляться здесь...';
        title.textContent = 'Переводчик с русского на английский';
    }

    document.getElementById('source_text').value = '';
    document.getElementById('translated_text').value = '';
}

function updateTranslation() {
    clearTimeout(typingTimer);
    typingTimer = setTimeout(function() {
        var sourceText = document.getElementById('source_text').value;
        if (sourceText.trim() === '') return;
        
        var formData = new FormData();
        formData.append('text', sourceText);
        formData.append('direction', isEnglishToRussian ? 'en2ru' : 'ru2en');
        
        fetch('/cgi-bin/translate.pl', {
            method: 'POST',
            body: formData
        })
        .then(response => response.text())
        .then(text => {
            document.getElementById('translated_text').value = text;
        });
    }, 500);
}

// Initialize the page when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Set up event listeners
    document.getElementById('source_text').addEventListener('keyup', updateTranslation);
    document.getElementById('switch-btn').addEventListener('click', switchLanguages);
}); 