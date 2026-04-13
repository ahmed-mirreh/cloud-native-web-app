// Global state
let selectedPlayers = {};
let currentSlot = null;
let dailyChallenge = {
    points: 130,
    rebounds: 35,
    assists: 25
};

// Timer state
let startTime = null;
let timerInterval = null;

// NBA players data - will be loaded from database
let availablePlayers = [];

// Backend API configuration - will be set by config.js
const API_BASE_URL = window.API_BASE_URL || 'http://localhost:8000';

// Mock leaderboard data - will be empty initially
let todaysLeaderboard = [];

// API Functions
async function loadPlayersFromDatabase() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/players`);
        
        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(`Error ${response.status}: ${errorData.detail}`);
        }
        
        const data = await response.json();
        // Convert database format to frontend format
        availablePlayers = data.players.map(player => ({
            name: player.player_name,
            team: player.team,
            photo: player.photo_url
        }));
        return availablePlayers;
    } catch (error) {
        console.error("Failed to load players:", error.message);
        showResultMessage("Could not load players. Please try again.", 'error');
        return [];
    }
}

async function getLeaderboard() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/leaderboard`);
        
        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(`Error ${response.status}: ${errorData.detail}`);
        }
        
        const data = await response.json();
        return data.leaderboard || [];
    } catch (error) {
        console.error("Failed to get leaderboard:", error.message);
        showResultMessage("Could not load leaderboard. Please try again.", 'error');
        return [];
    }
}

async function getPlayerStats(playerName) {
    try {
        // Convert "FirstName LastName" to "LastName_FirstName" for API call
        const nameParts = playerName.trim().split(/\s+/);
        const formattedName = nameParts.length >= 2 
            ? `${nameParts[nameParts.length - 1]}_${nameParts.slice(0, -1).join('_')}`
            : playerName.replace(/\s+/g, '_');
        const response = await fetch(`${API_BASE_URL}/api/stats/${formattedName}`);
        
        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(`Error ${response.status}: ${errorData.detail}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error("Failed to get player stats:", error.message);
        showResultMessage(`Could not load stats for ${playerName}. Please try again.`, 'error');
        return null;
    }
}

async function submitScoreToLeaderboard(username, completionTime) {
    try {
        const response = await fetch(`${API_BASE_URL}/api/leaderboard`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                user_name: username,
                completion_time: completionTime
            })
        });
        
        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(`Error ${response.status}: ${errorData.detail}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error("Failed to submit score:", error.message);
        showResultMessage("Could not submit score to leaderboard. Please try again.", 'error');
        return null;
    }
}

// Initialize the app
document.addEventListener('DOMContentLoaded', async function() {
    loadDailyChallenge();
    updateTotals();
    
    try {
        await loadPlayersFromDatabase(); // Load players from database first
    } catch (error) {
        console.error("Failed to load players, app may not work properly:", error);
        // Fallback: continue without players loaded
    }
    
    try {
        await loadLeaderboardFromBackend();
    } catch (error) {
        console.error("Failed to load leaderboard:", error);
        // Continue even if leaderboard fails
    }
    
    startTimer();
});

// Load daily challenge targets
function loadDailyChallenge() {
    document.getElementById('target-points').textContent = dailyChallenge.points;
    document.getElementById('target-rebounds').textContent = dailyChallenge.rebounds;
    document.getElementById('target-assists').textContent = dailyChallenge.assists;
}

// Timer functions
function startTimer() {
    startTime = Date.now();
    timerInterval = setInterval(updateTimerDisplay, 1000);
}

function updateTimerDisplay() {
    if (startTime) {
        const elapsed = Math.floor((Date.now() - startTime) / 1000);
        const minutes = Math.floor(elapsed / 60);
        const seconds = elapsed % 60;
        const timeString = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        
        // Update timer display (we'll need to add this to HTML)
        const timerElement = document.getElementById('timer-display');
        if (timerElement) {
            timerElement.textContent = timeString;
        }
    }
}

function stopTimer() {
    if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
    }
}

function getElapsedTime() {
    if (startTime) {
        return Math.floor((Date.now() - startTime) / 1000);
    }
    return 0;
}

// Show player search modal
function showPlayerSearch(slot) {
    currentSlot = slot;
    document.getElementById('player-search-modal').style.display = 'block';
    document.getElementById('player-search').value = '';
    displaySearchResults(availablePlayers);
}

// Close player search modal
function closePlayerSearch() {
    document.getElementById('player-search-modal').style.display = 'none';
    currentSlot = null;
}

// Search players
function searchPlayers() {
    const searchTerm = document.getElementById('player-search').value.toLowerCase();
    const filteredPlayers = availablePlayers.filter(player => 
        player.name.toLowerCase().includes(searchTerm) ||
        player.team.toLowerCase().includes(searchTerm)
    );
    displaySearchResults(filteredPlayers);
}

