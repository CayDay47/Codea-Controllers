
--# Main
-- Controllers - New

-- Main

-- Moving a sprite with a VirtualStick
displayMode(FULLSCREEN)

function setup()
    
    pos = vec2(WIDTH/2, HEIGHT/2)
    steer = vec2(0,0)
    speed = 400 -- pixels per second
    
    controller1 = VirtualStick {
    moved = function(v) steer = v end,
    released = function(v) steer = vec2(0,0) end,
    x0=0.5,x1=1,y0=0,y1=0.25,name="moving stick1",nameSide="bottom"}
    
    controller2 = VirtualStick {
    moved = function(v) steer = v end,
    released = function(v) steer = vec2(0,0) end,
    x0=0.5,x1=1,y0=0.25,y1=0.49,name="moving stick 2",nameSide="right"}
    
    controller3 = VirtualStick {
    moved = function(v) steer = v end,
    released = function(v) steer = vec2(0,0) end,
    x0=0.5,x1=1,y0=0.5,y1=0.75,name="moving stick 3",nameSide="right"}
    
    controller4 = VirtualSlider {
    moved = function(v) steer = vec2(0,v) end,
    released = function(v) steer = vec2(0,0) end,
    orientation = vec2(0,1),
    x0=0.5,x1=1,y0=0.75,y1=1,name="slider",nameSide="top"}
    
    allControllers = All({controller1,controller2,controller3,controller4})
    
    fps = FPS()
end

function draw()
    background(0, 0, 0, 255)
    
    pos = pos + steer*speed*DeltaTime
    
    sprite("Planet Cute:Character Boy", pos.x, pos.y)
    allControllers:draw()
    fps:draw()
end
function touched(touch)
    allControllers:touched(touch)
end


--# Controller
-- Controller

-- Base class for controllers

-- Controllers translate touch events into callbacks to functions
-- that do something in the app. (Model/View/Controller style).

-- Controllers can draw a representation of their current state on
-- the screen, but you can choose not to.

-- A controller can be installed as the global handler for touch
-- events by calling its activate() method

Controller = class()

function Controller:activate(input)
    self.x0 = input.x0 or 0
    self.x1 = input.x1 or 1
    self.y0 = input.y0 or 0
    self.y1 = input.y1 or 1
    self.cx = (self.x0+self.x1)/2 *WIDTH
    self.cy = (self.y0+self.y1)/2 *HEIGHT
    self.wx = (self.x1- self.x0)/2 *WIDTH
    self.wy = (self.y1- self.y0)/2 *HEIGHT
    self.name = input.name
    self.nameSide = input.nameSide
    if self.nameSide then
        self:textPanel()
    end
end

function Controller:textPanel()
    local w,h = 20,20
    local side = self.nameSide
    if side=="top" or side=="bottom" then w = self.wx*2
        elseif side=="left" or side=="right" then w = self.wy*2
        else print("the text for nameSide is not recognized")
    end
    
    local img = image(w,h)
    setContext(img)
    pushStyle() pushMatrix()
    strokeWidth(1)
    rectMode(RADIUS)
    background(127, 127, 127, 57)
    fill(0, 0, 0, 255)
    font("Copperplate-Light")
    fontSize(20)
    text(self.name,w/2,h/2)
    popStyle() popMatrix()
    setContext()
    
    local imgActive = image(w,h)
    setContext(imgActive)
    pushStyle() pushMatrix()
    strokeWidth(1)
    rectMode(RADIUS)
    background(255, 255, 255, 184)
    fill(0, 0, 0, 255)
    font("Copperplate-Light")
    fontSize(25)
    text(self.name,w/2,h/2)
    popStyle() popMatrix()
    setContext()
    
    local side = self.nameSide
    local x,y,r
    if     side=="top"     then
        x,y,r = self.cx , self.y1*HEIGHT - img.height/2 , 0
        elseif side=="bottom"  then
        x,y,r = self.cx , self.y0*HEIGHT + img.height/2 , 0
        elseif side=="left"    then
        x,y,r = self.x0*WIDTH + img.height/2 , self.cy , -90
        elseif side=="right"   then
        x,y,r = self.x1*WIDTH - img.height/2 , self.cy , 90
    end
    
    self.tx, self.ty, self.tr = x,y,r
    self.imgPassive = img
    self.imgActive = imgActive
    
end

function Controller:demo(timeout) -- Demo touch space will disappear after 10 seconds
    if ElapsedTime<timeout then
        pushStyle() pushMatrix()
        strokeWidth(1)
        rectMode(RADIUS)
        fill(255, 255, 255, 46)
        rect(self.cx,self.cy,self.wx,self.wy)
        fill(255, 255, 255, 255)
        fontSize(20)
        text("touch here to",self.cx,self.cy+20)
        text(self.name,self.cx,self.cy - 20)
        popStyle() popMatrix()
    end
end

