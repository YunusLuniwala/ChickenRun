

emo.Runtime.import("imo.nut");

const STATUS_READY = "ready";
const STATUS_STARTED = "started";
const STATUS_FINISHED = "finished";

const Z_BGS = 0;
const Z_ELEMS = 10000;
const Z_GUIS = 20000;

local physics = emo.Physics;


class MainStage extends imo.AbstractStage {
    status = STATUS_READY;
    countDownStarted = false;
    
    dialog = null;
    dialogBackgroundLayer = null;
    dialogButtonRetry = null;
    dialogButtonExit = null;
    
    captionBackgroundLayer = null;
    captionComplete = null;
    captionFailed = null;
    
    captionGetSet = null;
    captionCount1 = null;
    captionCount2 = null;
    captionCount3 = null;
    background = null;
    
    bgSky = null;
    bgDistantGround = null;
    bgMountain = null;
    bgRoad = null;

    chaseEntity = null;
    chaseEntityPhysicsInfo = null;
    ground = null;
    edgeLeft = null;
    edgeRight = null;
    cameraAbsoluteOffsetX = 0;
    cameraAbsoluteOffsetY = 0;
    
    acceptableRangeStartX = 900;
    acceptableRangeEndX = 999;
    
    force = 100;
    brakingForce = -40;
    brakingFrameCount = 10;
    currentBrakingFrameCount = 0;
    
    constructor() {
        base.constructor();
        width = 3000;
        height = 550;
    }
    
    function loadWorld() {
        return emo.physics.World(emo.Vec2(0, 10), true);;
    }
    
    function rewind() {
        status = STATUS_READY;
        countDownStarted = false;
        force = 100;
        
        
        captionBackgroundLayer.hide();
        captionComplete.hide();
        captionFailed.hide();
        
        captionGetSet.move((imo.S.WINDOW_WIDTH - captionGetSet.getWidth())/2, 0);
        captionGetSet.show();
        captionGetSet.addModifier(emo.MoveModifier(
            [captionGetSet.getX(), captionGetSet.getY()], 
            [captionGetSet.getX(), (imo.S.WINDOW_HEIGHT - captionGetSet.getHeight())/2], 
            1000, emo.easing.Linear));
            
        dialog.hide();
        
        loadChaseEntity();
        appendFloat(chaseEntity);
        setChaseTarget(chaseEntity);
    }
    
    function loadFloats() {
        floats = [];
        
        loadBackground();
        
        loadChaseEntity();
        floats.append(chaseEntity);
        setChaseTarget(chaseEntity);
        
        loadCaptions();
        
        loadDialog();
        floats.append(dialog);
        
        loadBuildings(floats);
        loadHouses(floats);
        loadEdge();
        
        return floats;
    }
    
    function loadChaseEntity() {
        if (chaseEntityPhysicsInfo) {
            world.removePhysicsObject(chaseEntityPhysicsInfo);
        }
        if (chaseEntity) {
            chaseEntity.remove();
            removeFloat(chaseEntity);
        }
        
        local _this = this;
            
        chaseEntity = emo.SpriteSheet("new-car-sprite.png", 150, 71);
        chaseEntity.setZ(Z_ELEMS + 100);
        chaseEntity.update = function(elapsedTime) {
            if (_this.chaseEntityPhysicsInfo.getBody().getLinearVelocity().x <= 0) {
                this.animate(3, 4, 100, 1);
            }
        }
        local fixtureDef = emo.physics.FixtureDef();
        fixtureDef.density = 0.8;
        fixtureDef.friction = 0.7;
        fixtureDef.restitution = 0.0;
        chaseEntityPhysicsInfo = physics.createDynamicSprite(world, chaseEntity, fixtureDef);
        chaseEntity.load();
    }
    