// Display search results
function displaySearchResults(players) {
    const resultsContainer = document.getElementById('search-results');
    resultsContainer.innerHTML = '';

    players.forEach(player => {
        const resultItem = document.createElement('div');
        resultItem.className = 'search-result-item';
        resultItem.onclick = () => selectPlayer(player);
        
        resultItem.innerHTML = `
            <img src="${player.photo}" alt="${player.name}" class="search-result-photo" 
                 onerror="this.src='https://via.placeholder.com/50x50?text=NBA'">
            <div class="search-result-info">
                <div class="search-result-name">${player.name}</div>
                <div class="search-result-team">${player.team}</div>
            </div>
        `;
        
        resultsContainer.appendChild(resultItem);
    });
}

// Select a player for the current slot
async function selectPlayer(player) {
    if (currentSlot) {
        // Check if player is already selected in another slot
        const isPlayerAlreadySelected = Object.values(selectedPlayers).some(selectedPlayer => 
            selectedPlayer.name === player.name
        );
        
        if (isPlayerAlreadySelected) {
            showResultMessage('This player is already selected!', 'error');
            return;
        }
        
        // Show loading overlay
        showLoadingOverlay();
        
        try {
            // Fetch real stats from backend
            const realStats = await getPlayerStats(player.name);
            
            if (realStats) {
                // Update player object with real stats
                const playerWithRealStats = {
                    ...player,
                    points: realStats.points,
                    rebounds: realStats.rebounds,
                    assists: realStats.assists
                };
                
                selectedPlayers[currentSlot] = playerWithRealStats;
                updatePlayerSlot(currentSlot, playerWithRealStats);
                updateTotals();
                closePlayerSearch();
            } else {
                // Show error if API fails
                showResultMessage('Failed to load stats. Please try again.', 'error');
            }
        } catch (error) {
            console.error('Error loading player stats:', error);
            showResultMessage('Failed to load stats. Please try again.', 'error');
        } finally {
            // Always hide loading overlay
            hideLoadingOverlay();
        }
    }
}

// Update player slot display
function updatePlayerSlot(slot, player) {
    const slotElement = document.querySelector(`[data-slot="${slot}"] .player-card`);
    slotElement.className = 'player-card';
    slotElement.innerHTML = `
        <div class="player-info">
            <img src="${player.photo}" alt="${player.name}" class="player-photo"
                 onerror="this.src='https://via.placeholder.com/60x60?text=NBA'">
            <div class="player-details">
                <div class="player-name">${player.name}</div>
                <div class="player-team">${player.team}</div>
            </div>
        </div>
        <div class="player-stats">
            <div class="stat-item">
                <span class="stat-label">Points</span>
                <span class="stat-value">${player.points}</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Rebounds</span>
                <span class="stat-value">${player.rebounds}</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Assists</span>
                <span class="stat-value">${player.assists}</span>
            </div>
        </div>
        <button class="remove-player-btn" onclick="removePlayer(${slot})">Remove</button>
    `;
}

// Remove player from slot
function removePlayer(slot) {
    delete selectedPlayers[slot];
    const slotElement = document.querySelector(`[data-slot="${slot}"] .player-card`);
    slotElement.className = 'player-card empty';
    slotElement.innerHTML = `
        <button class="add-player-btn" onclick="showPlayerSearch(${slot})">+ Add Player</button>
        <div class="player-stats">
            <div class="stat-item">
                <span class="stat-label">Points</span>
                <span class="stat-value empty">--</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Rebounds</span>
                <span class="stat-value empty">--</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Assists</span>
                <span class="stat-value empty">--</span>
            </div>
        </div>
    `;
    updateTotals();
}

// Update current totals
function updateTotals() {
    let totalPoints = 0;
    let totalRebounds = 0;
    let totalAssists = 0;

    Object.values(selectedPlayers).forEach(player => {
        totalPoints += player.points;
        totalRebounds += player.rebounds;
        totalAssists += player.assists;
    });

    document.getElementById('current-points').textContent = totalPoints.toFixed(1);
    document.getElementById('current-rebounds').textContent = totalRebounds.toFixed(1);
    document.getElementById('current-assists').textContent = totalAssists.toFixed(1);

    // Enable/disable submit button
    const submitBtn = document.getElementById('submit-btn');
    const selectedCount = Object.keys(selectedPlayers).length;
    submitBtn.disabled = selectedCount !== 5;
}

