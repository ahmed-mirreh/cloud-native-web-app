from fastapi import FastAPI, HTTPException, APIRouter
from pydantic import BaseModel
from typing import Dict, Optional, List
import json
import httpx
import os
import boto3
import signal
import sys
import logging
from decimal import Decimal
from pathlib import Path

# Configure logging for CloudWatch
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

# Graceful shutdown handlers
def signal_handler(sig, frame):
    logger.info(f'Received signal {sig}. Gracefully shutting down...')
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

app = FastAPI(title="NBA Higher or Lower API", version="1.0.0")

# Configuration - Production values from Terraform, fallbacks for local dev
RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY", "your-rapidapi-key-here")
BASKETBALL_API_BASE_URL = "https://v1.basketball.api-sports.io"
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
PLAYERS_TABLE = os.getenv("PLAYERS_TABLE", "nba-challenge-dev-players")
LEADERBOARD_TABLE = os.getenv("LEADERBOARD_TABLE", "nba-challenge-dev-leaderboard")

# Validate required environment variables
required_env_vars = {
    "RAPIDAPI_KEY": RAPIDAPI_KEY,
    "AWS_REGION": AWS_REGION, 
    "PLAYERS_TABLE": PLAYERS_TABLE,
    "LEADERBOARD_TABLE": LEADERBOARD_TABLE
}

# Check if we're using fallback values (local development)
using_fallbacks = [var for var, value in required_env_vars.items() if not os.getenv(var)]
if using_fallbacks:
    logger.warning(f"Using fallback values for local development: {using_fallbacks}")
    logger.warning("Set environment variables for production deployment")
else:
    logger.info("All environment variables provided - running in production mode")

logger.info("All required environment variables validated successfully")
logger.info(f"Starting NBA Higher or Lower API in region: {AWS_REGION}")

# DynamoDB setup
# ECS task role will provide credentials automatically
dynamodb = boto3.resource(
    'dynamodb',
    region_name=AWS_REGION
)

# Pydantic models (for API responses)
class PlayerStats(BaseModel):
    points: float
    rebounds: float
    assists: float

class PlayerInfo(BaseModel):
    player_name: str
    team: str
    photo_url: str

class UserScore(BaseModel):
    user_name: str
    completion_time: float

# Create API router with /api prefix
api_router = APIRouter(prefix="/api")


@api_router.get("/health")
async def health_check():
    return {"status": "healthy"}

# Player endpoints
@api_router.get("/players")
async def get_players():
    """Get all available players from database"""
    try:
        table = dynamodb.Table(PLAYERS_TABLE)
        response = table.scan()
        players = response['Items']

        # Sort by player_name alphabetically since there's no id field
        players.sort(key=lambda x: x['player_name'])

        player_list = [PlayerInfo(player_name=p['player_name'], team=p['team'], photo_url=p['photo_url']) for p in players]
        return {"players": [player.model_dump() for player in player_list]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get players: {str(e)}")


# Stats endpoint - still uses player name like before
@api_router.get("/stats/{player_name}")
async def get_player_stats(player_name: str):
    """Get player stats from Basketball API Sports (no persistence)"""
    try:
        # Search for player and get their data from third-party API
        player_data = await search_player_by_name(player_name)
        
        # Get full stats for this player from third-party API  
        player_with_stats = await fetch_player_stats(player_data)
        
        return player_with_stats
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get player stats: {str(e)}")

# Leaderboard endpoints
@api_router.get("/leaderboard")
async def get_leaderboard():
    """Get leaderboard sorted by completion time (fastest first)"""
    try:
        table = dynamodb.Table(LEADERBOARD_TABLE)
        response = table.scan()
        leaderboard_data = response['Items']
        
        # Sort by completion time (ascending - fastest first)
        leaderboard_data.sort(key=lambda x: float(x['completion_time']))
        
        return {"leaderboard": leaderboard_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get leaderboard: {str(e)}")

@api_router.post("/leaderboard")
async def submit_score(user_score: UserScore):
    """Submit a new user score to the leaderboard (one score per user)"""
    try:
        table = dynamodb.Table(LEADERBOARD_TABLE)
        
        # Check if user already exists
        try:
            lookup_response = table.get_item(Key={'user_name': user_score.user_name})
            if 'Item' in lookup_response.keys():
                raise HTTPException(status_code=400, detail=f"User {user_score.user_name} has already submitted a score")
        except HTTPException:
            raise
        except:
            pass  # User doesn't exist, which is what we want
        
        # Insert new score
        table.put_item(
            Item={
                'user_name': user_score.user_name,
                'completion_time': Decimal(str(user_score.completion_time)),
                'created_at': httpx._utils.utcnow().isoformat() if hasattr(httpx._utils, 'utcnow') else '2024-01-01T00:00:00Z'
            }
        )
        
        return {
            "message": f"Score submitted for {user_score.user_name}",
            "user_name": user_score.user_name,
            "completion_time": user_score.completion_time
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to submit score: {str(e)}")

# Helper functions
async def search_player_by_name(player_name: str) -> dict:
    """Search for player by name and return their data"""
    try:
        # Convert underscores to spaces for API call
        formatted_name = player_name.replace("_", " ")
        
        async with httpx.AsyncClient(timeout=10.0) as client:
            search_url = f"{BASKETBALL_API_BASE_URL}/players"
            params = {"search": formatted_name}
            headers = {"x-rapidapi-key": RAPIDAPI_KEY}
            
            response = await client.get(search_url, params=params, headers=headers)
            response.raise_for_status()
            data = response.json()
            
            if not data.get("response") or len(data["response"]) == 0:
                raise HTTPException(status_code=404, detail=f"No players found for '{player_name}'")
            
            # Return the first match - only return the ID as requested
            player = data["response"][0]
            return {"id": player.get("id")}
            
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Basketball API request timed out")
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=502, detail=f"Basketball API error: {e.response.status_code}")

async def fetch_player_stats(player_data: dict) -> PlayerStats:
    """Fetch player season averages from Basketball API Sports"""
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            # Get player game statistics for 2023-2024 season
            stats_url = f"{BASKETBALL_API_BASE_URL}/games/statistics/players"
            params = {
                "player": player_data["id"],
                "season": "2023-2024"
            }
            headers = {"x-rapidapi-key": RAPIDAPI_KEY}
            
            response = await client.get(stats_url, params=params, headers=headers)
            response.raise_for_status()
            stats_data = response.json()
            
            # Calculate season averages from all games
            total_points = total_rebounds = total_assists = 0.0
            games_count = 0
            
            if stats_data.get("response"):
                for game in stats_data["response"]:
                    # Skip All-Star games (team IDs 1416 or 1417)
                    team_id = game.get("team", {}).get("id")
                    if team_id in [1416, 1417]:
                        continue
                    total_points += game.get("points", 0) or 0
                    total_rebounds += game.get("rebounds", {}).get("total", 0) or 0
                    total_assists += game.get("assists", 0) or 0
                    games_count += 1
            
            # Calculate averages
            points = round(total_points / games_count) if games_count > 0 else 0
            rebounds = round(total_rebounds / games_count) if games_count > 0 else 0
            assists = round(total_assists / games_count) if games_count > 0 else 0
            
            return PlayerStats(
                points=points,
                rebounds=rebounds,
                assists=assists
            )
            
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Basketball API request timed out")
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=502, detail=f"Basketball API error: {e.response.status_code}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch player stats: {str(e)}")

# Include the API router after all routes are defined
app.include_router(api_router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="debug")