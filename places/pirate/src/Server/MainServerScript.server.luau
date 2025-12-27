-- ServiceLoader in ServerScriptService

-- Controllers
local GameRoomInitializer = require(game.ServerScriptService.Controller.GameRoomInitializer)
local MatchController = require(game.ServerScriptService.Controller.MatchController)

-- Services
local InventoryService = require(game.ServerScriptService.Service.InventoryService)
local PlayerDataService = require(game.ServerScriptService.Service.PlayerDataService)
local CoinAreaService = require(game.ServerScriptService.Service.CoinAreaService)
local BarrelSystemService = require(game.ServerScriptService.Service.BarrelSystemService.BarrelSystemService)
local TeamService = require(game.ServerScriptService.Service.TeamService)

-- 서비스 초기화
TeamService:Initialize()
MatchController:Initialize()

print("[MainServerScript] 모든 서비스 초기화 완료")