    function loadBackground() {
        bgDistantGround = emo.MapSprite("distant-ground.png", 100, 100);
        bgDistantGround.move(0, 350);
        bgDistantGround.setZ(Z_BGS + 1);
        bgDistantGround.setMap([[
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,]]);
        bgDistantGround.load();
        floats.append(bgDistantGround);
        
        ground = emo.MapSprite("road-2.png", 100, 100);
        ground.setMap([[
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,]]);
        ground.setSize(width, 100);
        ground.color(1, 1, 1, 1);
        ground.move(0, height - ground.getHeight());
        ground.setZ(Z_ELEMS + 0);
        ground.load();
        physics.createStaticSprite(world, ground)
        floats.append(ground);
        
        bgSky = emo.Sprite("sky.png");
        bgSky.move(0, 0);
        bgSky.setZ(Z_BGS + 0);
        bgSky.setAsBackground(true);
        bgSky.distance = 100.0;
        bgSky.load();
        floats.append(bgSky);

        bgMountain = emo.Sprite("mountain.png");
        bgMountain.move(0, bgDistantGround.getY() - bgMountain.getHeight());
        bgMountain.setZ(Z_BGS + 1);
        bgMountain.setAsBackground(true);
        bgMountain.distance = 90.0;
        bgMountain.load();
        floats.append(bgMountain);
    }
    
    function loadCaptions() {
        
        captionBackgroundLayer = emo.Rectangle();
        captionBackgroundLayer.setSize(imo.S.WINDOW_WIDTH, imo.S.WINDOW_HEIGHT);
        captionBackgroundLayer.color(1, 1, 1, 0.7);
        captionBackgroundLayer.setZ(Z_GUIS + 10);
        captionBackgroundLayer.hide();
        captionBackgroundLayer.load();
        
        captionComplete = emo.Sprite("complete.png");
        captionComplete.setZ(Z_GUIS + 11);
        captionComplete.hide();
        captionComplete.load();
        
        captionFailed = emo.Sprite("failed.png");
        captionFailed.setZ(Z_GUIS + 11);
        captionFailed.hide();
        captionFailed.load();
        
        captionGetSet = emo.Sprite("get-set.png");
        /*
        captionGetSet.move((imo.S.WINDOW_WIDTH - captionGetSet.getWidth())/2, 0);
        captionGetSet.addModifier(emo.MoveModifier(
            [captionGetSet.getX(), captionGetSet.getY()], 
            [captionGetSet.getX(), (imo.S.WINDOW_HEIGHT - captionGetSet.getHeight())/2], 
            1000, emo.easing.Linear));
            //*/
        captionGetSet.setZ(Z_GUIS + 1);
        captionGetSet.load();
        
        captionCount1 = emo.Sprite("count-1.png");
        captionCount1.move(
            (imo.S.WINDOW_WIDTH - captionCount1.getWidth())/2, 
            (imo.S.WINDOW_HEIGHT - captionCount1.getHeight())/2 + 100);
        captionCount1.setZ(Z_GUIS + 1);
        captionCount1.hide();
        captionCount1.load();
        
        captionCount2 = emo.Sprite("count-2.png");
        captionCount2.move(
            (imo.S.WINDOW_WIDTH - captionCount2.getWidth())/2, 
            (imo.S.WINDOW_HEIGHT - captionCount2.getHeight())/2 + 100);
        captionCount2.setZ(Z_GUIS + 1);
        captionCount2.hide();
        captionCount2.load();
        
        captionCount3 = emo.Sprite("count-3.png");
        captionCount3.move(
            (imo.S.WINDOW_WIDTH - captionCount3.getWidth())/2, 
            (imo.S.WINDOW_HEIGHT - captionCount3.getHeight())/2 + 100);
        captionCount3.setZ(Z_GUIS + 1);
        captionCount3.hide();
        captionCount3.load();
    }
    
    function loadDialog() {
        local _this = this;
        dialog = imo.Dialog(this, 0, 0, 0, 1);
        dialogButtonRetry = imo.DialogButton("retry.png", 600, 150);
        dialogButtonRetry.onMotionEvent = function(mevent) {
            print("dialogButtonRetry.onMotionEvent()");
            switch (mevent.getAction()) {
                case MOTION_EVENT_ACTION_DOWN:
                    setFrame(1);
                    break;
                case MOTION_EVENT_ACTION_UP:
                    setFrame(0);
                    _this.rewind();
                    break;
            }
        };
        dialogButtonExit = imo.DialogButton("exit.png", 600, 150);
        dialogButtonExit.onMotionEvent = function(mevent) {
            print("dialogButtonExit.onMotionEvent()");
            switch (mevent.getAction()) {
                case MOTION_EVENT_ACTION_DOWN:
                    setFrame(1);
                    break;
                case MOTION_EVENT_ACTION_UP:
                    setFrame(0);
                    break;
            }
        };
        dialog.appendButton(dialogButtonRetry);
        dialog.appendButton(dialogButtonExit);
        dialog.setZ(Z_GUIS + 100);
        dialog.setLayout(imo.S.LAYOUT_VERTICAL);
        dialog.load();
        dialog.hide();
    }
    
