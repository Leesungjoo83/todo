const todoInput = document.getElementById('todoInput');
const addButton = document.getElementById('addButton');
const todoList = document.getElementById('todoList');
const todoStats = document.getElementById('todoStats');
const clearCompletedBtn = document.getElementById('clearCompleted');

// API 기본 URL
const API_BASE_URL = 'http://localhost:3000/api';

// 할일 목록
let todos = [];
let currentFilter = 'all';
let currentPeriod = 'all';

// API 호출 함수들
async function fetchTodos() {
  try {
    const response = await fetch(`${API_BASE_URL}/todos`);
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.error || '할일 목록을 불러오는데 실패했습니다.');
    }
    todos = await response.json();
    renderTodos();
  } catch (error) {
    console.error('할일 목록 불러오기 오류:', error);
    if (error.message.includes('Failed to fetch') || error.message.includes('네트워크')) {
      alert('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } else if (!error.message.includes('데이터베이스')) {
      console.error('오류:', error.message);
    }
  }
}

async function createTodo(todoData) {
  try {
    const response = await fetch(`${API_BASE_URL}/todos`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(todoData),
    });
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.error || '할일 추가에 실패했습니다.');
    }
    
    await fetchTodos();
  } catch (error) {
    console.error('할일 추가 오류:', error);
    alert(error.message || '할일 추가에 실패했습니다.');
  }
}