// Submit solution
function submitSolution() {
    const selectedCount = Object.keys(selectedPlayers).length;
    if (selectedCount !== 5) {
        showResultMessage('Please select 5 players before submitting!', 'error');
        return;
    }

    // Calculate totals
    let totalPoints = 0;
    let totalRebounds = 0;
    let totalAssists = 0;

    Object.values(selectedPlayers).forEach(player => {
        totalPoints += player.points;
        totalRebounds += player.rebounds;
        totalAssists += player.assists;
    });

    // Check if solution meets or exceeds targets
    const pointsMatch = totalPoints >= dailyChallenge.points;
    const reboundsMatch = totalRebounds >= dailyChallenge.rebounds;
    const assistsMatch = totalAssists >= dailyChallenge.assists;

    if (pointsMatch && reboundsMatch && assistsMatch) {
        // Success! Stop the timer
        stopTimer();
        const timeElapsed = getElapsedTime();
        const minutes = Math.floor(timeElapsed / 60);
        const seconds = timeElapsed % 60;
        showResultMessage(`🎉 Congratulations, You Win! 🏆✨`, 'success');
        setTimeout(() => {
            document.getElementById('username-modal').style.display = 'block';
        }, 2000);
    } else {
        // Generate detailed feedback
        let feedback = "Close! ";
        const pointsDiff = dailyChallenge.points - totalPoints;
        const reboundsDiff = dailyChallenge.rebounds - totalRebounds;
        const assistsDiff = dailyChallenge.assists - totalAssists;

        const messages = [];
        
        if (pointsDiff > 0) {
            messages.push(`You need ${pointsDiff.toFixed(1)} more points`);
        }
        
        if (reboundsDiff > 0) {
            messages.push(`${reboundsDiff.toFixed(1)} more rebounds`);
        }
        
        if (assistsDiff > 0) {
            messages.push(`${assistsDiff.toFixed(1)} more assists`);
        }

        if (messages.length > 0) {
            feedback += messages.join(", but ") + ".";
        }

        showResultMessage(feedback, 'error');
    }
}

// Clear team
function clearTeam() {
    selectedPlayers = {};
    for (let i = 1; i <= 5; i++) {
        const slotElement = document.querySelector(`[data-slot="${i}"] .player-card`);
        slotElement.className = 'player-card empty';
        slotElement.innerHTML = `
            <button class="add-player-btn" onclick="showPlayerSearch(${i})">+ Add Player</button>
            <div class="player-stats">
                <div class="stat-item">
                    <span class="stat-label">Points</span>
                    <span class="stat-value empty">--</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">Rebounds</span>
                    <span class="stat-value empty">--</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">Assists</span>
                    <span class="stat-value empty">--</span>
                </div>
            </div>
        `;
    }
    updateTotals();
}

// Show/hide loading overlay
function showLoadingOverlay() {
    document.getElementById('loading-overlay').style.display = 'flex';
}

function hideLoadingOverlay() {
    document.getElementById('loading-overlay').style.display = 'none';
}

// Show result message
function showResultMessage(message, type) {
    const messageElement = document.getElementById('result-message');
    messageElement.textContent = message;
    messageElement.className = `result-message ${type}`;
    messageElement.style.display = 'block';
    
    setTimeout(() => {
        messageElement.style.display = 'none';
    }, 1500);
}

// Submit to leaderboard
async function submitToLeaderboard() {
    const username = document.getElementById('username-input').value.trim();
    if (!username) {
        alert('Please enter a username!');
        return;
    }

    // Submit to backend with time in seconds
    const timeElapsed = getElapsedTime();
    const result = await submitScoreToLeaderboard(username, timeElapsed);
    
    if (result) {
        closeUsernameModal();
        showResultMessage('Score submitted successfully! This page will refresh shortly to show your ranking on the leaderboard...', 'success');
        
        // Refresh page after showing success message for 3 seconds
        setTimeout(() => {
            window.location.reload();
        }, 3000);
    }
}

// Close username modal
function closeUsernameModal() {
    document.getElementById('username-modal').style.display = 'none';
    document.getElementById('username-input').value = '';
    // Refresh the page when user skips leaderboard submission
    window.location.reload();
}

// Load leaderboard from backend
async function loadLeaderboardFromBackend() {
    const leaderboardData = await getLeaderboard();
    todaysLeaderboard = leaderboardData.map(entry => ({
        username: entry.user_name,
        time: formatTime(entry.completion_time),
        timeSeconds: entry.completion_time
    }));
    showLeaderboard();
}

// Show leaderboard
function showLeaderboard() {
    const content = document.getElementById('leaderboard-content');
    
    if (todaysLeaderboard.length === 0) {
        content.innerHTML = '<p>No winners yet today. Be the first to solve the challenge!</p>';
    } else {
        content.innerHTML = '';
        todaysLeaderboard.forEach((entry, index) => {
            const item = document.createElement('div');
            item.className = 'leaderboard-item';
            item.innerHTML = `
                <div style="display: flex; align-items: center;">
                    <span class="leaderboard-rank">${index + 1}</span>
                    <div class="leaderboard-info">
                        <div class="leaderboard-username">${entry.username}</div>
                    </div>
                </div>
                <div class="leaderboard-time">${entry.time}</div>
            `;
            content.appendChild(item);
        });
    }
}

// Helper function to format time from seconds to MM:SS
function formatTime(seconds) {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = Math.floor(seconds % 60);
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
}

// Toggle solutions panel
function toggleSolutions() {
    const section = document.getElementById('solutions-section');
    const toggleBtn = document.getElementById('toggle-btn');
    
    if (section.classList.contains('minimized')) {
        section.classList.remove('minimized');
        toggleBtn.textContent = '▲';
    } else {
        section.classList.add('minimized');
        toggleBtn.textContent = '▼';
    }
}

// Close modals when clicking outside
window.onclick = function(event) {
    const playerModal = document.getElementById('player-search-modal');
    const usernameModal = document.getElementById('username-modal');
    
    if (event.target === playerModal) {
        closePlayerSearch();
    }
    if (event.target === usernameModal) {
        closeUsernameModal();
    }
}