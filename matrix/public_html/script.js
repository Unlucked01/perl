document.addEventListener('DOMContentLoaded', function() {
    // Глобальные переменные для хранения матриц
    let matrixA = null;
    let matrixB = null;
    
    // Добавим глобальные переменные для отслеживания редактируемой матрицы
    let editingMatrix = null; // 'A' или 'B'
    let modal = null;
    
    // Обработчики событий для элементов формы
    document.getElementById('rows').addEventListener('change', updateManualInputForm);
    document.getElementById('cols').addEventListener('change', updateManualInputForm);
    document.getElementById('rows-b').addEventListener('change', updateManualInputFormB);
    document.getElementById('cols-b').addEventListener('change', updateManualInputFormB);
    
    // Обработчики для радио-кнопок
    const fillTypeRadios = document.querySelectorAll('input[name="fill-type"]');
    fillTypeRadios.forEach(radio => {
        radio.addEventListener('change', function() {
            if (this.value === 'manual') {
                document.getElementById('manual-input').classList.remove('hidden');
                updateManualInputForm();
            } else {
                document.getElementById('manual-input').classList.add('hidden');
            }
        });
    });
    
    const fillTypeBRadios = document.querySelectorAll('input[name="fill-type-b"]');
    fillTypeBRadios.forEach(radio => {
        radio.addEventListener('change', function() {
            if (this.value === 'manual') {
                document.getElementById('manual-input-b').classList.remove('hidden');
                updateManualInputFormB();
            } else {
                document.getElementById('manual-input-b').classList.add('hidden');
            }
        });
    });
    
    // Обработчики для кнопок
    document.getElementById('create-matrix').addEventListener('click', createMatrixA);
    document.getElementById('show-matrix-b-form').addEventListener('click', function() {
        document.getElementById('matrix-b-form').classList.remove('hidden');
        this.style.display = 'none';
    });
    document.getElementById('create-matrix-b').addEventListener('click', createMatrixB);
    
    // Обработчики для операций с матрицами
    document.getElementById('transpose').addEventListener('click', transposeMatrix);
    document.getElementById('min-max').addEventListener('click', findMinMax);
    document.getElementById('inverse').addEventListener('click', inverseMatrix);
    document.getElementById('add').addEventListener('click', addMatrices);
    document.getElementById('multiply').addEventListener('click', multiplyMatrices);
    
    // Обработчики для кнопок очистки
    document.getElementById('clear-matrix-a').addEventListener('click', clearMatrixA);
    document.getElementById('clear-matrix-b').addEventListener('click', clearMatrixB);
    document.getElementById('clear-result').addEventListener('click', clearResult);
    
    // Добавим обработчики событий для кнопок редактирования
    document.getElementById('edit-matrix-a').addEventListener('click', function() {
        openEditModal('A');
    });

    document.getElementById('edit-matrix-b').addEventListener('click', function() {
        openEditModal('B');
    });
    
    // Инициализация модального окна
    modal = document.getElementById('edit-modal');
    
    // Закрытие модального окна при клике на крестик
    document.querySelector('.close').addEventListener('click', function() {
        modal.style.display = 'none';
    });
    
    // Закрытие модального окна при клике вне его области
    window.addEventListener('click', function(event) {
        if (event.target === modal) {
            modal.style.display = 'none';
        }
    });
    
    // Сохранение изменений
    document.getElementById('save-matrix-edit').addEventListener('click', saveMatrixEdit);
    
    // Функция для создания формы ручного ввода матрицы A
    function updateManualInputForm() {
        const rows = parseInt(document.getElementById('rows').value);
        const cols = parseInt(document.getElementById('cols').value);
        const container = document.getElementById('matrix-input-container');
        
        let html = '<table>';
        for (let i = 0; i < rows; i++) {
            html += '<tr>';
            for (let j = 0; j < cols; j++) {
                html += `<td><input type="number" step="any" id="cell_${i}_${j}" name="cell_${i}_${j}" value="0"></td>`;
            }
            html += '</tr>';
        }
        html += '</table>';
        
        container.innerHTML = html;
    }
    
    // Функция для создания формы ручного ввода матрицы B
    function updateManualInputFormB() {
        const rows = parseInt(document.getElementById('rows-b').value);
        const cols = parseInt(document.getElementById('cols-b').value);
        const container = document.getElementById('matrix-input-container-b');
        
        let html = '<table>';
        for (let i = 0; i < rows; i++) {
            html += '<tr>';
            for (let j = 0; j < cols; j++) {
                html += `<td><input type="number" step="any" id="cell_b_${i}_${j}" name="cell_b_${i}_${j}" value="0"></td>`;
            }
            html += '</tr>';
        }
        html += '</table>';
        
        container.innerHTML = html;
    }
    
    // Функция для создания матрицы A
    function createMatrixA() {
        const rows = parseInt(document.getElementById('rows').value);
        const cols = parseInt(document.getElementById('cols').value);
        const fillType = document.querySelector('input[name="fill-type"]:checked').value;
        
        // Проверка ограничений
        if (rows > 10 || cols > 10) {
            showError('Максимальный размер матрицы: 10x10');
            return;
        }
        
        const formData = new FormData();
        formData.append('action', 'create');
        formData.append('rows', rows);
        formData.append('cols', cols);
        formData.append('fill_type', fillType);
        
        if (fillType === 'manual') {
            for (let i = 0; i < rows; i++) {
                for (let j = 0; j < cols; j++) {
                    const value = document.getElementById(`cell_${i}_${j}`).value;
                    formData.append(`cell_${i}_${j}`, value);
                }
            }
        }
        
        fetch('/cgi-bin/matrix.pl', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                // Сохраняем матрицу в глобальную переменную
                matrixA = data.data.matrix;
                
                // Обновляем отображение
                document.getElementById('matrix-a-display').innerHTML = data.data.html;
                
                // Скрываем блок создания и показываем блок операций
                document.querySelector('.left-panel .section:first-child').style.display = 'none';
                document.getElementById('matrix-operations').style.display = 'block';
                
                showResult('Матрица A создана:', data.data.html);
                hideError();
            } else {
                showError(data.message);
            }
        })
        .catch(error => {
            showError('Произошла ошибка при создании матрицы: ' + error);
        });
    }
    
    // Функция для создания матрицы B
    function createMatrixB() {
        const rows = parseInt(document.getElementById('rows-b').value);
        const cols = parseInt(document.getElementById('cols-b').value);
        const fillType = document.querySelector('input[name="fill-type-b"]:checked').value;
        
        // Формируем данные для отправки
        const formData = new FormData();
        formData.append('action', 'create');
        formData.append('rows', rows);
        formData.append('cols', cols);
        formData.append('fill_type', fillType);
        
        // Если выбран ручной ввод, добавляем значения ячеек
        if (fillType === 'manual') {
            for (let i = 0; i < rows; i++) {
                for (let j = 0; j < cols; j++) {
                    const value = document.getElementById(`cell_b_${i}_${j}`).value;
                    formData.append(`cell_${i}_${j}`, value);
                }
            }
        }
        
        // Отправляем запрос на сервер
        fetch('/cgi-bin/matrix.pl', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                matrixB = data.data.matrix;
                document.getElementById('matrix-b-display').innerHTML = data.data.html;
                document.getElementById('matrix-b-display-container').classList.remove('hidden');
                document.getElementById('matrix-b-form').classList.add('hidden');
                showResult('Матрица B создана:', data.data.html);
                hideError();
            } else {
                showError(data.message);
            }
        })
        .catch(error => {
            showError('Произошла ошибка при создании матрицы: ' + error);
        });
    }
    
    // Функция для транспонирования матрицы
    function transposeMatrix() {
        if (!matrixA) {
            showError('Сначала создайте матрицу A');
            return;
        }
        
        const formData = new FormData();
        formData.append('action', 'transpose');
        formData.append('matrix', JSON.stringify(matrixA));
        
        fetch('/cgi-bin/matrix.pl', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                // Получаем HTML исходной матрицы
                const matrixAHtml = document.getElementById('matrix-a-display').innerHTML;
                
                // Формируем HTML с исходной и транспонированной матрицами
                const resultHtml = `
                    <div class="operation-result">
                        <div class="operation-row">
                            <div class="matrix-block">
                                <h4>Исходная матрица A:</h4>
                                ${matrixAHtml}
                            </div>
                            <div class="operation-symbol">→</div>
                            <div class="matrix-block">
                                <h4>Транспонированная матрица:</h4>
                                ${data.data.html}
                            </div>
                        </div>
                    </div>
                `;
                
                showResult('Транспонирование матрицы:', resultHtml);
                hideError();
            } else {
                showError(data.message);
            }
        })
        .catch(error => {
            showError('Произошла ошибка при транспонировании матрицы: ' + error);
        });
    }
    
    // Функция для нахождения минимального и максимального элементов
    function findMinMax() {
        if (!matrixA) {
            showError('Сначала создайте матрицу A');
            return;
        }
        
        const formData = new FormData();
        formData.append('action', 'min_max');
        formData.append('matrix', JSON.stringify(matrixA));
        
        fetch('/cgi-bin/matrix.pl', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                // Получаем HTML исходной матрицы
                const matrixAHtml = document.getElementById('matrix-a-display').innerHTML;
                
                // Формируем HTML с исходной матрицей и результатами
                const resultHtml = `
                    <div class="operation-result">
                        <div class="matrix-block">
                            <h4>Матрица A:</h4>
                            ${matrixAHtml}
                        </div>
                        <div class="min-max-result">
                            <p><strong>Минимальный элемент:</strong> ${data.data.min}</p>
                            <p><strong>Максимальный элемент:</strong> ${data.data.max}</p>
                        </div>
                    </div>
                `;
                
                showResult('Минимальный и максимальный элементы:', resultHtml);
                hideError();
            } else {
                showError(data.message);
            }
        })
        .catch(error => {
            showError('Произошла ошибка при поиске мин/макс элементов: ' + error);
        });
    }
    
    // Функция для вычисления обратной матрицы
    function inverseMatrix() {
        if (!matrixA) {
            showError('Сначала создайте матрицу A');
            return;
        }
        
        const formData = new FormData();
        formData.append('action', 'inverse');
        formData.append('matrix', JSON.stringify(matrixA));
        
        fetch('/cgi-bin/matrix.pl', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                // Получаем HTML исходной матрицы
                const matrixAHtml = document.getElementById('matrix-a-display').innerHTML;
                
                // Формируем HTML с исходной и обратной матрицами
                const resultHtml = `
                    <div class="operation-result">
                        <div class="operation-row">
                            <div class="matrix-block">
                                <h4>Исходная матрица A:</h4>
                                ${matrixAHtml}
                            </div>
                            <div class="operation-symbol">→</div>
                            <div class="matrix-block">
                                <h4>Обратная матрица:</h4>
                                ${data.data.html}
                            </div>
                        </div>
                    </div>
                `;
                
                showResult('Обратная матрица:', resultHtml);
                hideError();
            } else {
                showError(data.message);
            }
        })
        .catch(error => {
            showError('Произошла ошибка при вычислении обратной матрицы: ' + error);
        });
    }
    
    // Функция для сложения матриц
    function addMatrices() {
        if (!matrixA || !matrixB) {
            showError('Сначала создайте обе матрицы A и B');
            return;
        }
        
        const formData = new FormData();
        formData.append('action', 'add');
        formData.append('matrix1', JSON.stringify(matrixA));
        formData.append('matrix2', JSON.stringify(matrixB));
        
        fetch('/cgi-bin/matrix.pl', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                // Получаем HTML исходных матриц
                const matrixAHtml = document.getElementById('matrix-a-display').innerHTML;
                const matrixBHtml = document.getElementById('matrix-b-display').innerHTML;
                
                // Формируем HTML с исходными матрицами и результатом
                const resultHtml = `
                    <div class="operation-result">
                        <div class="operation-row">
                            <div class="matrix-block">
                                <h4>Матрица A:</h4>
                                ${matrixAHtml}
                            </div>
                            <div class="operation-symbol">+</div>
                            <div class="matrix-block">
                                <h4>Матрица B:</h4>
                                ${matrixBHtml}
                            </div>
                            <div class="operation-symbol">=</div>
                            <div class="matrix-block">
                                <h4>Результат:</h4>
                                ${data.data.html}
                            </div>
                        </div>
                    </div>
                `;
                
                showResult('Сложение матриц A + B:', resultHtml);
                hideError();
            } else {
                showError(data.message);
            }
        })
        .catch(error => {
            showError('Произошла ошибка при сложении матриц: ' + error);
        });
    }
    
    // Функция для умножения матриц
    function multiplyMatrices() {
        if (!matrixA || !matrixB) {
            showError('Сначала создайте обе матрицы A и B');
            return;
        }
        
        const formData = new FormData();
        formData.append('action', 'multiply');
        formData.append('matrix1', JSON.stringify(matrixA));
        formData.append('matrix2', JSON.stringify(matrixB));
        
        fetch('/cgi-bin/matrix.pl', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                // Получаем HTML исходных матриц
                const matrixAHtml = document.getElementById('matrix-a-display').innerHTML;
                const matrixBHtml = document.getElementById('matrix-b-display').innerHTML;
                
                // Формируем HTML с исходными матрицами и результатом
                const resultHtml = `
                    <div class="operation-result">
                        <div class="operation-row">
                            <div class="matrix-block">
                                <h4>Матрица A:</h4>
                                ${matrixAHtml}
                            </div>
                            <div class="operation-symbol">×</div>
                            <div class="matrix-block">
                                <h4>Матрица B:</h4>
                                ${matrixBHtml}
                            </div>
                            <div class="operation-symbol">=</div>
                            <div class="matrix-block">
                                <h4>Результат:</h4>
                                ${data.data.html}
                            </div>
                        </div>
                    </div>
                `;
                
                showResult('Умножение матриц A × B:', resultHtml);
                hideError();
            } else {
                showError(data.message);
            }
        })
        .catch(error => {
            showError('Произошла ошибка при умножении матриц: ' + error);
        });
    }
    
    // Функция для очистки матрицы A
    function clearMatrixA() {
        matrixA = null;
        document.getElementById('matrix-a-display').innerHTML = '';
        document.getElementById('matrix-b-display-container').classList.add('hidden');
        document.getElementById('show-matrix-b-form').style.display = 'block';
        document.getElementById('matrix-b-form').classList.add('hidden');
        
        // Показываем блок создания матрицы A
        document.querySelector('.left-panel .section:first-child').style.display = 'block';
        document.getElementById('matrix-operations').style.display = 'none';
        
        showResult('Матрица A очищена', '<p>Создайте новую матрицу A для продолжения работы.</p>');
    }
    
    // Функция для очистки матрицы B
    function clearMatrixB() {
        matrixB = null;
        document.getElementById('matrix-b-display').innerHTML = '';
        document.getElementById('matrix-b-display-container').classList.add('hidden');
        document.getElementById('show-matrix-b-form').style.display = 'block';
        showResult('Матрица B очищена', '<p>Создайте новую матрицу B для операций с двумя матрицами.</p>');
    }
    
    // Функция для очистки результата
    function clearResult() {
        document.getElementById('result-container').innerHTML = '<p class="placeholder-text">Здесь будет отображаться результат операций с матрицами.</p>';
        hideError();
    }
    
    // Вспомогательные функции
    function showResult(title, html) {
        const resultContainer = document.getElementById('result-container');
        resultContainer.innerHTML = `<h3>${title}</h3>${html}`;
    }
    
    function showError(message) {
        const errorContainer = document.getElementById('error-container');
        errorContainer.textContent = message;
        errorContainer.style.display = 'block';
    }
    
    function hideError() {
        document.getElementById('error-container').style.display = 'none';
    }

    // Функция открытия модального окна для редактирования
    function openEditModal(matrixType) {
        editingMatrix = matrixType;
        const matrix = matrixType === 'A' ? matrixA : matrixB;
        
        if (!matrix) {
            showError(`Матрица ${matrixType} не создана`);
            return;
        }
        
        const container = document.getElementById('edit-matrix-container');
        let html = '<table>';
        
        for (let i = 0; i < matrix.length; i++) {
            html += '<tr>';
            for (let j = 0; j < matrix[i].length; j++) {
                html += `<td><input type="number" step="any" id="edit_cell_${i}_${j}" value="${matrix[i][j]}"></td>`;
            }
            html += '</tr>';
        }
        
        html += '</table>';
        container.innerHTML = html;
        
        // Отображаем модальное окно
        modal.style.display = 'block';
    }

    // Функция сохранения изменений в матрице
    function saveMatrixEdit() {
        const matrix = editingMatrix === 'A' ? matrixA : matrixB;
        
        if (!matrix) {
            showError(`Ошибка: матрица ${editingMatrix} не найдена`);
            return;
        }
        
        // Собираем данные из формы
        for (let i = 0; i < matrix.length; i++) {
            for (let j = 0; j < matrix[i].length; j++) {
                const input = document.getElementById(`edit_cell_${i}_${j}`);
                matrix[i][j] = parseFloat(input.value) || 0;
            }
        }
        
        // Обновляем отображение матрицы
        updateMatrixDisplay(editingMatrix);
        
        // Закрываем модальное окно
        modal.style.display = 'none';
        
        showResult(`Матрица ${editingMatrix} обновлена`, 
            `<p>Матрица ${editingMatrix} была успешно отредактирована.</p>`);
    }

    // Функция обновления отображения матрицы
    function updateMatrixDisplay(matrixType) {
        const matrix = matrixType === 'A' ? matrixA : matrixB;
        const displayId = matrixType === 'A' ? 'matrix-a-display' : 'matrix-b-display';
        
        // Формируем HTML для отображения матрицы
        let html = '<table class="matrix">';
        for (let i = 0; i < matrix.length; i++) {
            html += '<tr>';
            for (let j = 0; j < matrix[i].length; j++) {
                html += `<td>${matrix[i][j]}</td>`;
            }
            html += '</tr>';
        }
        html += '</table>';
        
        document.getElementById(displayId).innerHTML = html;
    }
}); 