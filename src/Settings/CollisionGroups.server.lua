
-- Grab the Service:
local PhysicsService = game:GetService('PhysicsService')

-- Register the ZonePart Collision Group:
PhysicsService:RegisterCollisionGroup('ZonePart')
PhysicsService:CollisionGroupSetCollidable('ZonePart', 'Default', false)

-- Destroy this Script:
script:Destroy()