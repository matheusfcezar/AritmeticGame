-----------------------------------------------------------------------------------------
--
-- main_original.lua
--
-----------------------------------------------------------------------------------------

local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 )

-- Seed the random number generator
math.randomseed( os.time() )

-- variaveis locais
local lives = 4
local score = 0
local died = false
 
local villainsTable = {}
 
local bh
local gameLoopTimer
local livesText
local scoreText

local backGroup = display.newGroup()  -- Display group for the background image
local mainGroup = display.newGroup()  -- Display group for the ship, asteroids, lasers, etc.
local uiGroup = display.newGroup()    -- Display group for UI objects like the score


-- Subindo o background
local background = display.newImageRect(backGroup,"Imagens/Background (1).png", 1450, 800 )
background.x = display.contentCenterX
background.y = display.contentCenterY


--Subindo o personagem
hero = display.newImageRect( mainGroup,"Imagens/Fly (1).png", 132.9, 90.6 )
hero.x = display.contentHeight-800
hero.y = display.contentCenterY
physics.addBody( hero, { radius=30, isSensor=true } )
hero.myName = "hero"

-- Display lives and score
livesText = display.newText( uiGroup, "Lives: " .. lives, 400, 30, native.newFont( "Helvetica-Bold", 16 ), 30 )
scoreText = display.newText( uiGroup, " " .. score, 700, 30, native.newFont( "Helvetica-Bold", 16 ), 30 )
display.setStatusBar( display.HiddenStatusBar )

-- Hide the status bar
display.setStatusBar( display.HiddenStatusBar )

--Atualizar score
local function updateText()
    livesText.text = "Lives: " .. lives
    scoreText.text = "" .. score
end

--função gerar inimigos 
local function createVillain()
	local newVillain = display.newImageRect("Imagens/Villain (1).png", 132.9, 90.6)
    table.insert( villainsTable, newVillain )
    physics.addBody( newVillain, "dynamic", { radius=40, bounce=0.8 } )
    
    newVillain.myName = "villain"

    local whereFrom = math.random( 1 )
 
    -- From the right
    
    newVillain.x = display.contentHeight+350
    newVillain.y = math.random( display.contentHeight )
    newVillain:setLinearVelocity( -200, 0 )
end

-- função atirar
local function fireBullet()
    local newBullet = display.newImageRect( mainGroup, "Imagens/Bullet (1).png", 25, 25 )
    physics.addBody( newBullet, "dynamic", { isSensor=true } )
    newBullet.isBullet = true
    newBullet.myName = "bullet"
    newBullet.x = hero.x - 25
    newBullet.y = hero.y + 25
    newBullet:toBack()
    transition.to( newBullet, { x = 10000, y = 300, time=10000, 
    	onComplete = function() display.remove( newBullet ) end
    	} )
  
end

bullet = display.newImageRect( mainGroup,"Imagens/button.png", 100, 100 )
bullet.x = display.contentHeight + 315
bullet.y = display.contentHeight - 100


bullet:addEventListener( "tap", fireBullet )

-- função movimentação do personagem
local function dragHero( event )
	local hero = event.target
	local phase = event.phase

 	if ( "began" == phase ) then
        -- Set touch focus on the hero
        display.currentStage:setFocus( hero)
         -- Store initial offset position
        hero.touchOffsetX = event.x - hero.x
        hero.touchOffsetY = event.y - hero.y

    elseif ( "moved" == phase ) then
     	-- Move the hero to the new touch position
       	hero.x = event.x - hero.touchOffsetX
       	hero.y = event.y - hero.touchOffsetY

    elseif ( "ended" == phase or "cancelled" == phase ) then
        -- Release touch focus on the hero
        display.currentStage:setFocus( nil )   	
	end

	return true  -- Prevents touch propagation to underlying objects
end
 

hero:addEventListener( "touch", dragHero )

local function gameLoop()
	 -- Create new villain
    createVillain()
     -- Remove villains which have drifted off screen
    for i = #villainsTable, 1, -1 do
    	local thisVillain = villainsTable[i]
 
        if ( thisVillain.x < -100 or
             thisVillain.x > display.contentWidth + 100 or
             thisVillain.y < -100 or
             thisVillain.y > display.contentHeight + 100 )
        then
            display.remove( thisVillain )
            table.remove( villainsTable, i )
        end
    end
end

gameLoopTimer = timer.performWithDelay( 2000, gameLoop, 2000 )

local function restoreHero()
 
    hero.isBodyActive = false
    hero.x = display.contentHeight-800
    hero.y = display.contentCenterY
 
    -- Fade in the hero
    transition.to( hero, { alpha=1, time=4000,
        onComplete = function()
            hero.isBodyActive = true
            died = false
        end
    } )
end

local function onCollision( event )
 
    if ( event.phase == "began" ) then
 
        local obj1 = event.object1
        local obj2 = event.object2

        if ( ( obj1.myName == "bullet" and obj2.myName == "villain" ) or
             ( obj1.myName == "villain" and obj2.myName == "bullet" ) )
        then
        -- Remove both the bullet and villain
            display.remove( obj1 )
            display.remove( obj2 )

            for i = #villainsTable, 1, -1 do
                if ( villainsTable[i] == obj1 or villainsTable[i] == obj2 ) then
                    table.remove( villainsTable, i )
                    break
                end
            end

            -- Increase score
            score = score + 100
            scoreText.text = " " .. score

            elseif ( ( obj1.myName == "hero" and obj2.myName == "villain" ) or
                 ( obj1.myName == "villain" and obj2.myName == "hero" ) )
        	then
        		if ( died == false ) then
        			 died = true
                    restoreHero()   
        			 -- Update lives
                lives = lives - 1
                livesText.text = "Lives: " .. lives
                if ( lives == 0 ) then
                    display.remove( hero )
                else
                    hero.alpha = 0
                    timer.performWithDelay( 1000, restoreBh )
                end
            end
        end
    end
end

Runtime:addEventListener( "collision", onCollision )