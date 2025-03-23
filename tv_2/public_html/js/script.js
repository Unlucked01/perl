// Функция для переключения вкладок в админке
function switchTab(tabId) {
    // Скрываем все вкладки
    const tabContents = document.querySelectorAll('.tab-content');
    tabContents.forEach(tab => {
        tab.style.display = 'none';
    });
    
    // Убираем активный класс со всех кнопок вкладок
    const tabButtons = document.querySelectorAll('.admin-tab');
    tabButtons.forEach(button => {
        button.classList.remove('active');
    });
    
    // Показываем выбранную вкладку и делаем кнопку активной
    document.getElementById(tabId).style.display = 'block';
    document.querySelector(`[data-tab="${tabId}"]`).classList.add('active');
}

// Функция для фильтрации программы передач
function filterPrograms() {
    const date = document.getElementById('date').value;
    const channel = document.getElementById('channel').value;
    const category = document.getElementById('category').value;
    const timeFrom = document.getElementById('time-from').value;
    const timeTo = document.getElementById('time-to').value;
    
    // Формируем URL с параметрами фильтрации
    let url = `/cgi-bin/programs.pl?`;
    if (channel) url += `channel=${channel}&`;
    if (date) url += `date=${date}&`;
    if (category) url += `category=${category}&`;
    if (timeFrom) url += `time_from=${timeFrom}&`;
    if (timeTo) url += `time_to=${timeTo}&`;
    
    // Перенаправляем на страницу с фильтрами
    window.location.href = url;
}

// Функция для подтверждения удаления
function confirmDelete(type, id, name) {
    if (confirm(`Вы уверены, что хотите удалить ${type} "${name}"?`)) {
        window.location.href = `/cgi-bin/admin.pl?action=delete_${type}&id=${id}`;
    }
}

// Функция для предварительного просмотра изображения
function previewImage(input, previewId) {
    if (input.files && input.files[0]) {
        const reader = new FileReader();
        
        reader.onload = function(e) {
            document.getElementById(previewId).src = e.target.result;
            document.getElementById(previewId).style.display = 'block';
        }
        
        reader.readAsDataURL(input.files[0]);
    }
}

// Инициализация при загрузке страницы
document.addEventListener('DOMContentLoaded', function() {
    // Инициализация вкладок в админке, если они есть
    const adminTabs = document.querySelectorAll('.admin-tab');
    if (adminTabs.length > 0) {
        // Активируем первую вкладку по умолчанию
        const firstTabId = adminTabs[0].getAttribute('data-tab');
        switchTab(firstTabId);
        
        // Добавляем обработчики событий для вкладок
        adminTabs.forEach(tab => {
            tab.addEventListener('click', function() {
                const tabId = this.getAttribute('data-tab');
                switchTab(tabId);
            });
        });
    }
    
    // Инициализация формы фильтрации, если она есть
    const filterForm = document.getElementById('filter-form');
    if (filterForm) {
        filterForm.addEventListener('submit', function(e) {
            e.preventDefault();
            filterPrograms();
        });
    }
    
    // Инициализация предпросмотра изображений
    const imageInputs = document.querySelectorAll('.image-input');
    imageInputs.forEach(input => {
        input.addEventListener('change', function() {
            const previewId = this.getAttribute('data-preview');
            previewImage(this, previewId);
        });
    });
});

// Функция для прокрутки к верху страницы
function scrollToTop() {
    window.scrollTo({
        top: 0,
        behavior: 'smooth'
    });
}

// Функция для прокрутки к низу страницы
function scrollToBottom() {
    window.scrollTo({
        top: document.body.scrollHeight,
        behavior: 'smooth'
    });
} 