// Load dictionary content when page loads
function loadDictionary() {
    fetch('/cgi-bin/dict_manage.pl')
        .then(response => response.text())
        .then(html => {
            document.getElementById('dictionary-content').innerHTML = html;
        });
}

// Handle add form submission
function handleAddWord(e) {
    e.preventDefault();
    const form = document.getElementById('add-form');
    const engWord = form.elements['eng_word'].value;
    const rusWord = form.elements['rus_word'].value;
    
    const formData = new FormData();
    formData.append('action', 'add');
    formData.append('eng_word', engWord);
    formData.append('rus_word', rusWord);
    
    fetch('/cgi-bin/dict_manage.pl', {
        method: 'POST',
        body: formData
    })
    .then(response => response.text())
    .then(html => {
        document.getElementById('dictionary-content').innerHTML = html;
        form.reset();
        
        const successMsg = document.getElementById('success-message');
        successMsg.textContent = `Word "${engWord}" added successfully!`;
        successMsg.style.display = 'block';
        
        setTimeout(() => {
            successMsg.style.display = 'none';
        }, 3000);
    });
}

// Handle delete form submission
function handleDeleteWord(e) {
    e.preventDefault();
    const form = document.getElementById('delete-form');
    const engWord = form.elements['eng_word'].value;
    
    deleteWord(engWord);
}

// Function to delete a word (used by both form and table buttons)
function deleteWord(engWord) {
    const formData = new FormData();
    formData.append('action', 'delete');
    formData.append('eng_word', engWord);
    
    fetch('/cgi-bin/dict_manage.pl', {
        method: 'POST',
        body: formData
    })
    .then(response => response.text())
    .then(html => {
        document.getElementById('dictionary-content').innerHTML = html;
        
        const form = document.getElementById('delete-form');
        if (form.elements['eng_word'].value === engWord) {
            form.reset();
        }
        
        const successMsg = document.getElementById('success-message');
        successMsg.textContent = `Word "${engWord}" deleted successfully!`;
        successMsg.style.display = 'block';
        
        setTimeout(() => {
            successMsg.style.display = 'none';
        }, 3000);
    });
}

// Handle search form submission
function handleSearch() {
    const searchTerm = document.getElementById('dictionary-search').value;
    
    const url = `/cgi-bin/dict_manage.pl?search=${encodeURIComponent(searchTerm)}`;
    
    fetch(url)
        .then(response => response.text())
        .then(html => {
            document.getElementById('dictionary-content').innerHTML = html;
        });
}

// Initialize the page when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    loadDictionary();
    
    document.getElementById('add-form').addEventListener('submit', handleAddWord);
    document.getElementById('delete-form').addEventListener('submit', handleDeleteWord);
    
    const searchBtn = document.getElementById('search-btn');
    if (searchBtn) {
        searchBtn.addEventListener('click', handleSearch);
    }
    
    const searchInput = document.getElementById('dictionary-search');
    if (searchInput) {
        searchInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                handleSearch();
            }
        });
    }
});

window.deleteWord = deleteWord; 