function Controller:check(touch)
    local goodZone = false
    if  math.abs((touch.x-self.cx))<self.wx
    and math.abs((touch.y-self.cy))<self.wy
    then
        goodZone = true
    end
    return goodZone
end

function Controller:drawName()
    local img
    if self.touchId
    then img = self.imgActive
        else img = self.imgPassive
    end
    local x,y,r = self.tx, self.ty, self.tr
    
    pushMatrix()
    translate(x,y)
    rotate(r)
    spriteMode(CENTER)
    sprite(img,0,0)
    popMatrix()
end

--# Functions
-- Functions

-- Utility functions

function touchPos(t)
    return vec2(t.x, t.y)
end

function clamp(x, min, max)
    return math.max(min, math.min(max, x))
end

function clampAbs(x, maxAbs)
    return clamp(x, -maxAbs, maxAbs)
end

function clampLen(vec, maxLen)
    if vec == vec2(0,0) then
        return vec
        else
        return vec:normalize() * math.min(vec:len(), maxLen)
    end
end

-- projects v onto the direction represented by the given unit vector
function project(v, unit)
    return v:dot(unit)
end

function sign(x)
    if x == 0 then
        return 0
        elseif x < 0 then
        return -1
        elseif x > 0 then
        return 1
        else
        return x -- x is NaN
    end
end

function doNothing()
end


--# Controller_VirtualStick
-- VirtualStick

-- A virtual analogue joystick with a dead-zone at the center,
-- which activates wherever the user touches their finger
--
-- Arguments:
--     radius - radius of the stick (default = 100)
--     deadZoneRadius - radius of the stick's dead zone (default = 25)
--     moved(v) - Called when the stick is moved
--         v : vec2 - in the range vec2(-1,-1) and vec2(1,1)
--     pressed() - Called when the user starts using the stick (optional)
--     released() - Called when the user releases the stick (optional)

VirtualStick = class(Controller)

function VirtualStick:init(args)
    self.radius = args.radius or 100
    self.deadZoneRadius = args.deadZoneRadius or 25
    self.releasedCallback = args.released or doNothing
    self.steerCallback = args.moved or doNothing
    self.pressedCallback = args.pressed or doNothing
    self.activated = args.activate or true
    -- pre-draw sprites
    self.base = self:createBase()
    self.stick = self:createStick()
    if self.activated then self:activate(args) end
end

function VirtualStick:createBase()
    local base = image(self.radius*2+6,self.radius*2+6)
    pushStyle() pushMatrix()
    ellipseMode(RADIUS)
    strokeWidth(1)
    stroke(255, 255, 255, 255)
    noFill()
    setContext(base)
    background(0, 0, 0, 0)
    ellipse(base.width/2, base.height/2, self.radius, self.radius)
    ellipse(base.width/2, base.height/2, self.deadZoneRadius, self.deadZoneRadius)
    setContext()
    popMatrix() popStyle()
    return base
end

function VirtualStick:createStick()
    local base = image(56,56)
    pushStyle() pushMatrix()
    ellipseMode(RADIUS)
    strokeWidth(1)
    stroke(255, 255, 255, 255)
    noFill()
    setContext(base)
    background(0, 0, 0, 0)
    ellipse(base.width/2, base.height/2, 25, 25)
    setContext()
    popMatrix() popStyle()
    return base
end

function VirtualStick:touched(t)
    local pos = touchPos(t)
    local goodZone = self:check(t)
    
    if t.state == BEGAN and self.touchId == nil and goodZone then
        self.touchId = t.id
        self.touchStart = pos
        self.stickOffset = vec2(0, 0)
        self.pressedCallback()
        elseif t.id == self.touchId then
        if t.state == MOVING then
            self.stickOffset = clampLen(pos - self.touchStart, self.radius)
            self.steerCallback(self:vector())
            elseif t.state == ENDED or t.state == CANCELLED then
            self:reset()
            self.releasedCallback()
        end
    end
end

function VirtualStick:vector()
    local stickRange = self.radius - self.deadZoneRadius
    local stickAmount = math.max(self.stickOffset:len() - self.deadZoneRadius, 0)
    local stickDirection = self.stickOffset:normalize()
    
    return stickDirection * (stickAmount/stickRange)
end

function VirtualStick:reset()
    self.touchId = nil
    self.touchStart = nil
    self.stickOffset = nil
end

function VirtualStick:draw()
    if self.nameSide then self:drawName() end
    if self.name then self:demo(5) end
    if self.touchId then
        sprite(self.base,self.touchStart.x, self.touchStart.y)
        sprite(self.stick,
        self.touchStart.x+self.stickOffset.x,
        self.touchStart.y+self.stickOffset.y)
    end
end




--# Controller_VirtualSlider
-- VirtualSlider