async function updateTodo(id, todoData) {
  try {
    const response = await fetch(`${API_BASE_URL}/todos/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(todoData),
    });
    if (!response.ok) throw new Error('할일 수정에 실패했습니다.');
    await fetchTodos();
  } catch (error) {
    console.error('할일 수정 오류:', error);
    alert('할일 수정에 실패했습니다.');
  }
}

async function deleteTodoById(id) {
  try {
    const response = await fetch(`${API_BASE_URL}/todos/${id}`, {
      method: 'DELETE',
    });
    if (!response.ok) throw new Error('할일 삭제에 실패했습니다.');
    await fetchTodos();
  } catch (error) {
    console.error('할일 삭제 오류:', error);
    alert('할일 삭제에 실패했습니다.');
  }
}

async function clearCompletedTodos() {
  try {
    const response = await fetch(`${API_BASE_URL}/todos`, {
      method: 'DELETE',
    });
    if (!response.ok) throw new Error('완료된 할일 삭제에 실패했습니다.');
    await fetchTodos();
  } catch (error) {
    console.error('완료된 할일 삭제 오류:', error);
    alert('완료된 할일 삭제에 실패했습니다.');
  }
}

// 날짜와 시간 포맷팅 함수 (24시간제)
function formatDateTime(timestamp) {
    if (!timestamp) return '';
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}`;
}

// 날짜만 포맷팅 함수
function formatDate(timestamp) {
    if (!timestamp) return '';
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

// 날짜가 지났는지 확인
function isOverdue(dueDate) {
    if (!dueDate) return false;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const due = new Date(dueDate);
    due.setHours(0, 0, 0, 0);
    return due < today;
}

// 텍스트 데이터
const t = {
    title: '📝 할일 목록',
    stats: (total, completed, active) => `전체: ${total} | 완료: ${completed} | 진행중: ${active}`,
    filterAll: '전체',
    filterActive: '진행중',
    filterCompleted: '완료',
    periodAll: '전체 기간',
    periodWeek: '주간',
    periodMonth: '월간',
    placeholder: '할일을 입력하세요...',
    addButton: '+',
    deleteButton: '-',
    clearCompleted: '완료된 항목 모두 삭제',
    saveExcelButton: '📊 엑셀로 저장',
    loadButton: '📂 파일에서 불러오기',
    emptyAll: '할일이 없습니다. 새로운 할일을 추가해보세요!',
    emptyActive: '진행중인 할일이 없습니다.',
    emptyCompleted: '완료된 할일이 없습니다.',
    confirmDelete: '정말 삭제하시겠습니까?',
    confirmClear: (count) => `완료된 ${count}개의 항목을 모두 삭제하시겠습니까?`,
    confirmLoad: (count) => `파일에서 ${count}개의 할일을 불러오시겠습니까? (기존 할일은 유지됩니다)`,
    alertEmpty: '할일을 입력해주세요!',
    alertNoSave: '저장할 할일이 없습니다.',
    alertSaveExcelSuccess: '엑셀 파일이 성공적으로 저장되었습니다!',
    alertLoadSuccess: '파일이 성공적으로 불러와졌습니다!',
    alertLoadError: (msg) => `파일을 읽는 중 오류가 발생했습니다: ${msg}`,
    alertInvalidFile: '잘못된 파일 형식입니다.',
    createdDate: '작성일',
    completedDate: '완료일',
    dueDate: '완료 예정일',
    modifiedDate: '수정일',
    overdue: '지연됨',
    details: '세부내용',
    detailsPlaceholder: '세부내용을 입력하세요...',
    saveDetails: '저장',
    cancelDetails: '취소'
};

// UI 초기화
function initializeUI() {
    document.getElementById('appTitle').textContent = t.title;
    document.getElementById('filterAll').textContent = t.filterAll;
    document.getElementById('filterActive').textContent = t.filterActive;
    document.getElementById('filterCompleted').textContent = t.filterCompleted;
    document.getElementById('periodAll').textContent = t.periodAll;
    document.getElementById('periodWeek').textContent = t.periodWeek;
    document.getElementById('periodMonth').textContent = t.periodMonth;
    document.getElementById('todoInput').placeholder = t.placeholder;
    document.getElementById('addButton').textContent = t.addButton;
    document.getElementById('clearCompleted').textContent = t.clearCompleted;
    document.getElementById('saveExcelButton').textContent = t.saveExcelButton;
    document.getElementById('loadButton').textContent = t.loadButton;
    document.getElementById('dueDateInput').setAttribute('aria-label', t.dueDate);
    document.getElementById('detailsInput').placeholder = t.detailsPlaceholder;
    document.getElementById('detailsEdit').placeholder = t.detailsPlaceholder;
    document.getElementById('modalTitle').textContent = t.details;
    document.querySelector('.save-details-button').textContent = t.saveDetails;
    document.querySelector('.cancel-details-button').textContent = t.cancelDetails;
}

// 통계 업데이트
function updateStats() {
    const total = todos.length;
    const completed = todos.filter(todo => todo.completed).length;
    const active = total - completed;
    
    todoStats.textContent = t.stats(total, completed, active);
    clearCompletedBtn.disabled = completed === 0;
}

// 주간 범위 계산 (월요일~일요일)
function getWeekRange() {
    const today = new Date();
    const day = today.getDay();
    const diff = today.getDate() - day + (day === 0 ? -6 : 1);
    const monday = new Date(today.getFullYear(), today.getMonth(), diff);
    monday.setHours(0, 0, 0, 0);
    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);
    sunday.setHours(23, 59, 59, 999);
    return { start: monday.getTime(), end: sunday.getTime() };
}

// 월간 범위 계산 (이번 달 1일~마지막일)
function getMonthRange() {
    const today = new Date();
    const firstDay = new Date(today.getFullYear(), today.getMonth(), 1);
    firstDay.setHours(0, 0, 0, 0);
    const lastDay = new Date(today.getFullYear(), today.getMonth() + 1, 0);
    lastDay.setHours(23, 59, 59, 999);
    return { start: firstDay.getTime(), end: lastDay.getTime() };
}

// 기간 필터링
function filterByPeriod(todos) {
    if (currentPeriod === 'all') {
        return todos;
    }
    
    let range;
    if (currentPeriod === 'week') {
        range = getWeekRange();
    } else if (currentPeriod === 'month') {
        range = getMonthRange();
    }
    
    return todos.filter(todo => {
        const createdDate = todo.createdDate || 0;
        return createdDate >= range.start && createdDate <= range.end;
    });
}

// 필터링된 할일 목록 가져오기
function getFilteredTodos() {
    let filtered = todos;
    
    // 상태 필터 적용
    switch(currentFilter) {
        case 'active':
            filtered = filtered.filter(todo => !todo.completed);
            break;
        case 'completed':
            filtered = filtered.filter(todo => todo.completed);
            break;
    }
    
    // 기간 필터 적용
    filtered = filterByPeriod(filtered);
    
    return filtered;
}

// 달력 생성
function renderCalendar() {
    todoList.innerHTML = '';
    
    const today = new Date();
    const year = today.getFullYear();
    const month = today.getMonth();
    
    // 이번 달의 첫 번째 날과 마지막 날
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const daysInMonth = lastDay.getDate();
    const startDayOfWeek = firstDay.getDay();
    
    // 필터링된 todo 가져오기
    const filteredTodos = getFilteredTodos();
    
    // 날짜별로 todo 그룹화
    const todosByDate = {};
    filteredTodos.forEach(todo => {
        if (!todo.createdDate) return;
        const date = new Date(todo.createdDate);
        const dateKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
        if (!todosByDate[dateKey]) {
            todosByDate[dateKey] = [];
        }
        todosByDate[dateKey].push(todo);
    });
    
    // 달력 헤더
    const monthNames = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];
    const weekDays = ['일', '월', '화', '수', '목', '금', '토'];
    
    let calendarHTML = `
        <div class="calendar-container">
            <div class="calendar-header">
                <h3>${year}년 ${monthNames[month]}</h3>
            </div>
            <div class="calendar-weekdays">
                ${weekDays.map(day => `<div class="calendar-weekday">${day}</div>`).join('')}
            </div>
            <div class="calendar-grid">
    `;
    
    for (let i = 0; i < startDayOfWeek; i++) {
        calendarHTML += '<div class="calendar-day empty"></div>';
    }
    
    for (let day = 1; day <= daysInMonth; day++) {
        const dateKey = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        const dayTodos = todosByDate[dateKey] || [];
        const isToday = today.getDate() === day && today.getMonth() === month && today.getFullYear() === year;
        
        let dayHTML = `<div class="calendar-day ${isToday ? 'today' : ''}">`;
        dayHTML += `<div class="calendar-day-number">${day}</div>`;
        
        if (dayTodos.length > 0) {
            const sortedTodos = dayTodos.sort((a, b) => {
                if (!a.completed && b.completed) return -1;
                if (a.completed && !b.completed) return 1;
                if (a.completed && b.completed) {
                    return (a.completedDate || 0) - (b.completedDate || 0);
                }
                return 0;
            });
            
            const incompleteTodos = sortedTodos.filter(todo => !todo.completed);
            const completedTodos = sortedTodos.filter(todo => todo.completed).slice(0, 2);
            const displayTodos = [...incompleteTodos, ...completedTodos];
            
            dayHTML += '<div class="calendar-day-todos">';
            displayTodos.forEach(todo => {
                const todoIndex = todos.findIndex(t => t.id === todo.id);
                const completed = todo.completed;
                const overdue = !todo.completed && todo.dueDate && isOverdue(todo.dueDate);
                dayHTML += `
                    <div class="calendar-todo-item ${completed ? 'completed' : ''} ${overdue ? 'overdue' : ''}" onclick="openDetailsModal(${todoIndex})">
                        <span class="calendar-todo-text">${todo.text}</span>
                    </div>
                `;
            });
            dayHTML += '</div>';
        }
        
        dayHTML += '</div>';
        calendarHTML += dayHTML;
    }
    
    calendarHTML += `
            </div>
        </div>
    `;
    
    todoList.innerHTML = calendarHTML;
    updateStats();
}

// 할일 목록 렌더링
function renderTodos() {
    // 월간 필터일 때 달력 형식으로 표시
    if (currentPeriod === 'month') {
        renderCalendar();
        return;
    }
    
    todoList.innerHTML = '';
    
    const filteredTodos = getFilteredTodos();
    
    if (filteredTodos.length === 0) {
        const message = currentFilter === 'all' ? t.emptyAll
            : currentFilter === 'active' ? t.emptyActive
            : t.emptyCompleted;
        todoList.innerHTML = `<li class="empty-message">${message}</li>`;
        updateStats();
        return;
    }

    filteredTodos.forEach((todo) => {
        const li = document.createElement('li');
        li.className = `todo-item ${todo.completed ? 'completed' : ''}`;
        
        const todoIndex = todos.findIndex(t => t.id === todo.id);
        
        // 작성일은 날짜만, 완료일은 시간 포함
        const createdDateStr = formatDate(todo.createdDate);
        const completedDateStr = todo.completedDate ? formatDateTime(todo.completedDate) : '';
        const dueDateStr = todo.dueDate ? formatDate(todo.dueDate) : '';
        const modifiedDateStr = todo.modifiedDate ? formatDateTime(todo.modifiedDate) : '';
        const overdue = !todo.completed && todo.dueDate && isOverdue(todo.dueDate);
        const hasDetails = todo.details && todo.details.trim() !== '';
        
        li.innerHTML = `
            <div class="todo-content">
                <input 
                    type="checkbox" 
                    class="todo-checkbox" 
                    ${todo.completed ? 'checked' : ''}
                    onchange="toggleComplete(${todoIndex})"
                >
                <div class="todo-text-wrapper" onclick="openDetailsModal(${todoIndex})">
                    <span class="todo-text">${todo.text}${hasDetails ? ' <span class="has-details-icon">📄</span>' : ''}</span>
                    <div class="todo-dates">
                        <span class="todo-date created-date">${t.createdDate}: ${createdDateStr}</span>
                        ${dueDateStr ? `<span class="todo-date due-date ${overdue ? 'overdue' : ''}">${t.dueDate}: ${dueDateStr}${overdue ? ` (${t.overdue})` : ''}</span>` : ''}
                        ${modifiedDateStr ? `<span class="todo-date modified-date">${t.modifiedDate}: ${modifiedDateStr}</span>` : ''}
                        ${completedDateStr ? `<span class="todo-date completed-date">${t.completedDate}: ${completedDateStr}</span>` : ''}
                    </div>
                </div>
            </div>
            <button class="delete-button" onclick="deleteTodo(${todoIndex})">${t.deleteButton}</button>
        `;
        
        if (overdue) {
            li.classList.add('overdue-item');
        }
        todoList.appendChild(li);
    });

    updateStats();
}

// 필터 설정
function setFilter(filter) {
    currentFilter = filter;
    document.querySelectorAll('.filter-button').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');
    renderTodos();
}

// 기간 설정
function setPeriod(period) {
    currentPeriod = period;
    document.querySelectorAll('.period-button').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');
    renderTodos();
}

// 완료 상태 토글
async function toggleComplete(index) {
    const todo = todos[index];
    const newCompleted = !todo.completed;
    
    await updateTodo(todo.id, {
        completed: newCompleted
    });
}

// 할일 추가
async function addTodo() {
    const text = todoInput.value.trim();
    const dueDateInput = document.getElementById('dueDateInput');
    const dueDateValue = dueDateInput.value;
    const detailsInput = document.getElementById('detailsInput');
    const detailsValue = detailsInput.value.trim();
    const detailsInputSection = document.getElementById('detailsInputSection');
    
    if (text === '') {
        alert(t.alertEmpty);
        return;
    }

    const dueDate = dueDateValue ? new Date(dueDateValue) : new Date();
    dueDate.setHours(0, 0, 0, 0);

    const newTodo = {
        text: text,
        details: detailsValue || null,
        dueDate: dueDate.getTime()
    };

    await createTodo(newTodo);
    
    todoInput.value = '';
    detailsInput.value = '';
    detailsInputSection.classList.add('hidden');
    dueDateInput.value = formatDateForInput(Date.now());
}

// 세부내용 입력 섹션 토글
function toggleDetailsInput() {
    const detailsInputSection = document.getElementById('detailsInputSection');
    detailsInputSection.classList.toggle('hidden');
}

// 세부내용 모달 열기
let currentEditingIndex = -1;

function openDetailsModal(index) {
    currentEditingIndex = index;
    const todo = todos[index];
    const modal = document.getElementById('detailsModal');
    const detailsEdit = document.getElementById('detailsEdit');
    
    detailsEdit.value = todo.details || '';
    modal.classList.remove('hidden');
}

// 세부내용 모달 닫기
function closeDetailsModal() {
    const modal = document.getElementById('detailsModal');
    modal.classList.add('hidden');
    currentEditingIndex = -1;
}

// 세부내용 저장
async function saveDetails() {
    if (currentEditingIndex === -1) return;
    
    const detailsEdit = document.getElementById('detailsEdit');
    const detailsValue = detailsEdit.value.trim();
    const todo = todos[currentEditingIndex];
    
    await updateTodo(todo.id, {
        details: detailsValue
    });
    
    closeDetailsModal();
}

// 날짜 입력 필드용 포맷팅 (YYYY-MM-DD)
function formatDateForInput(timestamp) {
    if (!timestamp) return '';
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

// 할일 삭제
async function deleteTodo(index) {
    if (confirm(t.confirmDelete)) {
        const todo = todos[index];
        await deleteTodoById(todo.id);
    }
}

// 완료된 항목 모두 삭제
async function clearCompleted() {
    const completedCount = todos.filter(todo => todo.completed).length;
    if (completedCount === 0) return;
    
    if (confirm(t.confirmClear(completedCount))) {
        await clearCompletedTodos();
    }
}

// 엑셀 파일로 저장
function saveToExcel() {
    if (todos.length === 0) {
        alert(t.alertNoSave);
        return;
    }

    const excelData = todos.map(todo => ({
        '할일': todo.text || '',
        '상태': todo.completed ? '완료' : '진행중',
        '작성일': todo.createdDate ? formatDateTime(todo.createdDate) : '',
        '완료 예정일': todo.dueDate ? formatDate(todo.dueDate) : '',
        '완료일': todo.completedDate ? formatDateTime(todo.completedDate) : '',
        '수정일': todo.modifiedDate ? formatDateTime(todo.modifiedDate) : '',
        '세부내용': todo.details || '',
        '지연여부': (!todo.completed && todo.dueDate && isOverdue(todo.dueDate)) ? '지연됨' : ''
    }));

    const wb = XLSX.utils.book_new();
    const ws = XLSX.utils.json_to_sheet(excelData);
    ws['!cols'] = [
        { wch: 30 }, { wch: 10 }, { wch: 20 }, { wch: 15 },
        { wch: 20 }, { wch: 20 }, { wch: 50 }, { wch: 10 }
    ];
    
    XLSX.utils.book_append_sheet(wb, ws, '할일 목록');
    XLSX.writeFile(wb, `todo-list-${new Date().toISOString().split('T')[0]}.xlsx`);
    
    alert(t.alertSaveExcelSuccess);
}

// 파일에서 불러오기
async function loadFromFile(event) {
    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async function(e) {
        try {
            const loadedTodos = JSON.parse(e.target.result);
            
            if (!Array.isArray(loadedTodos)) {
                throw new Error(t.alertInvalidFile);
            }

            if (confirm(t.confirmLoad(loadedTodos.length))) {
                for (const todo of loadedTodos) {
                    let dueDate = null;
                    if (todo.dueDate) {
                        const date = new Date(todo.dueDate);
                        date.setHours(0, 0, 0, 0);
                        dueDate = date.getTime();
                    }
                    
                    await createTodo({
                        text: todo.text,
                        details: todo.details || null,
                        completed: todo.completed || false,
                        dueDate: dueDate
                    });
                }
                alert(t.alertLoadSuccess);
            }
        } catch (error) {
            alert(t.alertLoadError(error.message));
        }
    };
    reader.readAsText(file);
    event.target.value = '';
}

// 추가 버튼 클릭 이벤트
addButton.addEventListener('click', addTodo);

// Enter 키 입력 이벤트
todoInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        addTodo();
    }
});

// 완료 예정일 입력 필드 기본값 설정
const dueDateInput = document.getElementById('dueDateInput');
if (dueDateInput) {
    dueDateInput.value = formatDateForInput(Date.now());
}

// 초기 렌더링
initializeUI();
fetchTodos();