    function loadEdge() {
        edgeLeft = emo.Rectangle();
        edgeLeft.setSize(1, imo.S.WINDOW_HEIGHT);
        edgeLeft.move((-1)*edgeLeft.getWidth(), height - edgeLeft.getHeight());
        edgeLeft.setZ(Z_ELEMS + 0);
        edgeLeft.color(1, 0, 1, 1);
        edgeLeft.hide();
        edgeLeft.load();
        physics.createStaticSprite(world, edgeLeft);

        edgeRight = emo.Rectangle();
        edgeRight.setSize(1, imo.S.WINDOW_HEIGHT);
        edgeRight.move(width, height - edgeRight.getHeight());
        edgeRight.setZ(Z_ELEMS + 0);
        edgeRight.color(1, 0, 1, 1);
        edgeRight.hide();
        edgeRight.load();
        physics.createStaticSprite(world, edgeRight);
    }
    
    function loadBuildings(floats) {
        appendBuilding(floats, "building-1.png", -10);
        appendBuilding(floats, "building-2.png", 30);
        appendBuilding(floats, "building-3.png", 100);
        appendBuilding(floats, "building-1.png", 180);
        appendBuilding(floats, "building-4.png", 220);
        appendBuilding(floats, "building-5.png", 270);
    }
    
    function loadHouses(floats) {
        appendHouse(floats, "house-1.png", 50);
        appendHouse(floats, "house-2.png", 400);
        appendHouse(floats, "house-3.png", 1000);
        appendHouse(floats, "house-4.png", 1500);
        appendHouse(floats, "house-5.png", 1700);
    }
    
    function appendBuilding(floats, name, x) {
        appendBackground(floats, "building", name, x);
    }
    
    function appendHouse(floats, name, x) {
        appendBackground(floats, "house", name, x);
    }
    
    function appendBackground(floats, type, name, x) {
        local zBgs = Z_BGS + (type == "building" ? 1000 : type == "house" ? 2000 : 0);
        local distance = type == "building" ? 80 : type == "house" ? 0 : 0;
        local bgElem = emo.Sprite(name);
        bgElem.move(x, ground.getY() - bgElem.getHeight());
        bgElem.setZ(zBgs);
        bgElem.setAsBackground(true);
        bgElem.distance = distance;
        bgElem.load();
        floats.append(bgElem);
    }
    
    function onDrawFrame(dt) {
        base.onDrawFrame(dt);
        if (status == STATUS_FINISHED) {
            return;
        }

        applyForceToCar(dt);
        checkFinishedCondition();
    }
    
    function drawCompleteView() {
        captionBackgroundLayer.show();
        captionBackgroundLayer.color(1, 1, 1, 0.7);
        captionBackgroundLayer.move(cameraX, cameraY);
        
        captionComplete.move(
            cameraX + (imo.S.WINDOW_WIDTH - captionComplete.getWidth())/2, 
            cameraY + (imo.S.WINDOW_HEIGHT - captionComplete.getHeight())/2);
        captionComplete.show();
    }
    
    function drawNotCompleteView() {
        captionBackgroundLayer.show();
        captionBackgroundLayer.color(0, 0, 0, 0.7);
        captionBackgroundLayer.move(cameraX, cameraY);
        
        captionFailed.move(
            cameraX + (imo.S.WINDOW_WIDTH - captionFailed.getWidth())/2, 
            cameraY + (imo.S.WINDOW_HEIGHT - captionFailed.getHeight())/2);
        captionFailed.show();
    }
    
    function checkFinishedCondition() {
        if (status != STATUS_STARTED) return;
        if (chaseEntityPhysicsInfo.getBody().getLinearVelocity().x <= 0) {
            status = STATUS_FINISHED;
            if (isComplete()) {
                drawCompleteView();
            } else {
                drawNotCompleteView();
            }
        } else {
            status = STATUS_STARTED;
        }
    }
    