-- A virtual analogue slider with a dead-zone at the center,
-- which activates wherever the user touches their finger
--
-- Arguments:
--     orientation - A unit vector that defines the orientation of the slider.
--                   For example orientation=vec2(1,0) creates a horizontal slider,
--                   orientation=vec2(0,1) creates a vertical slider. The slider
--                   can be given an arbitrary orientation; it does not have to be
--                   aligned with the x or y axis. For example, setting
--                   orientation=vec2(1,1):normalize() creates a diagonal slider.
--     radius - Distance from the center to the end of the slider (default = 100)
--     deadZoneRadius - Distance from the center to the end of the dead zone (default = 25)
--     moved(x) - Called when the slider is moved
--         x : float - in the range -1 to 1
--     pressed() - Called when the user starts using the slider (optional)
--     released() - Called when the user releases the slider (optional)

VirtualSlider = class(Controller)

function VirtualSlider:init(args)
    self.orientation = args.orientation or vec2(1,0)
    self.radius = args.radius or 100
    self.deadZoneRadius = args.deadZoneRadius or 25
    self.releasedCallback = args.released or doNothing
    self.movedCallback = args.moved or doNothing
    self.pressedCallback = args.pressed or doNothing
    self.activated = args.activate or true
    self.base = self:createBase()
    self.stick = self:createStick()
    if self.activated then self:activate(args) end
end

function VirtualSlider:touched(t)
    local pos = touchPos(t)
    local goodZone = self:check(t)
    
    if t.state == BEGAN and self.touchId == nil and goodZone then
        self.touchId = t.id
        self.touchStart = pos
        self.sliderOffset = 0
        self.pressedCallback()
        elseif t.id == self.touchId then
        if t.state == MOVING then
            local v = pos - self.touchStart
            self.sliderOffset = clampAbs(project(v, self.orientation), self.radius)
            self.movedCallback(self:value())
            elseif t.state == ENDED or t.state == CANCELLED then
            self:reset()
            self.releasedCallback()
        end
    end
end

function VirtualSlider:reset()
    self.touchId = nil
    self.touchStart = nil
    self.sliderOffset = nil
end

function VirtualSlider:value()
    local range = self.radius - self.deadZoneRadius
    local amount = sign(self.sliderOffset) * math.max(math.abs(self.sliderOffset) - self.deadZoneRadius, 0)
    
    return amount/range
end

function VirtualSlider:createBase()
    local img = image(self.radius*2+6,self.radius*2+6)
    setContext(img)
    pushStyle()
    ellipseMode(RADIUS)
    strokeWidth(3)
    stroke(255, 255, 255, 255)
    lineCapMode(SQUARE)
    noFill()
    background(0, 0, 0, 0)
    local function polarLine(orientation, fromRadius, toRadius)
        local from = orientation * fromRadius + vec2(1,1)*(self.radius + 3)
        local to = orientation * toRadius + vec2(1,1)*(self.radius + 3)
        line(from.x, from.y, to.x, to.y)
    end
    polarLine(self.orientation, self.deadZoneRadius, self.radius)
    polarLine(self.orientation, -self.deadZoneRadius, -self.radius)
    popStyle()
    setContext()
    return img
end

function VirtualSlider:createStick()
    local img = image(56,56)
    setContext(img)
    pushStyle() pushMatrix()
    ellipseMode(RADIUS)
    strokeWidth(3)
    stroke(255, 255, 255, 255)
    lineCapMode(SQUARE)
    noFill()
    background(0, 0, 0, 0)
    
    
    strokeWidth(1)
    ellipse(28, 28, 25, 25)
    popMatrix() popStyle()
    setContext()
    return img
end

function VirtualSlider:draw()
    if self.nameSide then self:drawName() end
    if self.name then self:demo(5) end
    if self.touchId then
        pushMatrix() pushStyle()
        spriteMode(CENTER)
        sprite(self.base,self.touchStart.x, self.touchStart.y)
        local sliderPos = self.orientation * self.sliderOffset + self.touchStart
        strokeWidth(1)
        sprite(self.stick, sliderPos.x, sliderPos.y)
        popStyle() popMatrix()
    end
end


--# Controller_All
-- ControllerAll

-- Forwards each touch event to all the controllers in the table
-- passed to the constructor
 
All = class(Controller)
 
function All:init(controllers)
   self.controllers = controllers
end
 
function All:touched(t)
   for _, c in pairs(self.controllers) do
       c:touched(t)
   end
end
 
function All:draw()
   for _, c in pairs(self.controllers) do
       c:draw()
   end
end
 

--# FPS
-- FPS

FPS = class()
 
function FPS:init()
   self.val = 60
end
 
function FPS:draw()
   -- update FPS value with some smoothing
   self.val = self.val*0.99+ 1/(DeltaTime)*0.01
   -- write the FPS on the screen
   fill(208, 208, 208, 255)
   fontSize(30)
   font("AmericanTypewriter-Bold")
   rectMode(CENTER)
   text(math.floor(self.val).." fps",50,HEIGHT-25)
end