    function isComplete() {
        if (status != STATUS_FINISHED) return false;
        
        local vx = chaseEntityPhysicsInfo.getBody().getLinearVelocity().x;
        local carHeadPosition = chaseEntity.getX() + chaseEntity.getWidth();
        if (carHeadPosition >= acceptableRangeStartX && carHeadPosition <= acceptableRangeEndX) {
            return true;
        }
        return false;
    }
    
    function applyForceToCar(dt) {
        if (status == STATUS_STARTED) {
            local chaseEntityBody = chaseEntityPhysicsInfo.getBody();
            chaseEntityBody.applyForce(emo.Vec2(force, 0), chaseEntityBody.getWorldCenter());
            if (force < 0) {
                print("currentBrakingFrameCount: " + currentBrakingFrameCount);
                currentBrakingFrameCount++;
                if (currentBrakingFrameCount == brakingFrameCount) force = 0;
            }
        }
    }
    
    function onMotionEvent(mevent) {
        base.onMotionEvent(mevent);
        switch (status) {
            case STATUS_READY:
                if (mevent.getAction() == MOTION_EVENT_ACTION_UP && !countDownStarted) {
                    countDownStarted = true;
                    countDown();
                }
            break;
            case STATUS_STARTED:
                if (mevent.getAction() == MOTION_EVENT_ACTION_UP) {
                    force = brakingForce;
                    chaseEntity.stop();
                } else if (mevent.getAction() == MOTION_EVENT_ACTION_DOWN) {
                    chaseEntity.move(chaseEntity.getX(), chaseEntity.getY() + 30);
                }
            break;
            case STATUS_FINISHED:
                if (mevent.getAction() == MOTION_EVENT_ACTION_UP) {
                    dialog.show();
                }
            break;
            default:
            break;
        }
    }
    
    function countDown() {
        local _this = this;
        local captionGetSetHideModifier = emo.MoveModifier(
            [captionGetSet.getX(), captionGetSet.getY()], 
            [captionGetSet.getX(), (-1)*captionGetSet.getHeight()], 
            500, emo.easing.Linear);
        captionGetSetHideModifier.setEventCallback(function(targetObj, modifier, event) {
            if (event != EVENT_MODIFIER_FINISH) return;
             _this.captionGetSet.hide();
            _this.captionCount3.clearModifier();
            _this.captionCount3.show();
            
            local captionCount3AppearModifier = emo.ScaleModifier(1, 2, 700, emo.easing.Linear);
            captionCount3AppearModifier.setEventCallback(function(targetObj, modifier, event) {
                if (event != EVENT_MODIFIER_FINISH) return;
                _this.captionCount3.hide();
                _this.captionCount2.clearModifier();
                _this.captionCount2.show();
                
                local captionCount2AppearModifier = emo.ScaleModifier(1, 2, 700, emo.easing.Linear);
                captionCount2AppearModifier.setEventCallback(function(targetObj, modifier, event) {
                    if (event != EVENT_MODIFIER_FINISH) return;
                    _this.captionCount2.hide();
                    _this.captionCount1.clearModifier();
                    _this.captionCount1.show();
                    
                    local captionCount1AppearModifier = emo.ScaleModifier(1, 2, 700, emo.easing.Linear);
                    captionCount1AppearModifier.setEventCallback(function(targetObj, modifier, event) {
                        if (event != EVENT_MODIFIER_FINISH) return;
                        print("STATUS_STARTED");
                        _this.captionCount1.hide();
                        _this.status = STATUS_STARTED;
                        _this.chaseEntity.animate(0, 3, 100, -1);
                        _this.chaseEntityPhysicsInfo.getBody().setLinearVelocity(emo.Vec2(1, 0));
                    });
                    _this.captionCount1.addModifier(captionCount1AppearModifier);
                });
                _this.captionCount2.addModifier(captionCount2AppearModifier);
            });
            _this.captionCount3.addModifier(captionCount3AppearModifier);
        });
        captionGetSet.addModifier(captionGetSetHideModifier);
    }
}

function emo::onLoad() {
    emo.Stage.load(MainStage());
}
